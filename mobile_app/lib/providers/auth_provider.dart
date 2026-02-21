import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch latest exam to get the current access code
      final exam = await _supabaseService.fetchLatestExam();
      
      if (exam == null) {
        _error = "No active exam found.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Validate the provided password (Access Command) against the exam's access code
      if (password != exam.accessCode) {
        _error = "Invalid Access Command for the current exam.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Perform silent login for the unified student account
      // Note: Admin must ensure student@haramaya.com exists with this static password
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: 'student@haramaya.com',
        password: 'student_access_2026',
      );

      if (response.user != null) {
        String deviceId = await _getDeviceId();
        bool isBound = await _supabaseService.verifyDeviceBinding('student@haramaya.com', deviceId);
        
        if (!isBound) {
          await Supabase.instance.client.auth.signOut();
          _error = "This device is not registered for the exam.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _user = response.user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = "Access Denied: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<String> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_id';
    }
    return 'unknown_device_id';
  }
}

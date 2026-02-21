import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/supabase_service.dart';
import '../models/exam_model.dart';

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
      Exam? exam;
      try {
        exam = await _supabaseService.fetchLatestExam();
      } catch (dbError) {
        _error = "Database Connection Error: ${dbError.toString()}";
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      if (exam == null) {
        _error = "Access Refused: No active exam sessions were found in the registry. Please check with your supervisor.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Validate the provided password (Access Command) against the exam's access code
      final expected = (exam.accessCode ?? "").trim().toUpperCase();
      final received = password.trim().toUpperCase();
      
      if (received != expected) {
        _error = "Invalid Access Command.\nExpected: '$expected'\nReceived: '$received'";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Fetch global shared password from settings
      final settings = await _supabaseService.fetchSettings();
      final sharedPassword = settings['global_student_password'];

      // 4. Verify the student exists in the 'profiles' table
      // In this setup, we use a single Auth account but track individual profiles.
      // Or if the admin creates individual Auth users with the same password:
      // We will try to sign in with the student's own email and the shared password.
      
      String deviceId = await _getDeviceId();

      // 4. Verify student existence and handle account provisioning
      AuthResponse? response;
      try {
        response = await Supabase.instance.client.auth.signInWithPassword(
          email: email, 
          password: sharedPassword,
        );
      } catch (authError) {
        if (authError.toString().contains('429')) {
           rethrow; // Pass rate limit error up immediately
        }
        
        // Transparent Auto-Provisioning:
        // If user doesn't exist in Auth but is in the 'profiles' table (created by Admin)
        // we sign them up automatically using the shared password.
        
        try {
          final registryCheck = await Supabase.instance.client
              .from('student_registry')
              .select()
              .eq('email', email)
              .maybeSingle();

          if (registryCheck != null) {
             // Account exists in registry but not in Auth yet
             response = await Supabase.instance.client.auth.signUp(
               email: email,
               password: sharedPassword,
               data: {'name': registryCheck['name']},
             );
          } else {
             _error = "Access Denied: You are not registered for this exam portal. Please contact the administrator.";
             _isLoading = false;
             notifyListeners();
             return false;
          }
        } catch (provisioningError) {
          _error = "System error during account verification: ${provisioningError.toString()}";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (response != null && response.user != null) {
        // 5. Device Binding Logic (with retry and auto-healing)
        Map<String, dynamic>? profile = await _lookupProfile(response.user!.id);
        
        if (profile == null) {
          // Trigger might have missed it or was slow. Try to "heal" the profile.
          try {
             final registryCheck = await Supabase.instance.client
                .from('student_registry')
                .select()
                .eq('email', email)
                .maybeSingle();
             
             await Supabase.instance.client.from('profiles').upsert({
               'id': response.user!.id,
               'email': email,
               'name': registryCheck?['name'] ?? email.split('@')[0],
               'role': 'student'
             });
             
             // Try lookup one last time
             profile = await _lookupProfile(response.user!.id);
          } catch (e) {
            debugPrint("Auto-healing failed: $e");
          }
        }
        
        if (profile == null) {
          _error = "Profile synchronization failed. Please try again in a moment.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        String? boundId = profile['device_id'];

        if (boundId == null) {
          // Bind this device as it's their first successful login
          await Supabase.instance.client
              .from('profiles')
              .update({'device_id': deviceId})
              .eq('email', email);
          boundId = deviceId;
        }
        
        if (boundId != deviceId) {
          await Supabase.instance.client.auth.signOut();
          _error = "This exam seat is already bound to another device. Please contact the proctor.";
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

  Future<Map<String, dynamic>?> _lookupProfile(String userId) async {
    return await Supabase.instance.client
        .from('profiles')
        .select('device_id')
        .eq('id', userId)
        .maybeSingle();
  }
}

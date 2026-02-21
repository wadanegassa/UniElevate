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
      // 1. Fetch latest exam to validate the access command
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
        _error = "No active exam found. Please ask your supervisor to deploy an exam first.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Validate the access command — this is the ONLY gate.
      // Normalize both sides: strip all spaces, underscores, and hyphens so that
      // voice-spoken "START NOW" matches a stored code of "START_NOW".
      String _normalize(String s) => s.trim().toUpperCase().replaceAll(RegExp(r'[\s_\-]+'), '');

      final expected = _normalize(exam.accessCode ?? "");
      final received = _normalize(password);

      debugPrint('AuthProvider: Access command check — expected: "$expected", received: "$received"');

      if (received != expected || expected.isEmpty) {
        _error = "Invalid Access Command. Please check the command and try again.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Fetch shared password for Auth provisioning
      final settings = await _supabaseService.fetchSettings();
      final sharedPassword = settings['global_student_password'] ?? 'haramaya_student_2026';

      String deviceId = await _getDeviceId();

      // 4. Auto-provision: Try sign-in first, then sign-up if no account exists.
      //    No student_registry check — the correct access command IS the proof of eligibility.
      AuthResponse? response;
      try {
        response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: sharedPassword,
        );
        debugPrint('AuthProvider: Existing account signed in for $email');
      } catch (authError) {
        if (authError.toString().contains('429')) {
          rethrow;
        }
        // Account doesn't exist yet — create it automatically
        debugPrint('AuthProvider: No existing account, auto-provisioning for $email');
        try {
          response = await Supabase.instance.client.auth.signUp(
            email: email,
            password: sharedPassword,
            data: {'name': email.split('@')[0]},
          );
          debugPrint('AuthProvider: Auto-provisioned new account for $email');
        } catch (signUpError) {
          _error = "Failed to create account: ${signUpError.toString()}";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (response != null && response.user != null) {
        debugPrint('AuthProvider: Login successful for ${response.user!.id}. Syncing profile...');
        
        // 5. Device Binding Logic (with retry and auto-healing)
        Map<String, dynamic>? profile;
        try {
          profile = await _lookupProfile(response.user!.id);
          debugPrint('AuthProvider: Initial profile lookup result: $profile');
        } catch (e) {
          debugPrint('AuthProvider: Initial lookup FAILED with error: $e');
        }
        
        if (profile == null) {
          debugPrint('AuthProvider: Profile missing. Auto-creating profile...');
          try {
            final upsertData = {
              'id': response.user!.id,
              'email': email,
              'name': email.split('@')[0],
              'role': 'student'
            };
            debugPrint('AuthProvider: Performing profile upsert: $upsertData');

            await Supabase.instance.client.from('profiles').upsert(upsertData).select().maybeSingle();

            // Try lookup one last time
            profile = await _lookupProfile(response.user!.id);
            debugPrint('AuthProvider: Post-creation lookup result: $profile');
          } catch (e) {
            debugPrint("AuthProvider: Profile creation CRITICALLY failed: $e");
          }
        }
        
        if (profile == null) {
          debugPrint('AuthProvider: Profile synchronization failed after all attempts.');
          _error = "Profile synchronization failed. Please contact your administrator and try again.";
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
        .select('*')
        .eq('id', userId)
        .maybeSingle();
  }
}

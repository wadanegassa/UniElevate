import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _user = Supabase.instance.client.auth.currentUser;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(email, password);
      final user = response.user;
      
      if (user == null) throw "Authentication failed.";

      // Security Check: Look up the profile to verify the role
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (profile['role'] != 'admin') {
        await _supabaseService.signOut();
        _error = "Access Denied: You do not have administrator privileges.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _user = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().contains('406') ? "Invalid email or password" : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _supabaseService.signOut();
    _user = null;
    notifyListeners();
  }
}

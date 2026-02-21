import 'package:flutter/material.dart';
import '../models/answer_model.dart';
import '../services/supabase_service.dart';

class MonitorProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Answer> _recentAnswers = [];
  bool _isMonitoring = false;

  List<Answer> get recentAnswers => _recentAnswers;
  bool get isMonitoring => _isMonitoring;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _supabaseService.monitorAnswers().listen((answers) {
      _recentAnswers = answers;
      notifyListeners();
    });
  }

  Future<void> fetchHistory() async {
    _recentAnswers = await _supabaseService.fetchAllAnswers();
    notifyListeners();
  }
}

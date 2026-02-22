import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Exam?> fetchActiveExam() async {
    try {
      debugPrint('SupabaseService: Fetching active exam for mobile client...');
      
      final response = await _client
          .from('exams')
          .select()
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        debugPrint('SupabaseService: No active exam found.');
        return null;
      }

      final examData = response;
      debugPrint('SupabaseService: Found active exam: ${examData['title']}');

      // Fetch questions
      final questionsResponse = await _client
          .from('questions')
          .select()
          .eq('exam_id', examData['id']);

      final List<Question> questions = (questionsResponse as List)
          .map((q) => Question.fromJson(q))
          .toList();

      return Exam.fromJson(examData, questions: questions);
    } catch (e) {
      debugPrint('SupabaseService: Error fetching active exam: $e');
      rethrow;
    }
  }

  Future<bool> isStudentRegistered(String email) async {
    try {
      // 1. Check student_registry (pre-approved)
      final registryResponse = await _client
          .from('student_registry')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      
      if (registryResponse != null) return true;

      // 2. Or check if already have a profile (already auto-provisioned)
      final profileResponse = await _client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .eq('role', 'student')
          .maybeSingle();
      
      return profileResponse != null;
    } catch (e) {
      debugPrint('SupabaseService: Error checking registration: $e');
      return false;
    }
  }

  Future<void> submitAnswer(Answer answer) async {
    try {
      await _client.from('answers').insert(answer.toJson());
    } catch (e) {
      debugPrint('Error submitting answer: $e');
    }
  }

  Future<bool> verifyDeviceBinding(String email, String deviceId) async {
    // This assumes a 'users' or 'profiles' table with device_binding field
    // For the hackathon, we can simplify or mock this if the table doesn't exist yet
    // But let's follow the requirement: "Device binding verification via Supabase"
    try {
      final response = await _client
          .from('profiles')
          .select('device_id')
          .eq('email', email)
          .single();
      
      return response['device_id'] == deviceId;
    } catch (e) {
      debugPrint('Error verifying device binding: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    try {
      final response = await _client.from('app_settings').select().eq('id', 'main').single();
      return response;
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      return {'global_student_password': 'haramaya_student_2026'};
    }
  }
}

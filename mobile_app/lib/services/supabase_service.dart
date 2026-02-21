import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Exam?> fetchLatestExam() async {
    try {
      debugPrint('SupabaseService: Fetching latest exam for mobile client...');
      
      // Use standard select without maybeSingle to catch empty list explicitly
      final response = await _client
          .from('exams')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response == null || (response as List).isEmpty) {
        debugPrint('SupabaseService: No exams found in the database.');
        return null;
      }

      final examData = response.first as Map<String, dynamic>;
      debugPrint('SupabaseService: Found exam: ${examData['title']} (Access Code: ${examData['access_code']})');

      // Fetch questions with specific ordering if available
      final questionsResponse = await _client
          .from('questions')
          .select()
          .eq('exam_id', examData['id']);

      if (questionsResponse == null) {
        debugPrint('SupabaseService: Questions fetch returned null for exam ${examData['id']}');
        return Exam.fromJson(examData, questions: []);
      }

      final List<Question> questions = (questionsResponse as List)
          .map((q) => Question.fromJson(q))
          .toList();

      debugPrint('SupabaseService: Successfully loaded exam with ${questions.length} questions.');
      return Exam.fromJson(examData, questions: questions);
    } catch (e, stack) {
      debugPrint('SupabaseService: EXCEPTION during fetchLatestExam: $e');
      debugPrint('Stacktrace: $stack');
      rethrow; // Propagate up to AuthProvider/ExamProvider
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

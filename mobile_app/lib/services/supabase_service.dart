import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Exam?> fetchLatestExam() async {
    try {
      final examResponse = await _client
          .from('exams')
          .select()
          .order('start_time', ascending: false)
          .limit(1)
          .single();

      final questionsResponse = await _client
          .from('questions')
          .select()
          .eq('exam_id', examResponse['id']);

      final List<Question> questions = (questionsResponse as List)
          .map((q) => Question.fromJson(q))
          .toList();

      return Exam.fromJson(examResponse, questions: questions);
    } catch (e) {
      print('Error fetching exam: $e');
      return null;
    }
  }

  Future<void> submitAnswer(Answer answer) async {
    try {
      await _client.from('answers').insert(answer.toJson());
    } catch (e) {
      print('Error submitting answer: $e');
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
      print('Error verifying device binding: $e');
      return false;
    }
  }
}

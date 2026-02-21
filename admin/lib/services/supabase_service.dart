import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/student_model.dart';
import '../models/answer_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- Auth ---
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // --- Exams ---
  Future<List<Exam>> fetchExams() async {
    final response = await _client.from('exams').select().order('created_at', ascending: false);
    return (response as List).map((e) => Exam.fromJson(e)).toList();
  }

  Future<Exam> createExam(Exam exam) async {
    final response = await _client.from('exams').insert(exam.toJson()).select().single();
    return Exam.fromJson(response);
  }

  // --- Questions ---
  Future<void> addQuestions(List<Question> questions) async {
    await _client.from('questions').insert(questions.map((q) => q.toJson()).toList());
  }

  Future<List<Question>> fetchQuestions(String examId) async {
    final response = await _client.from('questions').select().eq('exam_id', examId);
    return (response as List).map((q) => Question.fromJson(q)).toList();
  }

  // --- Students ---
  Future<List<Student>> fetchStudents() async {
    final response = await _client.from('profiles').select().eq('role', 'student');
    return (response as List).map((s) => Student.fromJson(s)).toList();
  }

  Future<void> assignExamToStudent(String studentId, String examId) async {
    final student = await _client.from('profiles').select().eq('id', studentId).single();
    List<String> exams = List<String>.from(student['assigned_exam_ids'] ?? []);
    if (!exams.contains(examId)) {
      exams.add(examId);
      await _client.from('profiles').update({'assigned_exam_ids': exams}).eq('id', studentId);
    }
  }

  // --- Real-time Monitoring ---
  Stream<List<Answer>> monitorAnswers() {
    return _client
        .from('answers')
        .stream(primaryKey: ['student_id', 'question_id', 'timestamp'])
        .order('timestamp', ascending: false)
        .map((data) => data.map((json) => Answer.fromJson(json)).toList());
  }

  // Fetch all answers for reporting
  Future<List<Answer>> fetchAllAnswers() async {
    final response = await _client.from('answers').select().order('timestamp', ascending: false);
    return (response as List).map((a) => Answer.fromJson(a)).toList();
  }
}

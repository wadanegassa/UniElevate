import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/student_model.dart';
import '../services/supabase_service.dart';

class ExamManagerProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Exam> _exams = [];
  List<Student> _students = [];
  bool _isLoading = false;

  List<Exam> get exams => _exams;
  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    _exams = await _supabaseService.fetchExams();
    _students = await _supabaseService.fetchStudents();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createExamWithQuestions(Exam exam, List<Question> questions) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newExam = await _supabaseService.createExam(exam);
      final questionsWithId = questions.map((q) => Question(
        id: '',
        examId: newExam.id,
        text: q.text,
        type: q.type,
        options: q.options,
        correctAnswer: q.correctAnswer,
        keywords: q.keywords,
      )).toList();
      await _supabaseService.addQuestions(questionsWithId);
      await loadInitialData();
    } catch (e) {
      debugPrint('Error creating exam: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> assignExam(String studentId, String examId) async {
    await _supabaseService.assignExamToStudent(studentId, examId);
    await loadInitialData();
  }
}

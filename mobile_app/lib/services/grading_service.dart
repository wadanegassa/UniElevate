import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/question_model.dart';

class GradingService {
  final String apiKey;
  late final GenerativeModel _model;

  GradingService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<GradingResult> gradeAnswer(Question question, String transcript) async {
    if (question.type == QuestionType.mcq) {
      return _gradeMCQ(question, transcript);
    } else {
      return _gradeTheory(question, transcript);
    }
  }

  GradingResult _gradeMCQ(Question question, String transcript) {
    bool isCorrect = transcript.toLowerCase().trim() == question.correctAnswer?.toLowerCase().trim();
    return GradingResult(
      isCorrect: isCorrect,
      score: isCorrect ? 1.0 : 0.0,
      feedback: isCorrect ? "Excellent! That is correct." : "I'm sorry, that is not correct.",
    );
  }

  Future<GradingResult> _gradeTheory(Question question, String transcript) async {
    final prompt = """
    Evaluate this student's answer to a theory question.
    Question: ${question.text}
    Keywords to look for: ${question.keywords?.join(', ')}
    Student Answer: $transcript
    
    Provide a JSON response with:
    - is_correct: boolean (true if it covers the main points)
    - score: number between 0 and 1
    - feedback: concise encouraging feedback
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      // Simplified parsing for hackathon - in production use proper JSON parsing
      final text = response.text ?? "";
      
      // Basic heuristic if AI fails or returns non-JSON
      bool containsKeywords = question.keywords?.any((k) => transcript.toLowerCase().contains(k.toLowerCase())) ?? false;
      
      return GradingResult(
        isCorrect: text.contains('"is_correct": true') || containsKeywords,
        score: text.contains('"score": 1') ? 1.0 : 0.5,
        feedback: "Interesting perspective. ${containsKeywords ? "You hit several key points." : "Try to be more specific next time."}",
      );
    } catch (e) {
      debugPrint('Error grading answer: $e');
      return GradingResult(
        isCorrect: false,
        score: 0.0,
        feedback: "I had trouble processing that. Let's move on.",
      );
    }
  }
}

class GradingResult {
  final bool isCorrect;
  final double score;
  final String feedback;

  GradingResult({
    required this.isCorrect,
    required this.score,
    required this.feedback,
  });
}

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
      feedback: "I've recorded your answer.",
    );
  }

  Future<GradingResult> _gradeTheory(Question question, String transcript) async {
    final prompt = """
    You are an expert examiner for blind students. Evaluate the following spoken answer.
    
    Question: ${question.text}
    Required Keywords/Concepts: ${question.keywords?.join(', ')}
    
    Student's Spoken Transcript: "$transcript"
    
    Instructions:
    1. Ignore speech artifacts like "umm", "err", "i think", "maybe", or repetitions.
    2. Handle homophones gracefully (e.g., "cell" vs "sell", "weather" vs "whether") as this is a voice-to-text transcript.
    3. Focus on the semantic meaning. Does the student demonstrate understanding of the core concepts?
    4. Even if the grammar is poor (due to STT errors), if the keywords or their synonyms are present and correctly related, it is correct.
    
    Response Format (STRICT JSON):
    {
      "is_correct": boolean,
      "score": number (0.0 to 1.0),
      "feedback": "Concise, encouraging audio-friendly feedback that does NOT reveal if the answer was correct or incorrect. Just acknowledge receipt."
    }
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? "";
      
      // Attempt to find JSON in the response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        // Simple manual parsing to avoid adding json dependency if not needed
        // but let's assume we can use basic string checks for this hackathon
        bool isCorrect = jsonStr.contains('"is_correct": true');
        double score = 0.0;
        if (jsonStr.contains('"score": 1')) {
          score = 1.0;
        } else if (jsonStr.contains('"score": 0')) {
          score = 0.5; // Partial credit
        }
        
        String feedback = "I've recorded your answer.";
        final feedbackMatch = RegExp(r'"feedback":\s*"(.*?)"').firstMatch(jsonStr);
        if (feedbackMatch != null) {
          feedback = feedbackMatch.group(1)!;
        }

        return GradingResult(
          isCorrect: isCorrect,
          score: score,
          feedback: feedback,
        );
      }
      
      // Fallback to keyword matching if AI output is messy
      bool containsKeywords = question.keywords?.any((k) => transcript.toLowerCase().contains(k.toLowerCase())) ?? false;
      return GradingResult(
        isCorrect: containsKeywords,
        score: containsKeywords ? 0.8 : 0.0,
        feedback: "I've recorded your answer. Well done.",
      );
    } catch (e) {
      debugPrint('Error grading answer: $e');
      return GradingResult(
        isCorrect: false,
        score: 0.0,
        feedback: "I've noted your answer. Let's move to the next one.",
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

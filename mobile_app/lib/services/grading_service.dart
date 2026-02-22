import 'dart:convert';
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
    // Normalize both the transcript and the correct answer for comparison
    // transcript might be "Option A" or just "A"
    String normalizedTranscript = transcript.toUpperCase().replaceAll("OPTION", "").replaceAll(RegExp(r'[^\w]'), "").trim();
    String normalizedCorrect = (question.correctAnswer ?? "").toUpperCase().replaceAll("OPTION", "").replaceAll(RegExp(r'[^\w]'), "").trim();
    
    // Check if the answer matches either the letter or the full option text
    bool isCorrect = normalizedTranscript == normalizedCorrect;
    
    if (!isCorrect && question.options != null && normalizedTranscript.length == 1) {
       // If student said "A", and correctAnswer is "A", isCorrect is true.
       // But if student said "A" and correctAnswer is the full text of option A, 
       // we should also count it as correct.
       int index = normalizedTranscript.codeUnitAt(0) - 65;
       if (index >= 0 && index < question.options!.length) {
         String optionText = question.options![index].toUpperCase().trim();
         if (optionText == normalizedCorrect) isCorrect = true;
       }
    }
    
    return GradingResult(
      isCorrect: isCorrect,
      score: isCorrect ? 1.0 : 0.0,
      feedback: "Answer recorded. Moving to the next question.",
    );
  }

  Future<GradingResult> _gradeTheory(Question question, String transcript) async {
    final prompt = """
    You are an expert examiner for blind students. Evaluate the following spoken answer for semantic correctness.
    
    Question: ${question.text}
    Required Keywords/Concepts: ${question.keywords?.join(', ')}
    
    Student's Spoken Transcript: "$transcript"
    
    Instructions:
    1. EXTREME LENIENCY: This is a speech-to-text transcript. Ignore phonetic errors, missing punctuation, "umm/err" fillers, and repetitions.
    2. SEMANTIC FOCUS: If the student mentions the core concepts or their synonyms correctly, mark it as correct.
    3. HOMOPHONES: Correct for homophones (e.g., "cell" vs "sell").
    4. PARTIAL CREDIT: If they get some parts right, give a score between 0.1 and 0.9.
    
    Response Format (STRICT JSON):
    {
      "is_correct": boolean,
      "score": number (0.0 to 1.0),
      "feedback": "A very short, neutral response like 'Recorded' or 'Got it'. DO NOT indicate if the answer was right or wrong, and DO NOT reveal the correct answer."
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
        try {
          final decoded = json.decode(jsonStr) as Map<String, dynamic>;
          final isCorrect = decoded['is_correct'] == true;
          final score = (decoded['score'] as num?)?.toDouble() ?? (isCorrect ? 1.0 : 0.0);
          final feedback = decoded['feedback']?.toString() ?? "Answer recorded.";

          return GradingResult(
            isCorrect: isCorrect,
            score: score,
            feedback: feedback,
          );
        } catch (e) {
          debugPrint('JSON parse error: $e');
        }
      }
      
      // Fallback to keyword matching if AI output is messy
      bool containsKeywords = question.keywords?.any((k) => transcript.toLowerCase().contains(k.toLowerCase())) ?? false;
      return GradingResult(
        isCorrect: containsKeywords,
        score: containsKeywords ? 0.8 : 0.0,
        feedback: "Answer recorded. Let's move to the next one.",
      );
    } catch (e) {
      debugPrint('Error grading answer: $e');
      return GradingResult(
        isCorrect: false,
        score: 0.0,
        feedback: "Answer recorded. Moving forward.",
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

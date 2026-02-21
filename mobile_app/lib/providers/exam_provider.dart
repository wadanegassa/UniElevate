import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';
import '../models/aura_state.dart';
import '../services/supabase_service.dart';
import '../services/voice_service.dart';
import '../services/grading_service.dart';

class ExamProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final VoiceService _voiceService = VoiceService();
  final GradingService _gradingService;

  Exam? _currentExam;
  int _currentQuestionIndex = 0;
  Timer? _examTimer;
  int _remainingSeconds = 0;
  AuraState _auraState = AuraState.idle;
  String _liveTranscript = "";
  bool _isFinished = false;

  Exam? get currentExam => _currentExam;
  Question? get currentQuestion => _currentExam != null && _currentQuestionIndex < _currentExam!.questions.length 
      ? _currentExam!.questions[_currentQuestionIndex] 
      : null;
  int get remainingSeconds => _remainingSeconds;
  AuraState get auraState => _auraState;
  String get liveTranscript => _liveTranscript;
  bool get isFinished => _isFinished;

  ExamProvider({required String geminiApiKey}) : _gradingService = GradingService(apiKey: geminiApiKey);

  Future<void> startExam() async {
    _currentExam = await _supabaseService.fetchLatestExam();
    if (_currentExam != null) {
      _remainingSeconds = _currentExam!.duration * 60;
      _startTimer();
      _readQuestion();
    }
  }

  void _startTimer() {
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        if (_remainingSeconds % 600 == 0 && _remainingSeconds != 0) {
          _announceTimeLeft();
        }
        notifyListeners();
      } else {
        finishExam();
      }
    });
  }

  Future<void> _announceTimeLeft() async {
    int minutes = _remainingSeconds ~/ 60;
    await _voiceService.speak("$minutes minutes remaining.");
  }

  Future<void> _readQuestion() async {
    if (currentQuestion == null) return;
    
    _setAuraState(AuraState.aiSpeaking);
    String text = "Question ${_currentQuestionIndex + 1}. ${currentQuestion!.text}";
    if (currentQuestion!.type == QuestionType.mcq) {
      text += " Options are: ${currentQuestion!.options?.join(', ')}";
    }
    await _voiceService.speak(text);
    _setAuraState(AuraState.idle);
  }

  Future<void> repeatQuestion() async {
    await _readQuestion();
  }

  Future<void> startListening() async {
    _setAuraState(AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (transcript) {
        _liveTranscript = transcript;
        notifyListeners();
        _processAnswer(transcript);
      },
      onListeningChanged: (isListening) {
        if (!isListening) _setAuraState(AuraState.idle);
      },
    );
  }

  Future<void> _processAnswer(String transcript) async {
    _setAuraState(AuraState.processing);
    final result = await _gradingService.gradeAnswer(currentQuestion!, transcript);
    
    // Provide feedback
    _setAuraState(AuraState.aiSpeaking);
    if (result.isCorrect) {
      Vibration.vibrate(duration: 500);
    } else {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
    await _voiceService.speak(result.feedback);

    // Save answer
    final answer = Answer(
      studentId: "student_uuid", // Should come from AuthProvider
      questionId: currentQuestion!.id,
      transcript: transcript,
      isCorrect: result.isCorrect,
      score: result.score,
      feedback: result.feedback,
      timestamp: DateTime.now(),
    );
    await _supabaseService.submitAnswer(answer);

    _nextQuestion();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < (_currentExam?.questions.length ?? 0) - 1) {
      _currentQuestionIndex++;
      _liveTranscript = "";
      _readQuestion();
    } else {
      finishExam();
    }
    notifyListeners();
  }

  Future<void> finishExam() async {
    _examTimer?.cancel();
    _isFinished = true;
    _setAuraState(AuraState.aiSpeaking);
    await _voiceService.speak("Congratulations! You have completed the exam. Well done for your hard work.");
    _setAuraState(AuraState.idle);
    notifyListeners();
  }

  void _setAuraState(AuraState state) {
    _auraState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _examTimer?.cancel();
    _voiceService.stopSpeaking();
    super.dispose();
  }
}

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
  String? _studentId;

  Exam? get currentExam => _currentExam;
  Question? get currentQuestion => _currentExam != null && _currentQuestionIndex < _currentExam!.questions.length 
      ? _currentExam!.questions[_currentQuestionIndex] 
      : null;
  int get remainingSeconds => _remainingSeconds;
  AuraState get auraState => _auraState;
  String get liveTranscript => _liveTranscript;
  bool get isFinished => _isFinished;

  ExamProvider({required String geminiApiKey}) : _gradingService = GradingService(apiKey: geminiApiKey);

  Future<void> startExam({String? studentId}) async {
    _studentId = studentId;
    debugPrint('ExamProvider: startExam called for student $studentId');
    _currentExam = await _supabaseService.fetchLatestExam();
    notifyListeners();
    
    if (_currentExam != null) {
      debugPrint('ExamProvider: Exam loaded successfully: ${_currentExam!.title}');
      _remainingSeconds = _currentExam!.duration * 60;
      _startTimer();
      _welcome();
    } else {
      debugPrint('ExamProvider: Failed to load exam. Possible causes: Empty table or network issue.');
      _voiceService.speak("Critical error. I could not find any active exams in the system. Please alert your supervisor immediately.");
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

  Future<void> _welcome() async {
    _setAuraState(AuraState.aiSpeaking);
    await _voiceService.speak(
      "Welcome to the Uni Elevate Digital Exam Portal. You are now taking ${_currentExam!.title}. Are you ready to begin?",
      onComplete: () => _listenForReadiness(),
    );
  }

  String _normalizeCommand(String text) {
    final lower = text.toLowerCase().trim();
    debugPrint('ExamProvider: Normalizing text: "$lower"');
    
    if (lower.contains("yes") || 
        lower.contains("yeah") || 
        lower.contains("yep") || 
        lower.contains("sure") || 
        lower.contains("correct") || 
        lower.contains("ready") ||
        lower.contains("begin") ||
        lower.contains("let's go") ||
        lower.contains("start") ||
        lower.contains("ok") ||
        lower.contains("okay") ||
        lower.contains("i am ready") ||
        lower.contains("i'm ready") ||
        lower.contains("proceed") ||
        lower.contains("go ahead")) return "yes";
        
    if (lower.contains("no") || 
        lower.contains("nope") || 
        lower.contains("wrong") || 
        lower.contains("stop") ||
        lower.contains("wait") ||
        lower.contains("try again")) return "no";
        
    if (lower.contains("repeat") || 
        lower.contains("read again") || 
        lower.contains("one more time")) return "repeat";
        
    if (lower.contains("next") || 
        lower.contains("skip")) return "next";
    
    // Strict MCQ parsing: Check for single letters A-E
    final mcqMatch = RegExp(r'\b[a-e]\b').firstMatch(lower);
    if (mcqMatch != null) {
      final letter = mcqMatch.group(0)!.toUpperCase();
      debugPrint('ExamProvider: Detected MCQ Option $letter');
      return letter;
    }
    
    return lower;
  }

  bool _handleGlobalCommands(String command) {
    if (command == "repeat") {
      repeatQuestion();
      return true;
    }
    if (command == "next") {
      _nextQuestion();
      return true;
    }
    return false;
  }

  Future<void> _listenForReadiness() async {
    _setAuraState(AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (transcript) {
        final command = _normalizeCommand(transcript);
        if (_handleGlobalCommands(command)) return;

        if (command == "yes") {
          _readQuestion();
        } else {
          debugPrint('ExamProvider: Transcript did not match "yes": $transcript');
          _voiceService.speak("I didn't quite catch that. Please say yes when you are ready to begin.", onComplete: () => _listenForReadiness());
        }
      },
      onListeningChanged: (isListening) {
        if (!isListening && _auraState == AuraState.studentSpeaking) _setAuraState(AuraState.idle);
      },
      onError: () {
        debugPrint('ExamProvider: Readiness check failed or timed out.');
        _voiceService.speak("I didn't hear you. Please say yes when you are ready to begin.", onComplete: () => _listenForReadiness());
      },
    );
  }

  Future<void> _readQuestion() async {
    debugPrint('ExamProvider: _readQuestion called. Index: $_currentQuestionIndex');
    if (currentQuestion == null) {
      debugPrint('ExamProvider: Error - currentQuestion is null at index $_currentQuestionIndex');
      return;
    }
    
    _setAuraState(AuraState.aiSpeaking);
    String text = "Question ${_currentQuestionIndex + 1}. ${currentQuestion!.text}";
    
    if (currentQuestion!.type == QuestionType.mcq && currentQuestion!.options != null) {
      text += ". The options are: ";
      final options = currentQuestion!.options!;
      for (int i = 0; i < options.length; i++) {
        String letter = String.fromCharCode(65 + i); // 65 is 'A'
        text += "Option $letter: ${options[i]}. ";
      }
      text += ". Please say the letter of your choice.";
    }
    
    debugPrint('ExamProvider: Speaking question text: "$text"');
    await _voiceService.speak(text, onComplete: () {
      debugPrint('ExamProvider: Finished speaking question. Starting to listen...');
      startListening();
    });
  }

  Future<void> repeatQuestion() async {
    debugPrint('ExamProvider: repeatQuestion called');
    await _readQuestion();
  }

  Future<void> startListening() async {
    _setAuraState(AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (transcript) {
        final command = _normalizeCommand(transcript);
        if (_handleGlobalCommands(command)) return;

        _liveTranscript = transcript;
        notifyListeners();
        _confirmAnswer(command.length == 1 ? command : transcript);
      },
      onListeningChanged: (isListening) {
        if (!isListening && _auraState == AuraState.studentSpeaking) _setAuraState(AuraState.idle);
      },
      onError: () {
        debugPrint('ExamProvider: Main listening failed or timed out.');
        _voiceService.speak("I didn't quite get that. Could you please repeat your answer?", onComplete: () => startListening());
      },
    );
  }

  Future<void> _confirmAnswer(String displayTranscript) async {
    _setAuraState(AuraState.aiSpeaking);
    final prompt = currentQuestion!.type == QuestionType.mcq && displayTranscript.length == 1
        ? "I heard option $displayTranscript. Is this correct?"
        : "I heard: $displayTranscript. Is this correct?";
        
    await _voiceService.speak(
      "$prompt Please say yes to confirm or no to try again.",
      onComplete: () => _listenForConfirmation(displayTranscript),
    );
  }

  Future<void> _listenForConfirmation(String originalTranscript) async {
    _setAuraState(AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (transcript) {
        final command = _normalizeCommand(transcript);
        if (_handleGlobalCommands(command)) return;

        if (command == "yes") {
          _processAnswer(originalTranscript);
        } else {
          _voiceService.speak("Okay, please tell me your answer again.", onComplete: () => startListening());
        }
      },
      onListeningChanged: (isListening) {
        if (!isListening && _auraState == AuraState.studentSpeaking) _setAuraState(AuraState.idle);
      },
      onError: () {
        debugPrint('ExamProvider: Confirmation listening failed or timed out.');
        _voiceService.speak("Was that a yes or a no?", onComplete: () => _listenForConfirmation(originalTranscript));
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
    
    await _voiceService.speak(result.feedback, onComplete: () => _nextQuestion());

    // Save answer
    final answer = Answer(
      studentId: _studentId ?? "anonymous",
      questionId: currentQuestion!.id,
      transcript: transcript,
      isCorrect: result.isCorrect,
      score: result.score,
      feedback: result.feedback,
      timestamp: DateTime.now(),
    );
    await _supabaseService.submitAnswer(answer);
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

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

import '../services/voice_utils.dart';

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
  bool _isTransitioning = false;
  ExamSession _currentSessionType = ExamSession.none;
  String? _studentId;
  VoidCallback? _onLogout;

  Exam? get currentExam => _currentExam;
  Question? get currentQuestion => _currentExam != null && _currentQuestionIndex < _currentExam!.questions.length 
      ? _currentExam!.questions[_currentQuestionIndex] 
      : null;
  int get remainingSeconds => _remainingSeconds;
  AuraState get auraState => _auraState;
  String get liveTranscript => _liveTranscript;
  bool get isFinished => _isFinished;

  ExamProvider({required String geminiApiKey}) : _gradingService = GradingService(apiKey: geminiApiKey);

  Future<void> startExam({String? studentId, VoidCallback? onLogout}) async {
    _studentId = studentId;
    _onLogout = onLogout;
    debugPrint('ExamProvider: startExam called for student $studentId');
    final fetchedExam = await _supabaseService.fetchActiveExam();
    _currentExam = fetchedExam;
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
        if (_remainingSeconds % 300 == 0 && _remainingSeconds != 0) {
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
    debugPrint('ExamProvider: _welcome() called');
    _setAuraState(AuraState.aiSpeaking);
    await _voiceService.speak(
      "Welcome to the Uni Elevate Digital Exam Portal. You are now taking ${_currentExam!.title}. Are you ready to begin?",
      onComplete: () {
        debugPrint('ExamProvider: Welcome TTS complete, calling _listenForReadiness()');
        _listenForReadiness();
      },
    );
  }

  String _normalizeCommand(String text) {
    return VoiceUtils.normalizeCommand(text);
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
    debugPrint('ExamProvider: _listenForReadiness() called');
    if (_voiceService.isSpeaking || _isTransitioning) return;
    
    _currentSessionType = ExamSession.readiness;
    _setAuraState(AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (transcript, confidence) async {
        if (_isTransitioning || _currentSessionType != ExamSession.readiness) return;
        
        debugPrint('ExamProvider: Readiness result: "$transcript" (conf: $confidence)');
        final command = _normalizeCommand(transcript);
        if (_handleGlobalCommands(command)) return;

        if (command == "yes") {
          debugPrint('ExamProvider: Readiness confirmed, transitioning to _readQuestion()');
          _isTransitioning = true;
          _setAuraState(AuraState.idle);
          await _voiceService.stopListening();
          await Future.delayed(const Duration(milliseconds: 1500)); // Increased settle delay
          _isTransitioning = false;
          _readQuestion();
        } else if (command == "no") {
          debugPrint('ExamProvider: Readiness declined');
          await _voiceService.speak(
            "No problem. I'll wait. Just say yes whenever you are ready to begin.",
            onComplete: () => _listenForReadiness(),
          );
        } else {
          debugPrint('ExamProvider: Unrecognized readiness command: "$command"');
          _voiceService.speak(
            "I didn't quite catch that. Please say yes when you are ready to begin.",
            onComplete: () => _listenForReadiness(),
          );
        }
      },
      onListeningChanged: (isListening) {
        if (!isListening && _auraState == AuraState.studentSpeaking) _setAuraState(AuraState.idle);
      },
      onError: () {
        debugPrint('ExamProvider: Readiness check failed or timed out.');
        _voiceService.speak(
          "I didn't hear you. Please say yes when you are ready to begin.",
          onComplete: () => _listenForReadiness(),
        );
      },
    );
  }


  Future<void> _readQuestion() async {
    debugPrint('ExamProvider: _readQuestion() called for index $_currentQuestionIndex');
    final question = currentQuestion;
    if (question == null) {
      debugPrint('ExamProvider: Error - currentQuestion is null at index $_currentQuestionIndex');
      return;
    }

    _setAuraState(AuraState.aiSpeaking);
    _currentSessionType = ExamSession.question;
    
    // Professional header
    String speechText = "Question ${_currentQuestionIndex + 1}. ";
    
    // Differentiate types
    if (question.type == QuestionType.mcq) {
      speechText += "Multiple Choice. ${question.text}. The options are: ";
      if (question.options != null) {
        for (int i = 0; i < question.options!.length; i++) {
          final letter = String.fromCharCode(65 + i);
          speechText += "Option $letter: ${question.options![i]}. ";
        }
      }
      speechText += "Please state your choice.";
    } else {
      speechText += "Theory Question. ${question.text}. You may provide your explanation now.";
    }

    await _voiceService.speak(speechText, onComplete: () => startListening());
  }

  Future<void> repeatQuestion() async {
    debugPrint('ExamProvider: repeatQuestion called');
    await _readQuestion();
  }

  Future<void> startListening() async {
    if (_voiceService.isSpeaking || _isTransitioning) {
      debugPrint('ExamProvider: Ignoring manual startListening - proctor is busy');
      return;
    }

    debugPrint('ExamProvider: Manual startListening called for session $_currentSessionType');
    
    switch (_currentSessionType) {
      case ExamSession.readiness:
        _listenForReadiness();
        break;
      case ExamSession.question:
        _listenForQuestionAnswer();
        break;
      case ExamSession.confirmation:
        // Attempt to resume confirmation if we have a transcript
        if (_liveTranscript.isNotEmpty) {
          _listenForConfirmation(_liveTranscript);
        } else {
          _listenForQuestionAnswer();
        }
        break;
      case ExamSession.none:
        _listenForReadiness();
        break;
    }
  }

  Future<void> _listenForQuestionAnswer() async {
    _setAuraState(AuraState.studentSpeaking);
    _currentSessionType = ExamSession.question;
    await _voiceService.listen(
      onResult: (transcript, confidence) {
        if (_isTransitioning || _currentSessionType != ExamSession.question) return;
        String command = _normalizeCommand(transcript);
        if (_handleGlobalCommands(command)) return;

        // Special handling for MCQ: try to match spoken text to option content
        if (currentQuestion?.type == QuestionType.mcq && currentQuestion?.options != null) {
          final matchedLetter = VoiceUtils.matchOption(transcript, currentQuestion!.options!);
          if (matchedLetter != null) {
            command = matchedLetter;
          }
        }

        String displayAnswer = transcript;
        if (command.length == 1 && RegExp(r'^[A-E]$').hasMatch(command)) {
          displayAnswer = "Option $command";
        }

        _liveTranscript = displayAnswer;
        notifyListeners();

        // SMART CONFIRMATION: Skip confirmation if confidence is very high
        if (confidence > 0.95 && currentQuestion?.type == QuestionType.mcq && displayAnswer.startsWith("Option")) {
          debugPrint('ExamProvider: High confidence ($confidence), skipping confirmation.');
          _processAnswer(displayAnswer);
        } else {
          _confirmAnswer(displayAnswer);
        }
      },
      onListeningChanged: (isListening) {
        if (!isListening && _auraState == AuraState.studentSpeaking) _setAuraState(AuraState.idle);
      },
      onError: () {
        debugPrint('ExamProvider: Question answer failed or timed out.');
        _voiceService.speak("I didn't hear your answer. Please say it again.", onComplete: () => _listenForQuestionAnswer());
      },
    );
  }

  Future<void> _confirmAnswer(String displayTranscript) async {
    _setAuraState(AuraState.aiSpeaking);
    // displayTranscript is already formatted like "Option A"
    await _voiceService.speak(
      "I heard: $displayTranscript. Is this correct? Please say yes to confirm or no to try again.",
      onComplete: () => _listenForConfirmation(displayTranscript),
    );
  }

  Future<void> _listenForConfirmation(String originalTranscript) async {
    if (_voiceService.isSpeaking || _isTransitioning) return;
    _currentSessionType = ExamSession.confirmation;
    _setAuraState(AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (transcript, confidence) {
        if (_isTransitioning || _currentSessionType != ExamSession.confirmation) return;
        final command = _normalizeCommand(transcript);
        if (_handleGlobalCommands(command)) return;

        if (command == "yes") {
          _processAnswer(originalTranscript);
        } else {
          // Check if they provided a new answer in the "no" response
          // e.g., "No, I meant Option B" or "No, it is Berlin"
          String? correctedAnswer;
          if (currentQuestion?.type == QuestionType.mcq && currentQuestion?.options != null) {
            final matchedLetter = VoiceUtils.matchOption(transcript, currentQuestion!.options!);
            if (matchedLetter != null) {
               correctedAnswer = "Option $matchedLetter";
            }
          }
          
          if (correctedAnswer != null) {
            debugPrint('ExamProvider: Detected self-correction: $correctedAnswer');
            _confirmAnswer(correctedAnswer);
          } else {
            _liveTranscript = "";
            notifyListeners();
            _voiceService.speak("Okay, please tell me your answer again.", onComplete: () {
               if (!_isTransitioning) _listenForQuestionAnswer();
            });
          }
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
    if (_isTransitioning) return;
    _isTransitioning = true;
    _setAuraState(AuraState.processing);
    final result = await _gradingService.gradeAnswer(currentQuestion!, transcript);
    
    // Provide feedback
    _setAuraState(AuraState.aiSpeaking);
    if (result.isCorrect) {
      Vibration.vibrate(duration: 500);
    } else {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
    
    await _voiceService.speak(result.feedback, onComplete: () {
      _isTransitioning = false;
      _nextQuestion();
    });

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
    
    // Auto-logout after a short delay to allow the voice to finish
    await Future.delayed(const Duration(seconds: 2));
    if (_onLogout != null) {
      _onLogout!();
    }
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

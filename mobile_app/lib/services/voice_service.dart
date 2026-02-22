import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;

  Future<void> init() async {
    await _initAudioSession();
    await _initTts();
    await _initStt();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));
    debugPrint('VoiceService: AudioSession configured for Voice Communication');
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4); // Slower for extreme clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isTtsInitialized = true;

    _tts.setStartHandler(() {
      _isSpeaking = true;
      debugPrint('VoiceService: TTS Started speaking');
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      debugPrint('VoiceService: TTS Finished speaking');
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('VoiceService: TTS Error: $msg');
    });
  }

  Future<void> _initStt() async {
    bool available = await _stt.initialize(
      onError: (error) {
        debugPrint('STT Global Error: ${error.errorMsg}');
        if (_activeListenSessionId > 0 && _isListeningForCurrentSession) {
          debugPrint('VoiceService [#$_activeListenSessionId]: Forwarding STT Engine Error: ${error.errorMsg}');
          if (_currentOnError != null) _currentOnError!();
        }
      },
      onStatus: (status) => debugPrint('STT Global Status: $status'),
    );
    if (!available) {
      debugPrint('STT not available');
    }
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (!_isTtsInitialized) await _initTts();
    
    debugPrint('VoiceService: speak() called with: "$text"');
    
    // Stop any existing session
    await stopSpeaking();
    await stopListening();

    final processedText = text.replaceAll("...", "... ");

    // Safety timeout to ensure onComplete is called even if TTS engine hangs
    Timer? safetyTimer;
    
    void handleComplete() {
      safetyTimer?.cancel();
      if (_isSpeaking) {
        _isSpeaking = false;
        debugPrint('VoiceService: speak() completed');
        if (onComplete != null) onComplete();
      }
    }

    _tts.setCompletionHandler(handleComplete);

    // Guard: most sentences should finish in < 20s
    safetyTimer = Timer(const Duration(seconds: 20), () async {
      debugPrint('VoiceService: speak() safety timeout triggered. Force stopping TTS.');
      await _tts.stop(); // Force native stop
      handleComplete();
    });

    _isSpeaking = true;
    await _tts.speak(processedText);
  }

  Future<void> stopSpeaking() async {
    _tts.setCompletionHandler(() {}); 
    await _tts.stop();
    _isSpeaking = false;
    debugPrint('VoiceService: stopSpeaking() called');
  }

  String _lastWords = "";
  String _lastEmittedTranscript = "";
  DateTime _lastEmitTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _activeListenSessionId = 0;
  bool _isListeningForCurrentSession = false;
  VoidCallback? _currentOnError;

  Future<void> listen({
    required Function(String, double) onResult,
    required Function(bool) onListeningChanged,
    VoidCallback? onError,
  }) async {
    // 0. Safety Check: If we are still speaking, wait or abort
    if (_isSpeaking) {
      debugPrint('VoiceService: Aborting listen - TTS is active');
      return;
    }

    // 1. Ensure microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('VoiceService: Microphone permission denied');
        if (onError != null) onError();
        return;
      }
    }

    // 2. Stop if already listening
    if (_stt.isListening) {
      debugPrint('VoiceService: Already listening, stopping previous session');
      await _stt.stop();
      onListeningChanged(false);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 3. Ensure STT is initialized
    if (!_stt.isAvailable) {
      await _initStt();
      if (!_stt.isAvailable) {
        debugPrint('VoiceService: STT initialization failed');
        if (onError != null) onError();
        return;
      }
    }

    // 4. Session Locking: Generate a unique ID for this call
    final sessionId = ++_activeListenSessionId;
    _isListeningForCurrentSession = true;
    _currentOnError = onError;
    debugPrint('VoiceService: Starting session #$sessionId');

    // 5. Reset local session state
    final previousTranscript = _lastWords;
    _lastWords = "";
    bool resultEmitted = false;
    final sessionStartTime = DateTime.now();
    
    // Mandatory Guard Delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Ensure we are still the active session after the delay
    if (sessionId != _activeListenSessionId) {
      debugPrint('VoiceService: Session #$sessionId aborted - newer session started during delay');
      return;
    }

    onListeningChanged(true);

    try {
      await _stt.listen(
        onResult: (result) {
          // SESSION LOCK: Only process results for THIS session
          if (sessionId != _activeListenSessionId) return;

          final currentWords = result.recognizedWords.trim();
          if (currentWords.isEmpty) return;

          // FRESHNESS SAFEGUARD (Layer 1): Ignore buffer leakage from previous hardware state
          final elapsedSinceStart = DateTime.now().difference(sessionStartTime).inMilliseconds;
          if (elapsedSinceStart < 800 && currentWords == previousTranscript) {
            debugPrint('VoiceService [#$sessionId]: Ignoring buffer leak: "$currentWords"');
            return;
          }

          // CROSS-SESSION BLACKLIST (Layer 2): Ignore rapid repeats of the same word (e.g. "Yes")
          final elapsedSinceLastEmit = DateTime.now().difference(_lastEmitTime).inMilliseconds;
          if (elapsedSinceLastEmit < 2000 && currentWords == _lastEmittedTranscript) {
            debugPrint('VoiceService [#$sessionId]: Blacklisted repeat: "$currentWords"');
            return;
          }

          _lastWords = currentWords;
          debugPrint('VoiceService [#$sessionId]: result: "$currentWords" (conf: ${result.confidence}) final: ${result.finalResult}');
          
          if (!resultEmitted && (result.finalResult || result.confidence > 0.7)) {
            resultEmitted = true;
            _lastEmittedTranscript = currentWords;
            _lastEmitTime = DateTime.now();
            
            debugPrint('VoiceService [#$sessionId]: Emitting result: "$currentWords"');
            onResult(currentWords, result.confidence);
            
            if (result.finalResult) {
              _stt.stop();
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          onDevice: false,
        ),
      );
    } catch (e) {
      debugPrint('VoiceService [#$sessionId]: Listen exception: $e');
      if (sessionId == _activeListenSessionId) {
        onListeningChanged(false);
        _isListeningForCurrentSession = false;
        if (onError != null) onError();
      }
    }

    _stt.statusListener = (status) {
      if (sessionId != _activeListenSessionId) return;
      
      if (status == 'notListening' || status == 'done') {
        onListeningChanged(false);
        _isListeningForCurrentSession = false;
        debugPrint('VoiceService [#$sessionId]: STT status finished: $status. Last words: $_lastWords');
      }
    };
  }

  Future<void> stopListening() async {
    if (_stt.isListening) {
      await _stt.stop();
      debugPrint('VoiceService: stopListening() called');
      // Wait for statusListener to catch up
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  bool get isListening => _stt.isListening;
  bool get isSpeaking => _isSpeaking;
}

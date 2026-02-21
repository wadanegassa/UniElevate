import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _isTtsInitialized = false;

  Future<void> init() async {
    await _initTts();
    await _initStt();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4); // Slower for extreme clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isTtsInitialized = true;
  }

  Future<void> _initStt() async {
    bool available = await _stt.initialize(
      onError: (error) => debugPrint('STT Error: $error'),
      onStatus: (status) => debugPrint('STT Status: $status'),
    );
    if (!available) {
      debugPrint('STT not available');
    }
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (!_isTtsInitialized) await _initTts();
    
    if (onComplete != null) {
      _tts.setCompletionHandler(() {
        onComplete();
      });
    }
    
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    _tts.setCompletionHandler(() {}); // Clear handler
    await _tts.stop();
  }

  String _lastWords = "";

  Future<void> listen({
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
    VoidCallback? onError,
  }) async {
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

    // 2. Stop if already listening (toggle behavior)
    if (_stt.isListening) {
      await _stt.stop();
      onListeningChanged(false);
      return;
    }

    // 3. Ensure STT is initialized and available
    if (!_stt.isAvailable) {
      debugPrint('VoiceService: STT not available, initializing...');
      bool initialized = await _stt.initialize(
        onError: (error) => debugPrint('VoiceService: STT Init Error: $error'),
        onStatus: (status) => debugPrint('VoiceService: STT Init Status: $status'),
      );
      if (!initialized) {
        debugPrint('VoiceService: Failed to initialize STT');
        if (onError != null) onError();
        return;
      }
    }

    // 4. Reset state for new session
    _lastWords = "";
    onListeningChanged(true);
    
    // 5. Small delay to ensure any previous audio (like TTS) has fully stopped 
    // and the mic is ready to capture clearly.
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('VoiceService: Starting listening session...');
    
    try {
      await _stt.listen(
        onResult: (result) {
          debugPrint('VoiceService: Result: "${result.recognizedWords}" (final: ${result.finalResult})');
          _lastWords = result.recognizedWords;
          
          if (result.finalResult) {
            onResult(result.recognizedWords);
            onListeningChanged(false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5), // Increased for slower speakers
        listenMode: ListenMode.dictation, // Use dictation for better continuous capture
        onSoundLevelChange: null,
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('VoiceService: Listen error: $e');
      onListeningChanged(false);
      if (onError != null) onError();
    }

    // Hook into status to handle the "done" state if no final results were caught
    _stt.statusListener = (status) {
      debugPrint('VoiceService: Status changed to $status');
      if (status == 'notListening' || status == 'done') {
        onListeningChanged(false);
        if (_lastWords.isEmpty && status == 'done') {
          debugPrint('VoiceService: Ended with no words recognized');
          if (onError != null) onError();
        } else if (_lastWords.isNotEmpty) {
          // Backup: if we have words but no "final" result was emitted
          onResult(_lastWords);
          _lastWords = "";
        }
      }
    };
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}

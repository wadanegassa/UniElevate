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
      onError: (error) => debugPrint('STT Error: $error'),
      onStatus: (status) => debugPrint('STT Status: $status'),
    );
    if (!available) {
      debugPrint('STT not available');
    }
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (!_isTtsInitialized) await _initTts();
    
    // Stop any existing session
    await stopSpeaking();
    await stopListening();

    // Instead of manual splitting (which causes stuttering/interruptions),
    // we use a single speak command but replace "..." with punctuation 
    // that naturally results in pauses in most TTS engines.
    final processedText = text.replaceAll("...", "... ");

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (onComplete != null) onComplete();
    });

    _isSpeaking = true;
    await _tts.speak(processedText);
  }

  Future<void> stopSpeaking() async {
    _tts.setCompletionHandler(() {}); 
    await _tts.stop();
    _isSpeaking = false;
  }

  String _lastWords = "";

  Future<void> listen({
    required Function(String) onResult,
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
      await _stt.stop();
      onListeningChanged(false);
      return;
    }

    // 3. Ensure STT is initialized
    if (!_stt.isAvailable) {
      await _initStt();
      if (!_stt.isAvailable) {
        if (onError != null) onError();
        return;
      }
    }

    // 4. Reset state
    _lastWords = "";
    
    // 5. SMARTER SEQUENCING: Mandatory Guard Delay
    // Increas to 1 second to ensure complete silence on all hardware
    await Future.delayed(const Duration(milliseconds: 1000));

    debugPrint('VoiceService: Starting listening session (Earphone/Bluetooth ready)...');
    onListeningChanged(true);

    try {
      await _stt.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult || result.confidence > 0.8) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
          onDevice: false, // Set to false to prevent error_language_unavailable if model is missing
        ),
      );
    } catch (e) {
      debugPrint('VoiceService: Listen error: $e');
      onListeningChanged(false);
      if (onError != null) onError();
    }

    _stt.statusListener = (status) {
      if (status == 'notListening' || status == 'done') {
        onListeningChanged(false);
        debugPrint('VoiceService: STT status finished: $status. Last words: $_lastWords');
      }
    };
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
  bool get isSpeaking => _isSpeaking;
}

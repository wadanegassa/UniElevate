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
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isTtsInitialized = true;
  }

  Future<void> _initStt() async {
    bool available = await _stt.initialize(
      onError: (error) => print('STT Error: $error'),
      onStatus: (status) => print('STT Status: $status'),
    );
    if (!available) {
      print('STT not available');
    }
  }

  Future<void> speak(String text) async {
    if (!_isTtsInitialized) await _initTts();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> listen({
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
  }) async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    if (_stt.isListening) {
      await _stt.stop();
      onListeningChanged(false);
      return;
    }

    bool available = await _stt.initialize();
    if (available) {
      onListeningChanged(true);
      _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            onListeningChanged(false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}

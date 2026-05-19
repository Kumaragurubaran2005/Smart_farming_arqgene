import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceAssistantService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      bool speechAvailable = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );
      
      if (speechAvailable) {
        _isInitialized = true;
      }
    }
  }

  Future<void> speak(String text, String languageCode) async {
    await _tts.setLanguage(languageCode);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> listen({
    required Function(String) onResult,
    required String languageCode,
  }) async {
    await init();
    if (_isInitialized) {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: languageCode,
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
      );
    }
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

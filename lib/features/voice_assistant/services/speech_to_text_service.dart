import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechToTextService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (errorNotification) => print('Speech error: $errorNotification'),
      );
    }
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required String languageCode,
  }) async {
    bool available = await initialize();
    if (available) {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        localeId: languageCode,
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
        partialResults: false,
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}

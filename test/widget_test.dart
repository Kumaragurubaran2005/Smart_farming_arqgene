import 'package:flutter_test/flutter_test.dart';
import 'package:arqgene_farmer_app/features/listing/presentation/providers/listing_form_provider.dart';
import 'package:arqgene_farmer_app/core/services/open_router_service.dart';
import 'package:arqgene_farmer_app/features/voice_assistant/services/groq_whisper_service.dart';
import 'package:arqgene_farmer_app/features/voice_assistant/services/voice_recorder_service.dart';

class FakeOpenRouterService extends OpenRouterService {
  @override
  Future<Map<String, dynamic>?> extractEntitiesFromText(String transcription) async {
    return {
      'crop_name': 'Tomato',
      'quantity': '50',
      'unit': 'kg',
      'price': '30',
      'location': 'Chennai',
      'additional_notes': 'Fresh crop'
    };
  }
}

class FakeGroqWhisperService extends GroqWhisperService {
  @override
  Future<String?> processAudio(String filePath) async {
    return 'தக்காளி 50 கிலோ 30 ரூபாய் சென்னை';
  }
}

class FakeVoiceRecorderService extends VoiceRecorderService {
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> startRecording() async {}
  @override
  Future<String?> stopRecording() async => 'dummy_path.wav';
}

void main() {
  group('ListingFormProvider Unit Tests', () {
    late ListingFormProvider provider;
    late FakeOpenRouterService fakeOpenRouter;
    late FakeGroqWhisperService fakeGroqWhisper;
    late FakeVoiceRecorderService fakeRecorder;

    setUp(() {
      fakeOpenRouter = FakeOpenRouterService();
      fakeGroqWhisper = FakeGroqWhisperService();
      fakeRecorder = FakeVoiceRecorderService();
      provider = ListingFormProvider(
        openRouterService: fakeOpenRouter,
        groqWhisperService: fakeGroqWhisper,
        recorderService: fakeRecorder,
      );
    });

    test('Initial values are empty', () {
      expect(provider.transcriptionPreview, isEmpty);
      expect(provider.productController.text, isEmpty);
    });

    test('updateTranscriptionPreview updates preview state', () {
      provider.updateTranscriptionPreview('Test transcription');
      expect(provider.transcriptionPreview, 'Test transcription');
    });

    test('extractAndAutofill correctly maps entities to form controllers', () async {
      provider.updateTranscriptionPreview('தக்காளி 50 கிலோ 30 ரூபாய் சென்னை');
      await provider.extractAndAutofill();

      expect(provider.productController.text, 'Tomato');
      expect(provider.quantityController.text, '50');
      expect(provider.unitController.text, 'kg');
      expect(provider.priceController.text, '30');
      expect(provider.addressController.text, 'Chennai');
      expect(provider.descriptionController.text, 'Fresh crop');
      expect(provider.transcriptionPreview, isEmpty); // Clears preview on success
    });
  });
}

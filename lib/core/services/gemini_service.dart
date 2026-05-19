import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyCnNpLV2TKtrJoDHkz-5_kBvGxLmzp3rcw';

  Future<String?> generateDescription(String imagePath) async {
    try {
      final model = GenerativeModel(
        model: 'models/gemini-1.5-flash',
        apiKey: _apiKey,
      );
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart(
        "You are an agricultural expert helper. Look at this crop image. "
        "Write a short, attractive, and honest description (max 2 sentences) for a farmer to sell it. "
        "Focus on freshness, quality, and variety if identifiable. "
        "Do not include any intro text like 'Here is a description', just the description itself.",
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      return response.text;
    } catch (e) {
      print("Gemini Error: $e");
      return null;
    }
  }
}

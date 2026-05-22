import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqWhisperService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _endpoint = 'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _model = 'whisper-large-v3-turbo';

  Future<String?> processAudio(String filePath) async {
    try {
      debugPrint("====== DEBUG GROQ WHISPER ======");
      debugPrint("🌐 Uploading audio to Groq API...");
      debugPrint("Endpoint: $_endpoint");
      debugPrint("Model: $_model");
      debugPrint("Uploading File: $filePath");
      
      var request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
      });
      
      request.fields.addAll({
        "model": "whisper-large-v3-turbo",
        "response_format": "verbose_json"
      });
      
      final sanitizedHeaders = Map<String, String>.from(request.headers)..remove('Authorization');
      debugPrint("Headers: $sanitizedHeaders");
      debugPrint("Fields: ${request.fields}");
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      debugPrint("🚀 Sending Groq API request...");
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      debugPrint("📥 Groq API response received.");
      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Raw Whisper Response: $responseData");
      debugPrint("================================");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        final transcribedText = data['text'];
        final detectedLanguage = data['language'];
        
        debugPrint("🔍 Detected Transcription: $transcribedText");
        debugPrint("🔍 Detected Language: ${detectedLanguage ?? 'N/A'}");
        
        if (transcribedText == null || transcribedText.toString().trim().isEmpty) {
            debugPrint("⚠️ WARNING: Groq returned 200 but transcript is empty!");
        }
        return transcribedText;
      } else {
        debugPrint("❌ Groq API Error: ${response.statusCode} - $responseData");
        throw Exception("Groq API Error: ${response.statusCode} - $responseData");
      }
    } catch (e) {
      debugPrint("❌ Exception calling Groq: $e");
      throw Exception("Voice Processing failed: $e");
    }
  }
}

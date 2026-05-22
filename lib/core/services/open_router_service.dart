import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  static const String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openai/gpt-oss-120b';
  static final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// Extracts crop details from transcribed speech using OpenRouter.
  Future<Map<String, dynamic>?> extractEntitiesFromText(String transcription) async {
    // COMMENTS: Where request starts
    print("OpenRouter request started");
    print("Endpoint: $_endpoint");
    print("Model: $_model");
    print("User Prompt: $transcription");

    try {
      final Map<String, dynamic> body = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': '''You are an AI assistant for a farmer marketplace app.

The user may speak in Tamil, Telugu, Hindi, or English.

Your task:

1. Understand the farmer speech.
2. Translate crop names into English.
3. Extract structured data.
4. Return ONLY valid JSON.

Use EXACTLY this format:

{
"crop_name": "",
"quantity": "",
"unit": "",
"price": "",
"location": "",
"additional_notes": ""
}

Rules:

* Convert crop names to English.
* Convert spoken numbers into numeric values.
* Do not include explanations.
* Do not include markdown.
* Do not include reasoning.
* Output ONLY JSON.'''
          },
          {
            'role': 'user',
            'content': transcription,
          }
        ]
      };

      print("Request Body: ${jsonEncode(body)}");
      
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      // COMMENTS: Where response comes
      print("Status Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final message = responseData['choices'][0]['message'];
        
        String rawText = message['content'] ?? message['reasoning'] ?? '';
        
        if (rawText.isEmpty) {
          throw Exception("Empty AI response");
        }
        
        final jsonStart = rawText.indexOf('{');
        final jsonEnd = rawText.lastIndexOf('}');
        
        if (jsonStart == -1 || jsonEnd == -1) {
          throw Exception("No JSON found");
        }
        
        final cleanJson = rawText.substring(jsonStart, jsonEnd + 1);
        print("Extracted JSON Content: $cleanJson");
        
        final data = jsonDecode(cleanJson) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // COMMENTS: Where error occurs (Authentication Failure)
        print("OpenRouter Error: Authentication Failure - Invalid API Key or Unauthorized");
        throw Exception("Authentication Failure: Invalid API Key or Unauthorized");
      } else {
        // COMMENTS: Where error occurs (API Request Failure)
        print("OpenRouter Error: API Request Failure (Status ${response.statusCode})");
        throw Exception("API Request Failure: Status ${response.statusCode} - ${response.body}");
      }
    } catch (e, stackTrace) {
      // COMMENTS: Where error occurs (General request or network failure)
      print("OpenRouter Error: $e");
      print(stackTrace); // Prints full stack trace
      rethrow;
    }
  }

  /// Classifies user speech into standard system intents.
  Future<Map<String, dynamic>?> classifyIntent(String transcribedText) async {
    print("OpenRouter request started");
    print("Endpoint: $_endpoint");
    print("Model: $_model");
    print("User Prompt: $transcribedText");

    try {
      final Map<String, dynamic> body = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': "You are an intelligent assistant for a farmer's marketplace app. "
                "Analyze the user voice transcription and classify the intent into one of the following exact string values: "
                "'create_listing', 'open_profile', 'change_language', 'logout', or 'unknown'. "
                "Respond ONLY in valid JSON format: {\"intent\": \"value\"}. Do not explain anything."
          },
          {
            'role': 'user',
            'content': transcribedText,
          }
        ]
      };

      print("Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print("Status Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic>? choices = responseData['choices'];
        if (choices != null && choices.isNotEmpty) {
          final String? content = choices[0]['message']?['content'];
          if (content == null || content.isEmpty) {
            print("OpenRouter Error: Response Parsing Failure - message content is empty.");
            throw Exception("Empty AI response");
          }
          return _parseJson(content);
        }
        print("OpenRouter Error: Response Parsing Failure - choices or message content not found.");
        throw Exception("Response Parsing Failure: choices or message content not found.");
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print("OpenRouter Error: Authentication Failure - Invalid API Key or Unauthorized");
        throw Exception("Authentication Failure: Invalid API Key or Unauthorized");
      } else {
        print("OpenRouter Error: API Request Failure (Status ${response.statusCode})");
        throw Exception("API Request Failure: Status ${response.statusCode} - ${response.body}");
      }
    } catch (e, stackTrace) {
      print("OpenRouter Error: $e");
      print(stackTrace);
      rethrow;
    }
  }

  /// Generates a product description and price suggestion from a crop image.
  Future<Map<String, dynamic>?> generateDescription(String imagePath) async {
    const String visionModel = 'openai/gpt-4o-mini';
    print("OpenRouter request started");
    print("Endpoint: $_endpoint");
    print("Model: $visionModel");
    print("User Prompt: [Image data sent as base64]");

    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception("Image file does not exist at path: $imagePath");
      }
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final Map<String, dynamic> body = {
        'model': visionModel,
        'messages': [
          {
            'role': 'system',
            'content': "You are an agricultural expert helper. Look at the crop image.\n\n"
                "Extract the details and return them STRICTLY in this JSON format:\n"
                "{\n"
                "  \"product_name\": \"\",\n"
                "  \"description\": \"\",\n"
                "  \"price\": \"\"\n"
                "}\n\n"
                "For description, write a short, attractive, and honest description (max 2 sentences) for a farmer to sell it.\n"
                "For price, estimate a reasonable market price per kg in rupees (just the number).\n"
                "If a value is unknown, leave it empty.\n\n"
                "Return ONLY valid JSON. Do not include markdown code blocks, reasoning, or explanations."
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                }
              }
            ]
          }
        ]
      };

      // Create a sanitized body for logging to avoid printing huge base64 payload which causes frame skips
      final Map<String, dynamic> bodyForLog = {
        'model': visionModel,
        'messages': [
          body['messages'][0],
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,[Omitted for size]',
                }
              }
            ]
          }
        ]
      };
      print("Request Body: ${jsonEncode(bodyForLog)}");

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      print("Status Code: ${response.statusCode}");
      print("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic>? choices = responseData['choices'];
        if (choices != null && choices.isNotEmpty) {
          final String? content = choices[0]['message']?['content'];
          if (content == null || content.isEmpty) {
            print("OpenRouter Error: Response Parsing Failure - message content is empty.");
            throw Exception("Empty AI response");
          }
          return _parseJson(content);
        }
        print("OpenRouter Error: Response Parsing Failure - choices or message content not found.");
        throw Exception("Response Parsing Failure: choices or message content not found.");
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print("OpenRouter Error: Authentication Failure - Invalid API Key or Unauthorized");
        throw Exception("Authentication Failure: Invalid API Key or Unauthorized");
      } else {
        print("OpenRouter Error: API Request Failure (Status ${response.statusCode})");
        throw Exception("API Request Failure: Status ${response.statusCode} - ${response.body}");
      }
    } catch (e, stackTrace) {
      print("OpenRouter Error: $e");
      print(stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic>? _parseJson(String text) {
    try {
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd < jsonStart) {
        throw Exception("No valid JSON block found in response");
      }
      final cleanJson = text.substring(jsonStart, jsonEnd + 1);
      final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
      // Decodes JSON successfully
      return parsed;
    } catch (e) {
      // COMMENTS: Where error occurs (JSON Decoding Failure)
      print("JSON Parse Error: $e");
      print("OpenRouter Error: JSON Decoding Failure");
      return null;
    }
  }
}

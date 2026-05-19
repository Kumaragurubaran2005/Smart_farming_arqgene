import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/bhasini_config.dart';

class BhasiniApiService {
  Future<String?> processAudio(String filePath, String sourceLang) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final String base64Audio = base64Encode(bytes);

      // Construct Payload
      final Map<String, dynamic> payload = {
        "pipelineTasks": [
          {
            "taskType": BhasiniConfig.asrTaskType,
            "config": {
              "language": {
                "sourceLanguage": sourceLang
              },
              // NOTE: ServiceId might need to be specific if pipelineId isn't used automatically
              // But 'pipeline' endpoint usually figures out service based on input or uses default
              // If we have a pipeline ID we often put it in headers or URL. 
              // The Meity API style requires specific structure.
            }
          },
          {
            "taskType": BhasiniConfig.translationTaskType,
            "config": {
              "language": {
                "sourceLanguage": sourceLang,
                "targetLanguage": "en"
              }
            }
          }
        ],
        "inputData": {
          "audio": [
            {
              "audioContent": base64Audio
            }
          ]
        }
      };

      final response = await http.post(
        Uri.parse(BhasiniConfig.inferenceUrl),
        headers: {
          "Content-Type": "application/json",
          "userID": BhasiniConfig.userId,
          "ulcaApiKey": BhasiniConfig.ulcaApiKey,
          "Authorization": BhasiniConfig.ulcaApiKey, // sometimes used here
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Parse response to find translated text
        // Structure varies, usually: pipelineResponse -> [tasks] -> output
        // We look for the Translation output (final English text)
        
        final tasks = data['pipelineResponse'] as List;
        // Find translation task
        final translationTask = tasks.firstWhere(
          (t) => t['taskType'] == 'translation',
          orElse: () => null,
        );

        if (translationTask != null) {
            final output = translationTask['output'] as List;
            if (output.isNotEmpty) {
                return output[0]['target'];
            }
        }
        
        // Fallback to ASR output if no translation
        final asrTask = tasks.firstWhere(
            (t) => t['taskType'] == 'asr',
            orElse: () => null,
        );
        
        if (asrTask != null) {
            final output = asrTask['output'] as List;
            if (output.isNotEmpty) {
                return output[0]['source'];
            }
        }
      } else {
        print("Bhasini API Error: ${response.body}");
      }
    } catch (e) {
      print("Exception calling Bhasini: $e");
    }
    return null;
  }
}

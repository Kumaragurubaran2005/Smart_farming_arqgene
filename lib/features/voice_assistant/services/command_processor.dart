import 'package:flutter/foundation.dart';
import '../../../core/services/open_router_service.dart';
import '../../../../injection_container.dart';

enum VoiceAction {
  sellByPhoto,
  sellByVideo,
  openProfile,
  openSettings,
  changeLanguage,
  logout,
  unknown
}

class CommandResponse {
  final VoiceAction action;
  final String feedback;

  CommandResponse({required this.action, required this.feedback});
}

class CommandProcessor {
  final OpenRouterService _openRouterService = sl<OpenRouterService>();

  Future<CommandResponse> process(String text, String lang) async {
    final t = text.toLowerCase();
    
    // Default Unknown
    String msg = "Sorry, I didn't catch that.";
    VoiceAction action = VoiceAction.unknown;

    try {
      final result = await _openRouterService.classifyIntent(text);
      if (result != null && result['intent'] != null) {
        final intent = result['intent'];
        debugPrint("🎯 CommandProcessor: Intent identified as '$intent'");
        
        switch (intent) {
          case 'create_listing':
            msg = "Okay, let's take a photo to sell your crop.";
            action = VoiceAction.sellByPhoto;
            break;
          case 'open_profile':
            msg = "Opening your profile.";
            action = VoiceAction.openProfile;
            break;
          case 'change_language':
            msg = "Let's change the language.";
            action = VoiceAction.openSettings;
            break;
          case 'logout':
            msg = "Goodbye!";
            action = VoiceAction.logout;
            break;
          default:
            msg = "Sorry, I didn't catch that.";
            action = VoiceAction.unknown;
            debugPrint("⚠️ CommandProcessor: Intent was '$intent' which is treated as unknown.");
        }
      } else {
        debugPrint("❌ CommandProcessor: Intent result was null or empty.");
      }
    } catch (e) {
      debugPrint("❌ Command Processor Error: $e");
    }

    debugPrint("✅ CommandProcessor: Returning action $action with feedback '$msg'");
    return CommandResponse(action: action, feedback: msg);
  }
}

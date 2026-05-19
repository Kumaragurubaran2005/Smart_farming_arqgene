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
  CommandResponse process(String text, String lang) {
    final t = text.toLowerCase();
    
    // Sell Logic
    if (t.contains('sell') || t.contains('upload') || t.contains('becho') || t.contains('virka')) {
        String msg = lang == 'hi' ? "ठीक है, फोटो खींचिए" : (lang == 'ta' ? "சரி, புகைப்படம் எடுங்கள்" : "Okay, let's take a photo.");
        if (t.contains('video')) {
            msg = lang == 'hi' ? "ठीक है, वीडियो रिकॉर्ड कीजिए" : (lang == 'ta' ? "சரி, வீடியோ எடுங்கள்" : "Okay, let's record a video.");
            return CommandResponse(action: VoiceAction.sellByVideo, feedback: msg);
        }
        return CommandResponse(action: VoiceAction.sellByPhoto, feedback: msg);
    }
    
    // Profile Logic
    if (t.contains('profile') || t.contains('account') || t.contains('khata') || t.contains('kanakku')) {
        String msg = lang == 'hi' ? "आपका प्रोफाइल खोल रहा हूँ" : (lang == 'ta' ? "உங்கள் சுயவிவரத்தைத் திறக்கிறேன்" : "Opening your profile.");
        return CommandResponse(action: VoiceAction.openProfile, feedback: msg);
    }
    
    // Settings Logic
    if (t.contains('setting') || t.contains('language') || t.contains('bhasha') || t.contains('mozhi')) {
        String msg = lang == 'hi' ? "भाषा बदलें" : (lang == 'ta' ? "மொழியை மாற்றவும்" : "Let's change the language.");
        return CommandResponse(action: VoiceAction.openSettings, feedback: msg);
    }

    // Logout Logic
    if (t.contains('logout') || t.contains('sign out') || t.contains('bahar') || t.contains('veliyeru')) {
        String msg = lang == 'hi' ? "अलविदा" : (lang == 'ta' ? "மீண்டும் சந்திப்போம்" : "Goodbye!");
        return CommandResponse(action: VoiceAction.logout, feedback: msg);
    }

    String unknownMsg = lang == 'hi' ? "माफ कीजिये, समझ नहीं आया" : (lang == 'ta' ? "மன்னிக்கவும், புரியவில்லை" : "Sorry, I didn't catch that.");
    return CommandResponse(action: VoiceAction.unknown, feedback: unknownMsg);
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesHelper {
  static const String _keySavedListings = 'saved_listings';
  static const String _keyRecentlyViewed = 'recently_viewed';
  static const String _keyNotifications = 'notifications';

  // --- Saved Listings (Favorites) ---
  static Future<List<String>> getSavedListings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySavedListings) ?? [];
  }

  static Future<void> toggleSavedListing(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySavedListings) ?? [];
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(_keySavedListings, list);
  }

  static Future<bool> isListingSaved(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySavedListings) ?? [];
    return list.contains(id);
  }

  // --- Recently Viewed ---
  static Future<List<String>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyRecentlyViewed) ?? [];
  }

  static Future<void> addRecentlyViewed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyRecentlyViewed) ?? [];
    // Remove if already exists (to move it to top)
    list.remove(id);
    list.insert(0, id);
    // Limit to 10 items
    if (list.length > 10) {
      list.removeLast();
    }
    await prefs.setStringList(_keyRecentlyViewed, list);
  }

  // --- In-App Notifications ---
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyNotifications) ?? [];
    
    // Add default notifications if empty (so it feels like a real production app immediately)
    if (data.isEmpty) {
      final defaultNotifs = [
        {
          'id': 'welcome',
          'title': 'Welcome to Dr. Pasumai!',
          'body': 'Explore fresh organic products directly from local farmers.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'isRead': false,
        },
        {
          'id': 'how_to_buy',
          'title': 'Quick Buying Tip',
          'body': 'Tap on any crop to view seller details, call them directly, or chat via WhatsApp!',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'isRead': true,
        }
      ];
      final encoded = defaultNotifs.map((n) => jsonEncode(n)).toList();
      await prefs.setStringList(_keyNotifications, encoded);
      return defaultNotifs;
    }

    try {
      return data.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addNotification(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyNotifications) ?? [];
    
    final newNotif = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    
    data.insert(0, jsonEncode(newNotif));
    
    // Limit to 50 notifications
    if (data.length > 50) {
      data.removeLast();
    }
    await prefs.setStringList(_keyNotifications, data);
  }

  static Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyNotifications) ?? [];
    final List<String> updated = [];
    
    for (var item in data) {
      try {
        final Map<String, dynamic> notif = jsonDecode(item);
        notif['isRead'] = true;
        updated.add(jsonEncode(notif));
      } catch (e) {
        updated.add(item);
      }
    }
    await prefs.setStringList(_keyNotifications, updated);
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotifications);
  }
}

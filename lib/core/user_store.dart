// lib/core/user_store.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserStore {
  static const _kName = 'user_name_v1';
  static const _kEmail = 'user_email_v1';
  static const _kAvatar = 'user_avatar_path_v1';

  // Save or update the user's display name and email.
  static Future<void> saveProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name);
    await prefs.setString(_kEmail, email);
  }

  // Save (or clear) the avatar file path stored locally.
  static Future<void> saveAvatarPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_kAvatar);
    } else {
      await prefs.setString(_kAvatar, path);
    }
  }

  // Getters
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAvatar);
  }

  // Clear all stored user fields (useful on logout if desired).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kAvatar);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  static const _key = 'is_logged_in_v1';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
    // If you later store tokens, check token existence/expiry instead
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  // If you later add user profile or token:
  // static Future<void> saveToken(String token) ...
  // static Future<String?> getToken() ...
  // static Future<void> clear() ...
}

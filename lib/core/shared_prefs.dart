import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class LocalStorage {
  static const String keyToken = "AUTH_TOKEN";
  static const String keyDarkMode = "DARK_MODE";

  static Future<void> saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(Constants.keyToken, token);
  }

  static Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(Constants.keyToken);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  }

  // DARK MODE
  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(keyDarkMode, isDark);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyDarkMode) ?? false;
  }
}

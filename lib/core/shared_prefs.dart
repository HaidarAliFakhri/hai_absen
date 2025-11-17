import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class LocalStorage {
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
}

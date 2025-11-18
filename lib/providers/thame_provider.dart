import 'package:flutter/material.dart';

import '../core/shared_prefs.dart';

class ThemeProvider with ChangeNotifier {
  bool isDark = false;

  ThemeProvider() {
    loadTheme();
  }

  void loadTheme() async {
    isDark = await LocalStorage.getDarkMode();
    notifyListeners();
  }

  void toggleTheme() async {
    isDark = !isDark;
    await LocalStorage.setDarkMode(isDark);
    notifyListeners();
  }
}

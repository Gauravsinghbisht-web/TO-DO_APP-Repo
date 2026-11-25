
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  // Load previously saved theme.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');

    switch (savedTheme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      case 'system':
        _themeMode = ThemeMode.system;
        break;

      case 'light':
      default:
        _themeMode = ThemeMode.light;
        break;
    }

    notifyListeners();
  }

  // Change and save theme.
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    final themeName = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await prefs.setString('theme_mode', themeName);
  }
}

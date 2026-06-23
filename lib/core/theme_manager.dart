import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);
  static const String _themeKey = 'is_dark_theme';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? true; // Default to dark mode
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('ThemeManager initialization failed: $e');
    }
  }

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static Future<void> toggleTheme(bool isDark) async {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      debugPrint('ThemeManager save failed: $e');
    }
  }
}

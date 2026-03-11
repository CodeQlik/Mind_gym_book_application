import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'isDarkMode';
  static final ThemeService instance = ThemeService._internal();

  ThemeService._internal();

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Initialize the theme from local storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);

    if (isDark == null) {
      themeMode.value = ThemeMode.system;
    } else {
      themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    debugPrint("Theme initialized: ${themeMode.value}");
  }

  /// Toggle the theme and persist it
  Future<void> toggleTheme(bool isDark) async {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
    debugPrint("Theme changed to: ${themeMode.value}");
  }

  /// Reset to system theme
  Future<void> setSystemTheme() async {
    themeMode.value = ThemeMode.system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}

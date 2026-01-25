// Файл: lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // ValueNotifier, чтобы интерфейс знал, когда перерисоваться
  static ValueNotifier<bool> isDarkMode = ValueNotifier(false);

  // Загружаем сохраненную настройку при запуске
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // По умолчанию false (светлая тема)
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
  }

  // Сохраняем и обновляем тему
  static Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    isDarkMode.value = isDark;
  }
}
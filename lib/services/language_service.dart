import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  // Текущий язык (по умолчанию русский)
  static ValueNotifier<String> currentLanguage = ValueNotifier('ru');

  // Загрузка сохраненного языка
  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguage.value = prefs.getString('language_code') ?? 'ru';
  }

  // Смена языка
  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    currentLanguage.value = code;
  }

  // Получение перевода по ключу
  static String tr(String key) {
    final lang = currentLanguage.value;
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key]![lang] ?? key;
    }
    return key;
  }

  // СЛОВАРЬ (Здесь добавляй новые фразы)
  static final Map<String, Map<String, String>> _localizedValues = {
    // --- ОБЩЕЕ ---
    'app_title': {
      'ru': 'Smart Recipe Generator',
      'kk': 'Ақылды Рецепттер',
      'en': 'Smart Recipe Generator',
    },
    'settings': {
      'ru': 'Настройки',
      'kk': 'Баптаулар',
      'en': 'Settings',
    },
    'language': {
      'ru': 'Язык',
      'kk': 'Тіл',
      'en': 'Language',
    },

    // --- ГЛАВНЫЙ ЭКРАН ---
    'hello': {
      'ru': 'Привет',
      'kk': 'Сәлем',
      'en': 'Hello',
    },
    'chef': {
      'ru': 'Шеф',
      'kk': 'Шеф',
      'en': 'Chef',
    },
    'what_in_fridge': {
      'ru': 'Что в холодильнике?',
      'kk': 'Тоңазытқышта не бар?',
      'en': 'What\'s in the fridge?',
    },
    'scan_hint': {
      'ru': 'Сделай фото продуктов или введи список вручную',
      'kk': 'Өнімдерді суретке түсіріңіз немесе тізімді жазыңыз',
      'en': 'Take a photo of items or enter a list manually',
    },
    'scan_button': {
      'ru': 'Сканировать',
      'kk': 'Сканерлеу',
      'en': 'Scan',
    },

    // --- МЕНЮ СКАНИРОВАНИЯ ---
    'manual_input': {
      'ru': 'Ввести вручную',
      'kk': 'Қолмен енгізу',
      'en': 'Enter manually',
    },
    'gallery': {
      'ru': 'Галерея',
      'kk': 'Галерея',
      'en': 'Gallery',
    },
    'camera': {
      'ru': 'Камера',
      'kk': 'Камера',
      'en': 'Camera',
    },

    // --- ЭКРАН РЕЗУЛЬТАТОВ (SCAN SCREEN) ---
    'results_title': {
      'ru': 'Результат',
      'kk': 'Нәтиже',
      'en': 'Results',
    },
    'chef_thinking': {
      'ru': 'Шеф думает...',
      'kk': 'Шеф ойланып жатыр...',
      'en': 'Chef is thinking...',
    },
    'products_label': {
      'ru': 'Продукты:',
      'kk': 'Өнімдер:',
      'en': 'Ingredients:',
    },
    'edit': {
      'ru': 'Изменить',
      'kk': 'Өзгерту',
      'en': 'Edit',
    },
    'update': {
      'ru': 'Обновить',
      'kk': 'Жаңарту',
      'en': 'Update',
    },

    // --- РЕЦЕПТ ---
    'ingredients': {
      'ru': 'Ингредиенты',
      'kk': 'Құрамы',
      'en': 'Ingredients',
    },
    'steps': {
      'ru': 'Инструкция',
      'kk': 'Нұсқаулық',
      'en': 'Instructions',
    },
    'video_recipe': {
      'ru': 'Смотреть видео-рецепт',
      'kk': 'Бейне-рецептті көру',
      'en': 'Watch video recipe',
    },

    // --- ПРОМПТЫ ДЛЯ GEMINI (Скрытые) ---
    'prompt_lang': {
      'ru': 'Отвечай на РУССКОМ языке.',
      'kk': 'ҚАЗАҚ тілінде жауап бер.',
      'en': 'Answer in ENGLISH.',
    }
  };
}
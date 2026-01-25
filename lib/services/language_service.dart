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

  // --- ПОЛНЫЙ СЛОВАРЬ ПЕРЕВОДОВ ---
  static final Map<String, Map<String, String>> _localizedValues = {
    // === ОБЩЕЕ ===
    'app_title': {
      'ru': 'Smart Recipe Generator',
      'kk': 'Ақылды Рецепттер',
      'en': 'Smart Recipe Generator',
    },
    'settings': {'ru': 'Настройки', 'kk': 'Баптаулар', 'en': 'Settings'},
    'language': {'ru': 'Язык', 'kk': 'Тіл', 'en': 'Language'},
    'cancel': {'ru': 'Отмена', 'kk': 'Болдырмау', 'en': 'Cancel'},
    'save': {'ru': 'Сохранить', 'kk': 'Сақтау', 'en': 'Save'},
    'search': {'ru': 'Искать', 'kk': 'Іздеу', 'en': 'Search'},

    // === ЭКРАН ВХОДА (LOGIN) ===
    'login_subtitle': {
      'ru': 'Войдите, чтобы сохранять рецепты',
      'kk': 'Рецепттерді сақтау үшін кіріңіз',
      'en': 'Log in to save recipes',
    },
    'login_google': {
      'ru': 'Войти через Google',
      'kk': 'Google арқылы кіру',
      'en': 'Sign in with Google',
    },
    'login_phone': {
      'ru': 'Войти по номеру телефона',
      'kk': 'Телефон нөмірі арқылы кіру',
      'en': 'Sign in with Phone',
    },

    // === ГЛАВНЫЙ ЭКРАН (HOME) ===
    'hello': {'ru': 'Привет', 'kk': 'Сәлем', 'en': 'Hello'},
    'chef': {'ru': 'Шеф', 'kk': 'Шеф', 'en': 'Chef'},
    'what_in_fridge': {
      'ru': 'Что в холодильнике?',
      'kk': 'Тоңазытқышта не бар?',
      'en': 'What\'s in the fridge?',
    },
    'scan_hint': {
      'ru': 'Сделай фото или введи список вручную',
      'kk': 'Суретке түсіріңіз немесе тізімді жазыңыз',
      'en': 'Take a photo or enter a list',
    },
    'scan_button': {'ru': 'Сканировать', 'kk': 'Сканерлеу', 'en': 'Scan'},
    'manual_input': {'ru': 'Ввести вручную', 'kk': 'Қолмен енгізу', 'en': 'Enter manually'},
    'gallery': {'ru': 'Галерея', 'kk': 'Галерея', 'en': 'Gallery'},
    'camera': {'ru': 'Камера', 'kk': 'Камера', 'en': 'Camera'},
    'manual_dialog_title': {
      'ru': 'Какие продукты?',
      'kk': 'Қандай өнімдер бар?',
      'en': 'What ingredients?'
    },
    'manual_hint': {
      'ru': 'Например: курица, рис...',
      'kk': 'Мысалы: тауық, күріш...',
      'en': 'E.g., chicken, rice...'
    },

    // === НАСТРОЙКИ (SETTINGS) ===
    'account': {'ru': 'Аккаунт', 'kk': 'Аккаунт', 'en': 'Account'},
    'change_name': {'ru': 'Изменить имя', 'kk': 'Атын өзгерту', 'en': 'Change name'},
    'change_name_hint': {
      'ru': 'Настройте, как к вам обращаться',
      'kk': 'Сізге қалай хабарласу керектігін реттеңіз',
      'en': 'Set how to address you',
    },
    'food_restrictions': {
      'ru': 'Пищевые ограничения',
      'kk': 'Тағамдық шектеулер',
      'en': 'Dietary restrictions',
    },
    'gluten_free': {'ru': 'Без Глютена', 'kk': 'Глютенсіз', 'en': 'Gluten Free'},
    'lactose_free': {'ru': 'Без Лактозы', 'kk': 'Лактозасыз', 'en': 'Lactose Free'},
    'nut_allergy': {'ru': 'Аллергия на Орехи', 'kk': 'Жаңғаққа аллергия', 'en': 'Nut Allergy'},

    // === ПРОФИЛЬ (PROFILE) ===
    'edit_profile': {'ru': 'Редактировать профиль', 'kk': 'Профильді өңдеу', 'en': 'Edit Profile'},
    'your_name': {'ru': 'Ваше имя', 'kk': 'Сіздің атыңыз', 'en': 'Your name'},
    'name_saved': {'ru': 'Имя сохранено!', 'kk': 'Аты сақталды!', 'en': 'Name saved!'},

    // === СКАНЕР И РЕЗУЛЬТАТЫ ===
    'results_title': {'ru': 'Результат', 'kk': 'Нәтиже', 'en': 'Results'},
    'products_label': {'ru': 'Продукты:', 'kk': 'Өнімдер:', 'en': 'Ingredients:'},
    'edit': {'ru': 'Изменить', 'kk': 'Өзгерту', 'en': 'Edit'},
    'chef_thinking': {'ru': 'Шеф думает...', 'kk': 'Шеф ойланып жатыр...', 'en': 'Chef is thinking...'},
    'retry': {'ru': 'Повторить', 'kk': 'Қайталау', 'en': 'Retry'},
    'dialog_add_edit': {'ru': 'Добавить/Изменить', 'kk': 'Қосу/Өзгерту', 'en': 'Add/Edit'},
    'dialog_hint': {
      'ru': 'Что добавить? (Например: "плюс яйца")',
      'kk': 'Не қосу керек? (Мысалы: "жұмыртқа")',
      'en': 'What to add? (e.g. "plus eggs")'
    },
    'update_recipes': {'ru': 'Обновить рецепты', 'kk': 'Рецепттерді жаңарту', 'en': 'Update recipes'},

    // === ДЕТАЛИ РЕЦЕПТА ===
    'ingredients_title': {'ru': 'Ингредиенты:', 'kk': 'Құрамы:', 'en': 'Ingredients:'},
    'steps_title': {'ru': 'Инструкция:', 'kk': 'Дайындалуы:', 'en': 'Instructions:'},
    'video_recipe': {'ru': 'Смотреть видео-рецепт', 'kk': 'Бейне-рецептті көру', 'en': 'Watch video recipe'},
    'recipe_default': {'ru': 'Рецепт', 'kk': 'Рецепт', 'en': 'Recipe'},

    // === ИЗБРАННОЕ (FAVORITES) ===
    'my_recipes': {
      'ru': 'Мои рецепты',
      'kk': 'Менің рецепттерім',
      'en': 'My Recipes',
    },
    'no_favorites': {
      'ru': 'Пока нет любимых рецептов',
      'kk': 'Әзірге сүйікті рецепттер жоқ',
      'en': 'No favorite recipes yet',
    },

    // === ПРОМПТЫ ДЛЯ AI (СКРЫТЫЕ) ===
    'prompt_lang': {
      'ru': 'Отвечай на РУССКОМ языке.',
      'kk': 'ҚАЗАҚ тілінде жауап бер.',
      'en': 'Answer in ENGLISH.',
    }
  };
}
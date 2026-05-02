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
    'dark_mode': {
      'ru': 'Темная тема',
      'kk': 'Күңгірт режим',
      'en': 'Dark Mode'
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
    },
    // === НАСТРОЙКИ ===
    'diet': {'ru': 'Диета', 'kk': 'Диета', 'en': 'Diet'},
    'vegan': {'ru': 'Веган', 'kk': 'Веган', 'en': 'Vegan'},
    'vegetarian': {'ru': 'Вегетарианец', 'kk': 'Вегетарианец', 'en': 'Vegetarian'},

// === ПРОМПТЫ (Дополняем логику) ===
    'prompt_vegan': {
      'ru': 'РЕЦЕПТЫ ДОЛЖНЫ БЫТЬ СТРОГО ВЕГАНСКИМИ (без мяса, рыбы, яиц, молока).',
      'en': 'RECIPES MUST BE STRICTLY VEGAN (no meat, fish, eggs, dairy).',
      'kk': 'РЕЦЕПТТЕР ҚАТАҢ ВЕГАНДЫҚ БОЛУЫ ТИІС (ет, балық, жұмыртқа, сүтсіз).',
    },
    'prompt_vegetarian': {
      'ru': 'РЕЦЕПТЫ ДОЛЖНЫ БЫТЬ ВЕГЕТЕРИАНСКИМИ (без мяса и рыбы, но можно яйца и молоко).',
      'en': 'RECIPES MUST BE VEGETARIAN (no meat or fish, but eggs and dairy are allowed).',
      'kk': 'РЕЦЕПТТЕР ВЕГЕТЕРИАНДЫҚ БОЛУЫ ТИІС (ет пен балықсыз, бірақ жұмыртқа мен сүтке болады).',
    },
    // Добавьте это в существующий map _localizedValues
    'today': {'ru': 'Сегодня', 'kk': 'Бүгін', 'en': 'Today'},
    'kcal': {'ru': 'ккал', 'kk': 'ккал', 'en': 'kcal'},
    'my_recipes': {'ru': 'Мои рецепты', 'kk': 'Менің рецепттерім', 'en': 'My Recipes'}, // Если не было
    'search': {'ru': 'Поиск', 'kk': 'Іздеу', 'en': 'Search'}, // Если не было
    // Добавить в существующий map:
    'cooked_this': {
      'ru': 'Я приготовил это',
      'kk': 'Мен мұны дайындадым',
      'en': 'I cooked this'
    },
    'calories_added': {
      'ru': 'Калории добавлены в трекер!',
      'kk': 'Калориялар трекерге қосылды!',
      'en': 'Calories added to tracker!'
    },
    // ... твои старые переводы ...

    // === ГРАФИКИ И ЦЕЛИ (НОВОЕ) ===
    'history_title': {
      'ru': 'История (7 дней)',
      'kk': 'Тарих (7 күн)',
      'en': 'History (7 days)'
    },
    'no_data': {
      'ru': 'Нет данных',
      'kk': 'Деректер жоқ',
      'en': 'No data'
    },
    'my_goal': {
      'ru': 'Моя цель (ккал)',
      'kk': 'Менің мақсатым (ккал)',
      'en': 'My goal (kcal)'
    },
    'limit_exceeded': {
      'ru': 'Лимит!',
      'kk': 'Лимит!',
      'en': 'Limit!'
    },
    // === МАКРОСЫ (БЖУ) ===
    'macros': {'ru': 'БЖУ на порцию', 'kk': 'БМК (Бір үлес)', 'en': 'Macros per serving'},
    'protein': {'ru': 'Белки', 'kk': 'Ақуыз', 'en': 'Protein'},
    'fats': {'ru': 'Жиры', 'kk': 'Майлар', 'en': 'Fats'},
    'carbs': {'ru': 'Углеводы', 'kk': 'Көмірсу', 'en': 'Carbs'},
    'g': {'ru': 'г', 'kk': 'г', 'en': 'g'},
    // === ГЕЙМИФИКАЦИЯ И ПРОДУКТЫ ===
    'buy_groceries': {'ru': 'Купить продукты', 'kk': 'Азық-түлік алу', 'en': 'Buy groceries'},
    'i_cooked_this': {'ru': 'Я приготовил это', 'kk': 'Мен мұны пісірдім', 'en': 'I cooked this'},
    'shopping_bonus': {'ru': 'Бонус за шопинг: +150 XP! 💎', 'kk': 'Сауда бонусы: +150 XP! 💎', 'en': 'Shopping bonus: +150 XP! 💎'},
    'xp_added': {'ru': 'XP начислен', 'kk': 'XP қосылды', 'en': 'XP added'},

    // HUD и Профиль
    'level_short': {'ru': 'Ур.', 'kk': 'Ден.', 'en': 'Lvl'},
    'chef_level': {'ru': 'Шеф-повар Уровня', 'kk': 'Бас аспаз деңгейі', 'en': 'Chef Level'},
    'goal': {'ru': 'Цель', 'kk': 'Мақсат', 'en': 'Goal'},
    'dishes_cooked': {'ru': 'Блюд готово', 'kk': 'Дайын тағамдар', 'en': 'Dishes cooked'},
    'day_streak': {'ru': 'Серия дней', 'kk': 'Күндер сериясы', 'en': 'Day streak'},

    // === АВТОРИЗАЦИЯ И ТЕЛЕФОН (PHONE LOGIN) ===
    'email_hint': {
      'ru': 'Электронная почта',
      'kk': 'Электрондық пошта',
      'en': 'Email Address',
    },
    'password_hint': {
      'ru': 'Пароль',
      'kk': 'Құпия сөз',
      'en': 'Password',
    },
    'password_validation_error': {
      'ru': 'Пароль должен быть > 8 символов, содержать буквы и цифры',
      'kk': 'Құпия сөз 8 таңбадан көп болуы, әріптер мен сандардан тұруы керек',
      'en': 'Password must be > 8 chars, include letters and numbers',
    },
    'invalid_email': {
      'ru': 'Введите корректный email',
      'kk': 'Дұрыс email енгізіңіз',
      'en': 'Enter a valid email',
    },
    'verification_sent': {
      'ru': 'Письмо для подтверждения отправлено на почту!',
      'kk': 'Растау хаты поштаға жіберілді!',
      'en': 'Verification email has been sent!',
    },
    'email_not_verified': {
      'ru': 'Пожалуйста, подтвердите ваш email перед входом',
      'kk': 'Кірмес бұрын email-ды растаңыз',
      'en': 'Please verify your email before signing in',
    },
    'submit': {
      'ru': 'Отправить',
      'kk': 'Жіберу',
      'en': 'Submit',
    },
    'phone_hint': {
      'ru': 'Номер телефона (+7...)',
      'kk': 'Телефон нөмірі (+7...)',
      'en': 'Phone number (+7...)',
    },
    'get_code': {
      'ru': 'Получить код',
      'kk': 'Кодты алу',
      'en': 'Get code',
    },
    'sms_code': {
      'ru': 'SMS-код',
      'kk': 'SMS-код',
      'en': 'SMS code',
    },
    'enter': {
      'ru': 'Войти',
      'kk': 'Кіру',
      'en': 'Sign in',
    },
    'invalid_sms': {
      'ru': 'Неверный SMS-код',
      'kk': 'Қате SMS-код',
      'en': 'Invalid SMS code',
    },
    'error': {
      'ru': 'Ошибка',
      'kk': 'Қате',
      'en': 'Error',
    },

    // === ПЕРВОНАЧАЛЬНАЯ НАСТРОЙКА (PROFILE SETUP) ===
    'profile_setup': {
      'ru': 'Настройка профиля',
      'kk': 'Профильді баптау',
      'en': 'Profile Setup',
    },
    'complete_setup': {
      'ru': 'Завершить и начать работу',
      'kk': 'Аяқтау және бастау',
      'en': 'Complete and start',
    },

    // === ОНБОРДИНГ (ПЕРВАЯ НАСТРОЙКА) ===
    'profile_setup': {
      'ru': 'Настройка профиля',
      'kk': 'Профильді баптау',
      'en': 'Profile Setup',
    },
    'welcome_setup': {
      'ru': 'Добро пожаловать!\nДавайте настроим ваш профиль.',
      'kk': 'Қош келдіңіз!\nПрофиліңізді баптайық.',
      'en': 'Welcome!\nLet\'s set up your profile.',
    },
    'complete_setup': {
      'ru': 'Сохранить профиль и начать',
      'kk': 'Профильді сақтап, бастау',
      'en': 'Save profile and start',
    },

    // === ВКЛАДКИ И РЕГИСТРАЦИЯ ===
    'tab_login': {
      'ru': 'Вход',
      'kk': 'Кіру',
      'en': 'Login',
    },
    'tab_register': {
      'ru': 'Регистрация',
      'kk': 'Тіркелу',
      'en': 'Sign Up',
    },
    'login_welcome': {
      'ru': 'С возвращением! Войдите в аккаунт',
      'kk': 'Қайта оралуыңызбен! Аккаунтқа кіріңіз',
      'en': 'Welcome back! Sign in to your account',
    },
    'register_welcome': {
      'ru': 'Создайте аккаунт, чтобы сохранять рецепты',
      'kk': 'Рецепттерді сақтау үшін аккаунт жасаңыз',
      'en': 'Create an account to save recipes',
    },
    'register_google': {
      'ru': 'Регистрация через Google',
      'kk': 'Google арқылы тіркелу',
      'en': 'Sign up with Google',
    },
    'register_phone': {
      'ru': 'Регистрация по телефону',
      'kk': 'Телефон арқылы тіркелу',
      'en': 'Sign up with Phone',
    },

    // Диалог уровня
    'level_up_title': {'ru': 'НОВЫЙ УРОВЕНЬ!', 'kk': 'ЖАҢА ДЕҢГЕЙ!', 'en': 'LEVEL UP!'},
    'level_up_desc': {'ru': 'Поздравляем! Вы достигли уровня', 'kk': 'Құттықтаймыз! Сіз деңгейге жеттіңіз:', 'en': 'Congrats! You reached level'},
    'cool': {'ru': 'КРУТО!', 'kk': 'КЕРЕМЕТ!', 'en': 'COOL!'},
    'history_title': {'ru': 'История питания', 'kk': 'Тамақтану тарихы', 'en': 'Food History'},
    'empty_history': {'ru': 'Пока пусто', 'kk': 'Әзірге бос', 'en': 'Empty so far'},
    'daily_goal': {'ru': 'Моя цель (ккал)', 'kk': 'Күнделікті мақсат (ккал)', 'en': 'Daily Goal (kcal)'},
  };
}
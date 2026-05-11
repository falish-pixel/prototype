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
    'search': {'ru': 'Поиск', 'kk': 'Іздеу', 'en': 'Search'},
    'home': {'ru': 'Главная', 'kk': 'Басты бет', 'en': 'Home'},

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
      'ru': 'Сделайте фото или введите список вручную',
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
    'no_results': {
      'ru': 'Ничего не найдено',
      'kk': 'Ештеңе табылмады',
      'en': 'No results found',
    },
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
    'min': {'ru': 'мин', 'kk': 'мин', 'en': 'min'},
    'today': {'ru': 'Сегодня', 'kk': 'Бүгін', 'en': 'Today'},
    'kcal': {'ru': 'ккал', 'kk': 'ккал', 'en': 'kcal'},
    'breakfast': {'ru': 'Завтрак', 'kk': 'Таңғы ас', 'en': 'Breakfast'},
    'lunch': {'ru': 'Обед', 'kk': 'Түскі ас', 'en': 'Lunch'},
    'dinner': {'ru': 'Ужин', 'kk': 'Кешкі ас', 'en': 'Dinner'},
    'dessert': {'ru': 'Десерт', 'kk': 'Десерт', 'en': 'Dessert'},
    'snack': {'ru': 'Перекус', 'kk': 'Тіскебасар', 'en': 'Snack'},
    'all': {'ru': 'Все', 'kk': 'Барлығы', 'en': 'All'},
    'my_recipes': {'ru': 'Мои рецепты', 'kk': 'Менің рецепттерім', 'en': 'My Recipes'}, // Если не было
    'search': {'ru': 'Поиск', 'kk': 'Іздеу', 'en': 'Search'}, // Если не было
    // Добавить в существующий map:
    'cooked_this': {
      'ru': 'Я приготовил это',
      'kk': 'Мен мұны дайындадым',
      'en': 'I cooked this'
    },
    'recipe_of_day': {
      'ru': 'Рецепт дня',
      'kk': 'Күн рецепті',
      'en': 'Recipe of the Day'
    },
    'try_now': {
      'ru': 'Попробовать',
      'kk': 'Қазір байқап көру',
      'en': 'Try now'
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
    'forgot_password': {
      'ru': 'Забыли пароль?',
      'kk': 'Құпия сөзді ұмыттыңыз ба?',
      'en': 'Forgot Password?',
    },
    'forgot_password_title': {
      'ru': 'Восстановление пароля',
      'kk': 'Құпия сөзді қайта орнату',
      'en': 'Reset Password',
    },
    'forgot_password_subtitle': {
      'ru': 'Введите ваш Email, и мы отправим ссылку для сброса пароля',
      'kk': 'Email-ды енгізіңіз, біз құпия сөзді қайта орнату сілтемесін жібереміз',
      'en': 'Enter your email and we will send you a password reset link',
    },
    'send': {
      'ru': 'Отправить',
      'kk': 'Жіберу',
      'en': 'Send',
    },
    'back_to_login': {
      'ru': 'Назад ко входу',
      'kk': 'Кіруге қайту',
      'en': 'Back to Login',
    },
    'reset_link_sent': {
      'ru': 'Ссылка для сброса пароля отправлена!',
      'kk': 'Құпия сөзді қайта орнату сілтемесі жіберілді!',
      'en': 'Password reset link sent!',
    },
    'error_user_not_found': {
      'ru': 'Пользователь не найден',
      'kk': 'Пайдаланушы табылмады',
      'en': 'User not found',
    },
    'error_wrong_password': {
      'ru': 'Неверный пароль',
      'kk': 'Құпия сөз қате',
      'en': 'Wrong password',
    },
    'error_network': {
      'ru': 'Ошибка сети',
      'kk': 'Желі қатесі',
      'en': 'Network error',
    },
    'check_email': {
      'ru': 'Проверьте почту',
      'kk': 'Поштаңызды тексеріңіз',
      'en': 'Check your email',
    },
    'username_hint': {
      'ru': 'Имя пользователя (логин)',
      'kk': 'Пайдаланушы аты (логин)',
      'en': 'Username',
    },
    'username_taken': {
      'ru': 'Этот логин уже занят',
      'kk': 'Бұл логин бос емес',
      'en': 'Username is already taken',
    },
    'login_id_hint': {
      'ru': 'Email или Логин',
      'kk': 'Email немесе Логин',
      'en': 'Email or Username',
    },
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
      'ru': 'Мин. 8 символов: заглавная буква, цифра и спецсимвол (!@#...)',
      'kk': 'Кемінде 8 таңба: бас әріп, сан және арнайы таңба (!@#...)',
      'en': 'Min 8 chars: uppercase, digit and special char (!@#...)',
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
    'verify_email_title': {
      'ru': 'Подтвердите почту',
      'kk': 'Поштаны растаңыз',
      'en': 'Verify Your Email',
    },
    'verify_email_subtitle': {
      'ru': 'Мы отправили письмо на {email}. Пожалуйста, перейдите по ссылке в письме, чтобы продолжить.',
      'kk': 'Біз {email} поштасына хат жібердік. Жалғастыру үшін хаттағы сілтеме бойынша өтіңіз.',
      'en': 'We sent an email to {email}. Please click the link in the email to continue.',
    },
    'resend_email': {
      'ru': 'Отправить письмо еще раз',
      'kk': 'Хатты қайта жіберу',
      'en': 'Resend Email',
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
    'logout': {
      'ru': 'Выйти из аккаунта',
      'kk': 'Аккаунттан шығу',
      'en': 'Logout',
    },
    'delete_account': {
      'ru': 'Удалить аккаунт',
      'kk': 'Аккаунтты жою',
      'en': 'Delete Account',
    },
    'delete_confirm_title': {
      'ru': 'Вы уверены?',
      'kk': 'Сенімдісіз бе?',
      'en': 'Are you sure?',
    },
    'delete_confirm_desc': {
      'ru': 'Это действие нельзя отменить. Все ваши данные и логин будут удалены навсегда.',
      'kk': 'Бұл әрекетті болдырмау мүмкін емес. Барлық деректеріңіз бен логиніңіз біржола жойылады.',
      'en': 'This action cannot be undone. All your data and username will be deleted permanently.',
    },
    'delete': {
      'ru': 'Удалить',
      'kk': 'Жою',
      'en': 'Delete',
    },
    'enter_password_to_delete': {
      'ru': 'Введите пароль для удаления',
      'kk': 'Жою үшін құпия сөзді енгізіңіз',
      'en': 'Enter password to delete',
    },
    'confirm_delete_button': {
      'ru': 'Подтвердить удаление',
      'kk': 'Жоюды растау',
      'en': 'Confirm Deletion',
    },
    'password_label': {
      'ru': 'Ваш пароль',
      'kk': 'Құпия сөзіңіз',
      'en': 'Your password',
    },
    'delete_account_step2': {
      'ru': 'Последний шаг: введите пароль, чтобы мы убедились, что это вы.',
      'kk': 'Соңғы қадам: бұл сіз екеніңізге көз жеткізу үшін құпия сөзді енгізіңіз.',
      'en': 'Last step: enter your password so we know it\'s you.',
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

    // === ФИЛЬТРЫ И ПОИСК ===
    'filters': {
      'ru': 'Фильтры',
      'kk': 'Сүзгілер',
      'en': 'Filters'
    },
    'max_time': {
      'ru': 'Макс. время',
      'kk': 'Макс. уақыт',
      'en': 'Max time'
    },
    'max_kcal': {
      'ru': 'Макс. калории',
      'kk': 'Макс. калориялар',
      'en': 'Max kcal'
    },
    'dietary': {
      'ru': 'Диета', // 'diet' уже есть, но для шторки можно использовать 'dietary'
      'kk': 'Диета',
      'en': 'Dietary'
    },
    'reset': { // Если ключа еще нет
      'ru': 'Сбросить',
      'kk': 'Қалпына келтіру',
      'en': 'Reset'
    },
    'apply': {
      'ru': 'Применить',
      'kk': 'Қолдану',
      'en': 'Apply'
    },
    'no_results_desc': {
      'ru': 'Попробуйте изменить запрос\nили параметры фильтра',
      'kk': 'Сұрауды немесе сүзгі параметрлерін\nөзгертіп көріңіз',
      'en': 'Try changing your query\nor filter parameters'
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
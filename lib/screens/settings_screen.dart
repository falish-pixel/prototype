import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Добавлен Firebase для имени
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/calorie_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool isInitialSetup; // Флаг первого входа

  const SettingsScreen({super.key, this.isInitialSetup = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _glutenFree = false;
  bool _lactoseFree = false;
  bool _nutAllergy = false;
  bool _isVegan = false;
  bool _isVegetarian = false;

  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Контроллер имени

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCalorieGoal();

    // Подтягиваем имя из Google (если зашли через него)
    _nameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  Future<void> _loadCalorieGoal() async {
    int goal = await CalorieService.getCurrentGoal();
    if (mounted) {
      setState(() {
        _goalController.text = goal.toString();
      });
    }
  }

  Future<void> _saveCalorieGoal() async {
    if (_goalController.text.isEmpty) return;
    int? newGoal = int.tryParse(_goalController.text);
    if (newGoal != null && newGoal > 500 && newGoal < 10000) {
      await CalorieService.updateGoal(newGoal);
      // Показываем Снэкбар, только если это НЕ первый вход (чтобы не мешало переходу)
      if (mounted && !widget.isInitialSetup) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(LanguageService.tr('save')))
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glutenFree = prefs.getBool('glutenFree') ?? false;
      _lactoseFree = prefs.getBool('lactoseFree') ?? false;
      _nutAllergy = prefs.getBool('nutAllergy') ?? false;
      _isVegan = prefs.getBool('isVegan') ?? false;
      _isVegetarian = prefs.getBool('isVegetarian') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // === ЛОГИКА ЗАВЕРШЕНИЯ НАСТРОЙКИ ===
  Future<void> _completeInitialSetup() async {
    // 1. Сохраняем имя (с обходом бага Firebase)
    if (_nameController.text.trim().isNotEmpty) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      } catch (e) {
        debugPrint('Проигнорирована системная ошибка Firebase: $e');
      }
    }

    // 2. Сохраняем калории
    await _saveCalorieGoal();

    // 3. Отмечаем, что настройка пройдена
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isProfileSetup', true);

    // 4. Переходим на главную
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSetup
            ? LanguageService.tr('profile_setup') // Локализованный заголовок
            : LanguageService.tr('settings')),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      // Твой родной ListView без лишних оберток
      body: ListView(
        children: [
          // === БЛОК ПРИВЕТСТВИЯ И ИМЕНИ (ТОЛЬКО ДЛЯ ПЕРВОГО ВХОДА) ===
          if (widget.isInitialSetup) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                LanguageService.tr('welcome_setup'), // Локализованное приветствие
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(LanguageService.tr('your_name'),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.green),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: LanguageService.tr('change_name_hint'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 30),
          ],

          // --- БЛОК ЦЕЛИ ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(LanguageService.tr('daily_goal'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.orange),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "2000",
                      ),
                      onSubmitted: (_) => _saveCalorieGoal(),
                    ),
                  ),
                  if (!widget.isInitialSetup) // Скрываем обычную кнопку "Сохранить", если это онбординг
                    TextButton(
                      onPressed: _saveCalorieGoal,
                      child: Text(LanguageService.tr('save')),
                    )
                ],
              ),
            ),
          ),

          const Divider(height: 30),

          // --- ЯЗЫК ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(LanguageService.tr('language'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: LanguageService.currentLanguage.value,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text("🇷🇺 Русский")),
                    DropdownMenuItem(value: 'kk', child: Text("🇰🇿 Қазақ тілі")),
                    DropdownMenuItem(value: 'en', child: Text("🇺🇸 English")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      LanguageService.setLanguage(val);
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
          ),

          const Divider(height: 30),

          // --- ТЕМА ---
          SwitchListTile(
            title: Text(LanguageService.tr('dark_mode')),
            secondary: const Icon(Icons.dark_mode),
            value: ThemeService.isDarkMode.value,
            onChanged: (val) {
              ThemeService.toggleTheme(val);
              setState(() {});
            },
          ),

          const Divider(height: 30),

          // --- ДИЕТА ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(LanguageService.tr('diet'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('vegan')),
            secondary: const Icon(Icons.grass, color: Colors.green),
            value: _isVegan,
            onChanged: (val) {
              setState(() {
                _isVegan = val;
                if (val) _isVegetarian = false;
              });
              _saveSetting('isVegan', val);
              _saveSetting('isVegetarian', false);
            },
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('vegetarian')),
            secondary: const Icon(Icons.egg_alt, color: Colors.orange),
            value: _isVegetarian,
            onChanged: (val) {
              setState(() {
                _isVegetarian = val;
                if (val) _isVegan = false;
              });
              _saveSetting('isVegetarian', val);
              _saveSetting('isVegan', false);
            },
          ),

          const Divider(height: 30),

          // --- ПИЩЕВЫЕ ОГРАНИЧЕНИЯ ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(LanguageService.tr('food_restrictions'),
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('gluten_free')),
            secondary: const Icon(Icons.bakery_dining),
            value: _glutenFree,
            onChanged: (val) {
              setState(() => _glutenFree = val);
              _saveSetting('glutenFree', val);
            },
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('lactose_free')),
            secondary: const Icon(Icons.local_drink),
            value: _lactoseFree,
            onChanged: (val) {
              setState(() => _lactoseFree = val);
              _saveSetting('lactoseFree', val);
            },
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('nut_allergy')),
            secondary: const Icon(Icons.nature_people),
            value: _nutAllergy,
            onChanged: (val) {
              setState(() => _nutAllergy = val);
              _saveSetting('nutAllergy', val);
            },
          ),

          // === КНОПКА ЗАВЕРШЕНИЯ В САМОМ КОНЦЕ СПИСКА ===
          if (widget.isInitialSetup) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: ElevatedButton(
                onPressed: _completeInitialSetup,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(LanguageService.tr('complete_setup'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            const SizedBox(height: 40), // Отступ для обычных настроек снизу
          ]
        ],
      ),
    );
  }
}
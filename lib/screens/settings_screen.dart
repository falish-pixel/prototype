import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Для фильтра цифр
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/calorie_service.dart'; // Импорт сервиса

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _glutenFree = false;
  bool _lactoseFree = false;
  bool _nutAllergy = false;
  bool _isVegan = false;
  bool _isVegetarian = false;

  // Контроллер для цели
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCalorieGoal();
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
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.tr('settings'))),
      body: ListView(
        children: [
          // === НОВЫЙ БЛОК: АККАУНТ ===
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(LanguageService.tr('account'), // "Аккаунт"
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: Text(LanguageService.tr('change_name')), // "Изменить имя"
            subtitle: Text(LanguageService.tr('change_name_hint')), // "Настройте, как к вам обращаться"
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // Переходим на экран профиля
              await Navigator.pushNamed(context, '/profile');
              // Когда вернемся, обновляем UI (если вдруг что-то поменялось)
              setState(() {});
            },
          ),
          const Divider(height: 30),
          // --- БЛОК ЦЕЛИ ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Моя цель (ккал)", // Можно добавить в словарь переводов
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
        ],
      ),
    );
  }
}
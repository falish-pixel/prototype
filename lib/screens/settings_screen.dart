import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _glutenFree = false;
  bool _lactoseFree = false;
  bool _nutAllergy = false;
  // Новые переменные для диеты
  bool _isVegan = false;
  bool _isVegetarian = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
          // ЯЗЫК
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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

          // ТЕМА
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

          // ДИЕТА (НОВОЕ)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(LanguageService.tr('diet'), // Добавьте ключ 'diet' в переводы
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('vegan')), // 'vegan'
            secondary: const Icon(Icons.grass, color: Colors.green),
            value: _isVegan,
            onChanged: (val) {
              setState(() {
                _isVegan = val;
                if (val) _isVegetarian = false; // Взаимоисключение
              });
              _saveSetting('isVegan', val);
              _saveSetting('isVegetarian', false);
            },
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('vegetarian')), // 'vegetarian'
            secondary: const Icon(Icons.egg_alt, color: Colors.orange),
            value: _isVegetarian,
            onChanged: (val) {
              setState(() {
                _isVegetarian = val;
                if (val) _isVegan = false; // Взаимоисключение
              });
              _saveSetting('isVegetarian', val);
              _saveSetting('isVegan', false);
            },
          ),

          const Divider(height: 30),

          // ПИЩЕВЫЕ ОГРАНИЧЕНИЯ
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
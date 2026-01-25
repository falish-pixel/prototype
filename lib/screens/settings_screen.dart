// Файл: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/language_service.dart'; // Импорт сервиса языков

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _glutenFree = false;
  bool _lactoseFree = false;
  bool _nutAllergy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Загружаем сохраненные настройки при входе
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glutenFree = prefs.getBool('glutenFree') ?? false;
      _lactoseFree = prefs.getBool('lactoseFree') ?? false;
      _nutAllergy = prefs.getBool('nutAllergy') ?? false;
    });
  }

  // Сохраняем настройку при изменении
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок берем из словаря
        title: Text(LanguageService.tr('settings')),
      ),
      body: ListView(
        children: [

          // --- СЕКЦИЯ ЯЗЫКА (НОВАЯ) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              LanguageService.tr('language'), // "Язык" / "Тіл"
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: LanguageService.currentLanguage.value,
                  isExpanded: true,
                  icon: const Icon(Icons.language, color: Colors.green),
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text("🇷🇺 Русский")),
                    DropdownMenuItem(value: 'kk', child: Text("🇰🇿 Қазақ тілі")),
                    DropdownMenuItem(value: 'en', child: Text("🇺🇸 English")),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      // Меняем язык глобально
                      LanguageService.setLanguage(newValue);
                      // Обновляем текущий экран, чтобы Dropdown перерисовался
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
          ),

          const Divider(height: 30),

          // --- СЕКЦИЯ ПРОФИЛЯ ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text("Аккаунт", // Можно тоже добавить в словарь как 'account'
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text("Изменить имя"), // 'change_name'
            subtitle: const Text("Настройте, как к вам обращаться"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/profile');
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),

          const Divider(height: 30),

          // --- СЕКЦИЯ ПИЩЕВЫХ ПРЕДПОЧТЕНИЙ ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text("Пищевые ограничения", // 'food_restrictions'
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text("Без Глютена"), // 'gluten_free'
            secondary: const Icon(Icons.bakery_dining),
            value: _glutenFree,
            onChanged: (val) {
              setState(() => _glutenFree = val);
              _saveSetting('glutenFree', val);
            },
          ),
          SwitchListTile(
            title: const Text("Без Лактозы"), // 'lactose_free'
            secondary: const Icon(Icons.local_drink),
            value: _lactoseFree,
            onChanged: (val) {
              setState(() => _lactoseFree = val);
              _saveSetting('lactoseFree', val);
            },
          ),
          SwitchListTile(
            title: const Text("Аллергия на Орехи"), // 'nut_allergy'
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
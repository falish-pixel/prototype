// Файл: lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';

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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glutenFree = prefs.getBool('glutenFree') ?? false;
      _lactoseFree = prefs.getBool('lactoseFree') ?? false;
      _nutAllergy = prefs.getBool('nutAllergy') ?? false;
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

          // АККАУНТ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(LanguageService.tr('account'), // <-- ИСПРАВЛЕНО
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: Text(LanguageService.tr('change_name')), // <-- ИСПРАВЛЕНО
            subtitle: Text(LanguageService.tr('change_name_hint')), // <-- ИСПРАВЛЕНО
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () async {
              final result = await Navigator.pushNamed(context, '/profile');
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          const Divider(height: 30),

          // ПИЩЕВЫЕ ОГРАНИЧЕНИЯ
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(LanguageService.tr('food_restrictions'), // <-- ИСПРАВЛЕНО
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('gluten_free')), // <-- ИСПРАВЛЕНО
            secondary: const Icon(Icons.bakery_dining),
            value: _glutenFree,
            onChanged: (val) {
              setState(() => _glutenFree = val);
              _saveSetting('glutenFree', val);
            },
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('lactose_free')), // <-- ИСПРАВЛЕНО
            secondary: const Icon(Icons.local_drink),
            value: _lactoseFree,
            onChanged: (val) {
              setState(() => _lactoseFree = val);
              _saveSetting('lactoseFree', val);
            },
          ),
          SwitchListTile(
            title: Text(LanguageService.tr('nut_allergy')), // <-- ИСПРАВЛЕНО
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
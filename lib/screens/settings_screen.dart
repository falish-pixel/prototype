import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Добавил импорт

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
      appBar: AppBar(title: const Text("Настройки")),
      body: ListView(
        children: [
          // --- СЕКЦИЯ ПРОФИЛЯ ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text("Аккаунт",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text("Изменить имя"),
            subtitle: const Text("Настройте, как к вам обращаться"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () async {
              // 1. Ждем возврата из профиля и проверяем результат
              final result = await Navigator.pushNamed(context, '/profile');

              // 2. Если профиль вернул true (значит имя меняли),
              // то мы закрываем настройки и тоже передаем true на Главный экран
              if (result == true && context.mounted) {
                // Можно просто выйти назад, передав true
                Navigator.pop(context, true);
              }
            },
          ),

          const Divider(height: 30), // Визуальный разделитель

          // --- СЕКЦИЯ ПИЩЕВЫХ ПРЕДПОЧТЕНИЙ ---
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text("Пищевые ограничения",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text("Без Глютена"),
            secondary: const Icon(Icons.bakery_dining),
            value: _glutenFree,
            onChanged: (val) {
              setState(() => _glutenFree = val);
              _saveSetting('glutenFree', val);
            },
          ),
          SwitchListTile(
            title: const Text("Без Лактозы"),
            secondary: const Icon(Icons.local_drink),
            value: _lactoseFree,
            onChanged: (val) {
              setState(() => _lactoseFree = val);
              _saveSetting('lactoseFree', val);
            },
          ),
          SwitchListTile(
            title: const Text("Аллергия на Орехи"),
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
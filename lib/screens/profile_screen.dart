// Файл: lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user?.displayName ?? "";
    }
  }

  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 1. Обновляем имя
      await user?.updateDisplayName(_nameController.text.trim());
      // 2. Обновляем локальные данные (reload)
      await user?.reload();
    } catch (e) {
      final String errorText = e.toString();
      // Игнорируем ошибку Pigeon, если она вылезет
      if (errorText.contains('PigeonUserInfo') || errorText.contains('List<Object?>')) {
        try { await user?.reload(); } catch(_) {}
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Имя сохранено!")));
      // Возвращаемся назад
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Редактировать профиль")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Ваше имя", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateName,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }
}
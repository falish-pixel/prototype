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
    // Подставляем текущее имя при открытии
    if (user != null) {
      _nameController.text = user?.displayName ?? "";
    }
  }

  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Обновляем имя в профиле Firebase
      await user?.updateDisplayName(_nameController.text.trim());

      // 2. Перезагружаем пользователя, чтобы данные обновились локально
      await user?.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Имя успешно обновлено!")),
        );
        Navigator.pop(context); // Возвращаемся назад
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            const Text(
              "Как к вам обращаться?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Ваше имя",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Сохранить"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/user_service.dart';

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
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 1. Пытаемся обновить в Auth (может выдать ошибку, но имя сменит)
      try {
        await user?.updateDisplayName(_nameController.text.trim());
      } catch (_) {}

      // 2. ГАРАНТИРОВАННО сохраняем в Firestore
      await UserService.updateNameInFirestore(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LanguageService.tr('name_saved')), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.tr('edit_profile'))),
      body: SingleChildScrollView( // Чтобы не было проблем на маленьких экранах
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Аватарка (заглушка)
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1), // Современный метод прозрачности
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 40),

            // Поле ввода имени
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('your_name'),
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            // Кнопка Сохранить
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateName,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : Text(
                    LanguageService.tr('save'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
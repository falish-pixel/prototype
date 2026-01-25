// Файл: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await _authService.signInWithGoogle();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, включена ли темная тема
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Фон теперь берется из настройки темы в main.dart (темный или светлый)
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // В темной теме делаем круг полупрозрачным, в светлой — светлым
                  color: isDark ? Colors.green.withOpacity(0.2) : Colors.green[100],
                ),
                child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 30),

              Text(
                LanguageService.tr('app_title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                LanguageService.tr('login_subtitle'),
                // Цвет подзаголовка адаптируем
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              if (_isLoading)
                const CircularProgressIndicator(color: Colors.green)
              else ...[
                // Кнопка Google (оставляем белой для узнаваемости)
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login),
                  label: Text(LanguageService.tr('login_google')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 16),
                // Кнопка телефона
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone),
                  label: Text(LanguageService.tr('login_phone')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
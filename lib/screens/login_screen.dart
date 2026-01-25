import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    // Если вход успешен, StreamBuilder в main.dart сам переключит экран
    if (user != null) {
      print("Успешный вход: ${user.user?.email}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип или иконка
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green[100],
                ),
                child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 30),
              const Text(
                "Smart Recipe Generator",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Войдите, чтобы сохранять рецепты",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),

              if (_isLoading)
                const CircularProgressIndicator(color: Colors.green)
              else ...[
                // Кнопка Google
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login), // Можно найти иконку Google в пакете font_awesome_flutter
                  label: const Text("Войти через Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 2,
                  ),
                ),
                const SizedBox(height: 16),
                // Заготовка под телефон (реализация сложнее из-за SMS кода)
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Вход по телефону требует дополнительной настройки SMS")),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text("Войти по номеру телефона"),
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
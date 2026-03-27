// Файл: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import 'phone_login_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Логотип
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.green.withOpacity(0.2) : Colors.green[100],
                ),
                child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 20),
              Text(
                LanguageService.tr('app_title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Вкладки переключения
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: LanguageService.tr('tab_login')),
                    Tab(text: LanguageService.tr('tab_register')),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Содержимое вкладок
              Expanded(
                child: TabBarView(
                  children: [
                    // --- ВКЛАДКА "ВХОД" ---
                    _buildAuthTab(
                      context: context,
                      isDark: isDark,
                      subtitle: LanguageService.tr('login_welcome'),
                      googleText: LanguageService.tr('login_google'),
                      phoneText: LanguageService.tr('login_phone'),
                    ),

                    // --- ВКЛАДКА "РЕГИСТРАЦИЯ" ---
                    _buildAuthTab(
                      context: context,
                      isDark: isDark,
                      subtitle: LanguageService.tr('register_welcome'),
                      googleText: LanguageService.tr('register_google'),
                      phoneText: LanguageService.tr('register_phone'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Виджет для отрисовки внутренностей вкладки
  Widget _buildAuthTab({
    required BuildContext context,
    required bool isDark,
    required String subtitle,
    required String googleText,
    required String phoneText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            subtitle,
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          if (_isLoading)
            const CircularProgressIndicator(color: Colors.green)
          else ...[
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: const Icon(Icons.login),
              label: Text(googleText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
                );
              },
              icon: const Icon(Icons.phone),
              label: Text(phoneText),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
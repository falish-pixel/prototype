// Файл: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Контроллеры для ввода
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Валидация пароля: > 8 символов, буквы и цифры
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LanguageService.tr('password_validation_error');
    }
    bool hasLetters = value.contains(RegExp(r'[a-zA-Z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    if (value.length < 8 || !hasLetters || !hasDigits) {
      return LanguageService.tr('password_validation_error');
    }
    return null;
  }

  // Валидация Email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty || !value.contains('@')) {
      return LanguageService.tr('invalid_email');
    }
    return null;
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleEmailSignUp() async {
    if (_formKeyRegister.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        _showSnackBar(LanguageService.tr('verification_sent'));
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? e.code);
      } catch (e) {
        _showSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleEmailSignIn() async {
    if (_formKeyLogin.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential? result = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (result?.user != null && !result!.user!.emailVerified) {
          _showSnackBar(LanguageService.tr('email_not_verified'));
          // Опционально: можно выйти или просто предупредить
        }
      } on FirebaseAuthException catch (e) {
        _showSnackBar(e.message ?? e.code);
      } catch (e) {
        _showSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
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

                const SizedBox(height: 20),

                // Содержимое вкладок
                SizedBox(
                  height: 500, // Фиксированная высота для TabBarView внутри SingleChildScrollView
                  child: TabBarView(
                    children: [
                      // --- ВКЛАДКА "ВХОД" ---
                      _buildEmailAuthForm(
                        formKey: _formKeyLogin,
                        subtitle: LanguageService.tr('login_welcome'),
                        buttonText: LanguageService.tr('enter'),
                        onPressed: _handleEmailSignIn,
                        isDark: isDark,
                      ),

                      // --- ВКЛАДКА "РЕГИСТРАЦИЯ" ---
                      _buildEmailAuthForm(
                        formKey: _formKeyRegister,
                        subtitle: LanguageService.tr('register_welcome'),
                        buttonText: LanguageService.tr('submit'),
                        onPressed: _handleEmailSignUp,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailAuthForm({
    required GlobalKey<FormState> formKey,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Text(
              subtitle,
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('email_hint'),
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('password_hint'),
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
              validator: _validatePassword,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.green)
            else ...[
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonText),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleGoogleSignIn,
                icon: const Icon(Icons.login),
                label: Text(LanguageService.tr('login_google')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
  bool _isPasswordVisible = false;
  bool _showForgotPassword = false; // Состояние для переключения на форму восстановления

  // Контроллеры для ввода
  final TextEditingController _loginIdController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();    
  final TextEditingController _usernameController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotEmailController = TextEditingController(); // Новый контроллер
  
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();
  final _formKeyForgot = GlobalKey<FormState>();

  @override
  void dispose() {
    _loginIdController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found': return LanguageService.tr('error_user_not_found');
      case 'wrong-password': return LanguageService.tr('error_wrong_password');
      case 'username-taken': return LanguageService.tr('username_taken');
      case 'network-request-failed': return LanguageService.tr('error_network');
      case 'email-not-verified': return LanguageService.tr('email_not_verified');
      default: return code;
    }
  }

  // Логика отправки ссылки на сброс пароля
  void _handleForgotPassword() async {
    if (_formKeyForgot.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.sendPasswordResetEmail(_forgotEmailController.text.trim());
        _showSnackBar(LanguageService.tr('reset_link_sent'));
        setState(() => _showForgotPassword = false); // Возвращаемся к логину
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
        await _authService.signInWithIdentifier(
          _loginIdController.text.trim(),
          _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        _showSnackBar(_mapAuthError(e.code));
      } catch (e) {
        _showSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleEmailSignUp() async {
    if (_formKeyRegister.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _usernameController.text.trim(),
        );
        _showSnackBar(LanguageService.tr('verification_sent'));
      } on FirebaseAuthException catch (e) {
        _showSnackBar(_mapAuthError(e.code));
      } catch (e) {
        _showSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return LanguageService.tr('password_validation_error');
    
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (value.length < 8 || !hasUppercase || !hasDigits || !hasSpecialCharacters) {
      return LanguageService.tr('password_validation_error');
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.green.withOpacity(0.2) : Colors.green[100],
                  ),
                  child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.green),
                ),
                const SizedBox(height: 20),
                Text(LanguageService.tr('app_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                // Показываем TabBar только если не открыта форма восстановления
                if (!_showForgotPassword)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(25)),
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
                SizedBox(
                  height: 600,
                  child: _showForgotPassword 
                    ? _buildForgotPasswordForm(isDark) // Если нажали "Забыли пароль"
                    : TabBarView(
                        children: [
                          _buildLoginForm(isDark),
                          _buildRegisterForm(isDark),
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

  Widget _buildLoginForm(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKeyLogin,
        child: Column(
          children: [
            Text(LanguageService.tr('login_welcome'), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
            const SizedBox(height: 20),
            TextFormField(
              controller: _loginIdController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('login_id_hint'),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v!.isEmpty ? '?' : null,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(_passwordController),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _showForgotPassword = true), // Переключаем экран
                child: Text(LanguageService.tr('forgot_password'), style: const TextStyle(color: Colors.green)),
              ),
            ),
            const SizedBox(height: 16),
            _buildSubmitButton(LanguageService.tr('enter'), _handleEmailSignIn),
            _buildSocialDivider(),
            _buildGoogleButton(isDark),
          ],
        ),
      ),
    );
  }

  // НОВАЯ ФОРМА ВОССТАНОВЛЕНИЯ ПАРОЛЯ
  Widget _buildForgotPasswordForm(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKeyForgot,
        child: Column(
          children: [
            Text(
              LanguageService.tr('forgot_password_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              LanguageService.tr('forgot_password_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _forgotEmailController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('email_hint'),
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => !v!.contains('@') ? LanguageService.tr('invalid_email') : null,
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(LanguageService.tr('send'), _handleForgotPassword),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _showForgotPassword = false),
              child: Text(
                LanguageService.tr('back_to_login'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKeyRegister,
        child: Column(
          children: [
            Text(LanguageService.tr('register_welcome'), style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700])),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('username_hint'),
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v!.length < 3 ? 'Too short' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: LanguageService.tr('email_hint'),
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => !v!.contains('@') ? LanguageService.tr('invalid_email') : null,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(_passwordController),
            const SizedBox(height: 24),
            _buildSubmitButton(LanguageService.tr('submit'), _handleEmailSignUp),
            _buildSocialDivider(),
            _buildGoogleButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: LanguageService.tr('password_hint'),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: _validatePassword,
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return _isLoading
        ? const CircularProgressIndicator(color: Colors.green)
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(text),
          );
  }

  Widget _buildSocialDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("OR", style: TextStyle(color: Colors.grey))),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return ElevatedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: const Icon(Icons.login),
      label: Text(LanguageService.tr('login_google')),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}

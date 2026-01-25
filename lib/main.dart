import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/language_service.dart'; // Импорт сервиса
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'firebase_options.dart'; // Если используется

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Загружаем сохраненный язык перед запуском
  await LanguageService.loadLanguage();

  runApp(const SmartRecipeApp());
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Слушаем изменения языка
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, langCode, child) {
        return MaterialApp(
          // Ключ заставляет Flutter полностью перестроить дерево виджетов при смене языка
          key: ValueKey(langCode),
          title: 'Smart Recipe Generator',
          theme: ThemeData(
            primarySwatch: Colors.green,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.grey[50],
          ),
          home: const AuthGate(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/login': (context) => const LoginScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  // ... (остальной код AuthGate без изменений)
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
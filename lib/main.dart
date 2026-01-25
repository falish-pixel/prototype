// Файл: lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/language_service.dart';
import 'services/theme_service.dart'; // Убедитесь, что этот файл создан
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Загружаем настройки
  await LanguageService.loadLanguage();
  await ThemeService.loadTheme();

  runApp(const SmartRecipeApp());
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Слушаем изменения ЯЗЫКА
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, langCode, child) {
        // 2. Слушаем изменения ТЕМЫ
        return ValueListenableBuilder<bool>(
          valueListenable: ThemeService.isDarkMode,
          builder: (context, isDark, _) {
            return MaterialApp(
              key: ValueKey(langCode), // Перестройка при смене языка
              title: 'Smart Recipe Generator',

              // Логика переключения тем
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

              // --- СВЕТЛАЯ ТЕМА ---
              theme: ThemeData(
                primarySwatch: Colors.green,
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: Colors.grey[50],
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),

              // --- ТЕМНАЯ ТЕМА ---
              darkTheme: ThemeData(
                primarySwatch: Colors.green,
                useMaterial3: true,
                brightness: Brightness.dark,
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                cardColor: const Color(0xFF1E1E1E),
              ),

              home: const AuthGate(), // Здесь вызывается класс ниже
              routes: {
                '/home': (context) => const HomeScreen(),
                '/settings': (context) => const SettingsScreen(),
                '/login': (context) => const LoginScreen(),
                '/profile': (context) => const ProfileScreen(),
              },
            );
          },
        );
      },
    );
  }
}

// === ВОТ ЭТОТ КЛАСС БЫЛ ПОТЕРЯН ===
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // Ожидание соединения
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Если пользователь вошел -> Главный экран
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Если нет -> Экран входа
        return const LoginScreen();
      },
    );
  }
}
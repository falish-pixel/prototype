import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Импорт Core
import 'package:firebase_auth/firebase_auth.dart'; // Импорт Auth
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart'; // Импорт экрана входа

void main() async {
  // Обязательно для Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const SmartRecipeApp());
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Recipe Generator',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      // Убираем initialRoute, используем home с логикой проверки
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// Виджет, который решает, какой экран показать
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Если данные загружаются
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Если пользователь есть - пускаем на Главную
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Если нет - на Логин
        return const LoginScreen();
      },
    );
  }
}
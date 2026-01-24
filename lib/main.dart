import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';


void main() {
  runApp(const SmartRecipeApp());
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Recipe Generator',
      theme: ThemeData(
        // Используем зеленый цвет, так как проект про еду и здоровье
        primarySwatch: Colors.green,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      // Маршруты для навигации
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
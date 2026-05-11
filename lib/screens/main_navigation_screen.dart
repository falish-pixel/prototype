import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../services/language_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: LanguageService.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_rounded),
            label: LanguageService.tr('search'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_rounded),
            label: LanguageService.tr('my_recipes'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: LanguageService.tr('settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: LanguageService.tr('account'),
          ),
        ],
      ),
    );
  }
}



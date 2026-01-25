import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_detail_screen.dart';
import '../services/language_service.dart'; // Импорт сервиса

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
            child: Text(LanguageService.tr('login_subtitle')) // "Войдите..."
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // ПЕРЕВОД ЗАГОЛОВКА
        title: Text(LanguageService.tr('my_recipes')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('savedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  // ПЕРЕВОД ПУСТОГО ЭКРАНА
                  Text(
                      LanguageService.tr('no_favorites'),
                      style: const TextStyle(color: Colors.grey)
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final recipe = {
                'name': data['name'] ?? 'No Name',
                'time': data['time'] ?? '',
                'kcal': data['kcal'] ?? '',
                'ingredients': data['ingredients'] ?? [],
                'steps': data['steps'] ?? [],
              };

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(recipe['name']),
                  subtitle: Text("${recipe['time']} • ${recipe['kcal']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
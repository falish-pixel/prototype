import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'recipe_detail_screen.dart';
import '../services/language_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(body: Center(child: Text(LanguageService.tr('login_subtitle'))));
    }

    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.tr('my_recipes'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('favorites')
            .orderBy('savedAt', descending: true).snapshots(),
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
                  Text(LanguageService.tr('no_favorites'), style: const TextStyle(color: Colors.grey)),
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
                // === ДОБАВЛЯЕМ ЭТИ СТРОКИ ===
                'protein': data['protein'] ?? 0,
                'fats': data['fats'] ?? 0,
                'carbs': data['carbs'] ?? 0,
                // ============================
                'ingredients': data['ingredients'] ?? [],
                'steps': data['steps'] ?? [],
              };

              final String name = recipe['name'].toString();

              // Генерируем уникальный ID для картинки на основе названия
              final int lockId = name.hashCode;

              // ИСПОЛЬЗУЕМ LOREMFLICKR (Реальные фото еды)
              final imageUrl = 'https://loremflickr.com/320/240/food,dish?lock=$lockId';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 60, height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                          width: 60, height: 60,
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, color: Colors.grey)
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text("${recipe['time']} • ${recipe['kcal']}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(recipe: recipe),
                    ));
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
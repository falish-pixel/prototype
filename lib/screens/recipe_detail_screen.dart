import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe['name'] ?? 'Рецепт')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и калории
            Text(
              recipe['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey),
                const SizedBox(width: 4),
                Text(recipe['time'] ?? 'N/A'),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 4),
                Text(recipe['kcal'] ?? 'N/A'),
              ],
            ),
            const Divider(height: 30),

            // Ингредиенты
            const Text(
              "Ингредиенты:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate((recipe['ingredients'] as List).length, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recipe['ingredients'][index])),
                  ],
                ),
              );
            }),

            const Divider(height: 30),

            // Шаги приготовления
            const Text(
              "Инструкция:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate((recipe['steps'] as List).length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green[100],
                      child: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.green)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(recipe['steps'][index])),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
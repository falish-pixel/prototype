import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  final String ingredients;

  const RecipesScreen({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Рецепты")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Ингредиенты: $ingredients",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _RecipeCard(
                    title: "Фруктовый салат",
                    kcal: "250 ккал",
                    icon: Icons.emoji_nature,
                  ),
                  _RecipeCard(
                    title: "Шарлотка (Нужна мука)",
                    kcal: "400 ккал",
                    icon: Icons.cake,
                    isMissing: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final String title;
  final String kcal;
  final IconData icon;
  final bool isMissing;

  const _RecipeCard({
    required this.title,
    required this.kcal,
    required this.icon,
    this.isMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isMissing ? Colors.orange[100] : Colors.green[100],
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title),
        subtitle: Text(kcal),
        trailing: isMissing ? const Text("Купить", style: TextStyle(color: Colors.red)) : const Icon(Icons.arrow_forward),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isFavorite = false;
  bool isLoading = true; // Чтобы кнопка не мигала при загрузке
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Проверяем, есть ли этот рецепт уже в базе
  Future<void> _checkIfFavorite() async {
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .where('name', isEqualTo: widget.recipe['name']) // Ищем по названию
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        isFavorite = query.docs.isNotEmpty;
        isLoading = false;
      });
    }
  }

  // Добавляем или удаляем из избранного
  Future<void> _toggleFavorite() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Войдите, чтобы сохранять рецепты")));
      return;
    }

    setState(() => isFavorite = !isFavorite); // Сразу меняем визуально

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites');

    // Сначала ищем, есть ли рецепт (чтобы узнать его ID для удаления)
    final query = await collection
        .where('name', isEqualTo: widget.recipe['name'])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Если есть - удаляем
      await query.docs.first.reference.delete();
    } else {
      // Если нет - добавляем
      // Добавляем дату сохранения, чтобы потом сортировать
      final dataToSave = Map<String, dynamic>.from(widget.recipe);
      dataToSave['savedAt'] = FieldValue.serverTimestamp();

      await collection.add(dataToSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe['name'] ?? 'Рецепт'),
        actions: [
          // Кнопка избранного
          if (!isLoading)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и калории
            Text(
              widget.recipe['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.grey),
                const SizedBox(width: 4),
                Text(widget.recipe['time'] ?? 'N/A'),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 4),
                Text(widget.recipe['kcal'] ?? 'N/A'),
              ],
            ),
            const Divider(height: 30),

            // Ингредиенты
            const Text(
              "Ингредиенты:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Проверка на null и тип List
            if (widget.recipe['ingredients'] is List)
              ...List.generate((widget.recipe['ingredients'] as List).length,
                      (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                              child:
                              Text(widget.recipe['ingredients'][index] ?? '')),
                        ],
                      ),
                    );
                  }),

            const Divider(height: 30),

            // Шаги
            const Text(
              "Инструкция:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.recipe['steps'] is List)
              ...List.generate((widget.recipe['steps'] as List).length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.green[100],
                        child: Text("${index + 1}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(widget.recipe['steps'][index] ?? '')),
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
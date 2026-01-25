import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // Не забудь добавить этот импорт!

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isFavorite = false;
  bool isLoading = true;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Проверка избранного
  Future<void> _checkIfFavorite() async {
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .where('name', isEqualTo: widget.recipe['name'])
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        isFavorite = query.docs.isNotEmpty;
        isLoading = false;
      });
    }
  }

  // Переключение избранного
  Future<void> _toggleFavorite() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Войдите, чтобы сохранять рецепты")));
      return;
    }

    setState(() => isFavorite = !isFavorite);

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites');

    final query = await collection
        .where('name', isEqualTo: widget.recipe['name'])
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    } else {
      final dataToSave = Map<String, dynamic>.from(widget.recipe);
      dataToSave['savedAt'] = FieldValue.serverTimestamp();
      await collection.add(dataToSave);
    }
  }

  // --- НОВАЯ ФУНКЦИЯ: ОТКРЫТЬ YOUTUBE ---
  Future<void> _openYouTube() async {
    final recipeName = widget.recipe['name'];
    // Формируем поисковый запрос: "Рецепт [Название блюда]"
    final query = Uri.encodeComponent("рецепт $recipeName");
    final url = Uri.parse("https://www.youtube.com/results?search_query=$query");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Если не открылось, пробуем универсальный способ
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Не удалось открыть YouTube: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe['name'] ?? 'Рецепт'),
        actions: [
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
            // Название
            Text(
              widget.recipe['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Время и Ккал
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

            const SizedBox(height: 20),

            // --- КНОПКА YOUTUBE ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openYouTube,
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text("Смотреть видео-рецепт",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Фирменный цвет YouTube
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                    )
                ),
              ),
            ),
            const Divider(height: 30),

            // Ингредиенты
            const Text(
              "Ингредиенты:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.recipe['ingredients'] is List)
              ...List.generate((widget.recipe['ingredients'] as List).length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.recipe['ingredients'][index] ?? '')),
                    ],
                  ),
                );
              }),

            const Divider(height: 30),

            // Инструкция
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
                            style: const TextStyle(fontSize: 12, color: Colors.green)),
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
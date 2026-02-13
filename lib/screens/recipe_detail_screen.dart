import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/language_service.dart';
import '../services/calorie_service.dart'; // <--- Импорт сервиса калорий

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

  Future<void> _checkIfFavorite() async {
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('users').doc(user!.uid).collection('favorites')
        .where('name', isEqualTo: widget.recipe['name']).limit(1).get();
    if (mounted) {
      setState(() {
        isFavorite = query.docs.isNotEmpty;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LanguageService.tr('login_subtitle')))
      );
      return;
    }
    setState(() => isFavorite = !isFavorite);
    final collection = FirebaseFirestore.instance
        .collection('users').doc(user!.uid).collection('favorites');
    final query = await collection
        .where('name', isEqualTo: widget.recipe['name']).limit(1).get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    } else {
      final dataToSave = Map<String, dynamic>.from(widget.recipe);
      dataToSave['savedAt'] = FieldValue.serverTimestamp();
      await collection.add(dataToSave);
    }
  }

  Future<void> _addToCalorieTracker() async {
    // 1. Извлекаем строку с калориями, например "450 ккал"
    final String kcalString = widget.recipe['kcal']?.toString() ?? "0";

    // 2. Удаляем все НЕ цифры (оставляем только 450)
    final String cleanString = kcalString.replaceAll(RegExp(r'[^0-9]'), '');

    // 3. Преобразуем в число
    final int kcal = int.tryParse(cleanString) ?? 0;

    if (kcal > 0) {
      // 4. Добавляем через сервис
      await CalorieService.addCalories(kcal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LanguageService.tr('calories_added')), // "Калории добавлены!"
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            )
        );
        // Опционально: можно вернуться на главный экран
        // Navigator.pop(context);
      }
    }
  }

  Future<void> _openYouTube() async {
    final recipeName = widget.recipe['name'];
    final query = Uri.encodeComponent("рецепт $recipeName");
    final url = Uri.parse("https://www.youtube.com/results?search_query=$query");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.recipe['name'] ?? 'Food';
    final int lockId = name.hashCode;
    final imageUrl = 'https://loremflickr.com/320/240/food,dish?lock=$lockId';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontSize: 18)),
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Картинка с Hero эффектом (если бы он был в списке)
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.green[50],
                  child: const Center(child: CircularProgressIndicator())
              ),
              errorWidget: (context, url, error) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название
                  Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Инфо-панель (Время и Калории)
                  Row(
                    children: [
                      _buildInfoChip(Icons.timer_outlined, widget.recipe['time'] ?? 'N/A', Colors.blue),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.local_fire_department_rounded, widget.recipe['kcal'] ?? 'N/A', Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // КНОПКА "Я ПРИГОТОВИЛ ЭТО"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addToCalorieTracker,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(LanguageService.tr('cooked_this')), // "Я приготовил это"
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Кнопка YouTube
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openYouTube,
                      icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                      label: Text(
                          LanguageService.tr('video_recipe'),
                          style: const TextStyle(color: Colors.red)
                      ),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                  ),

                  const Divider(height: 40),

                  // Ингредиенты
                  Text(
                      LanguageService.tr('ingredients_title'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  if (widget.recipe['ingredients'] is List)
                    ...List.generate((widget.recipe['ingredients'] as List).length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle, size: 8, color: Colors.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(
                                  widget.recipe['ingredients'][index] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                )
                            ),
                          ],
                        ),
                      );
                    }),

                  const Divider(height: 40),

                  // Инструкция
                  Text(
                      LanguageService.tr('steps_title'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 16),
                  if (widget.recipe['steps'] is List)
                    ...List.generate((widget.recipe['steps'] as List).length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Text(
                                  widget.recipe['steps'][index] ?? '',
                                  style: const TextStyle(fontSize: 16, height: 1.4),
                                )
                            ),
                          ],
                        ),
                      );
                    }),

                  // Отступ внизу для удобства скролла
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный виджет для чипсов (время, ккал)
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
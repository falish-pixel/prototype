import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- Для открытия магазинов
import 'package:cached_network_image/cached_network_image.dart';
import '../services/language_service.dart';
import '../services/calorie_service.dart';
import '../services/user_service.dart'; // <--- Для начисления опыта (XP)

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

  // === ЛОГИКА: Я ПРИГОТОВИЛ (Калории + XP) ===
  Future<void> _addToCalorieTracker() async {
    final String kcalString = widget.recipe['kcal']?.toString() ?? "0";
    final String cleanString = kcalString.replaceAll(RegExp(r'[^0-9]'), '');
    final int kcal = int.tryParse(cleanString) ?? 0;

    if (kcal > 0) {
      // 1. Добавляем калории
      await CalorieService.addCalories(kcal);

      // 2. Добавляем XP (+50 за блюдо)
      final newLevel = await UserService.addXp(50);

      if (mounted) {
        String message = "${LanguageService.tr('name_saved')} (+50 XP)";

        if (newLevel > -1) {
          _showLevelUpDialog(newLevel);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              )
          );
        }
      }
    }
  }

  // === ЛОГИКА: ПОКУПКА ПРОДУКТОВ ===
  Future<void> _shopIngredients(String provider) async {
    final List ingredientsList = widget.recipe['ingredients'] ?? [];
    if (ingredientsList.isEmpty) return;

    // Берем первые 5 ингредиентов для поиска
    final String query = ingredientsList.take(5).join(" ");

    Uri? url;

    if (provider == 'kaspi') {
      // Ищем в Kaspi (добавляем Magnum для точности)
      url = Uri.parse("https://kaspi.kz/shop/search/?text=Magnum $query");
    } else if (provider == 'wolt') {
      // Ищем в Wolt
      url = Uri.parse("https://wolt.com/ru/kaz/search?q=$query");
    } else if (provider == 'yandex') {
      // Ищем в Яндекс Еде
      url = Uri.parse("https://eda.yandex.kz/search?query=$query");
    }

    if (url != null) {
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Не удалось открыть магазин: $e");
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
      }
    } catch (e) {
      debugPrint("Error launching YT: $e");
    }
  }

  void _showLevelUpDialog(int level) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green[50],
        title: const Column(children: [
          Icon(Icons.star, size: 50, color: Colors.orange),
          Text("LEVEL UP!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ]),
        content: Text("Поздравляем! Вы достигли уровня $level.", textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("КРУТО!", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.recipe['name'] ?? 'Food';
    // Исправленный генератор картинок (всегда положительный ID)
    final int lockId = (name.hashCode.abs() % 1000);
    final imageUrl = 'https://loremflickr.com/320/240/food,dish?lock=$lockId';

    // Парсим БЖУ
    final int protein = _parseInt(widget.recipe['protein']);
    final int fats = _parseInt(widget.recipe['fats']);
    final int carbs = _parseInt(widget.recipe['carbs']);
    final bool hasMacros = protein > 0 || fats > 0 || carbs > 0;

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
            // Картинка
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  height: 250, color: Colors.green.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(
                  height: 250, color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, size: 80, color: Colors.grey)),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Время и Калории
                  Row(
                    children: [
                      _buildInfoChip(Icons.timer_outlined, widget.recipe['time'] ?? 'N/A', Colors.blue),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.local_fire_department_rounded, widget.recipe['kcal'] ?? 'N/A', Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // БЖУ (Если есть)
                  if (hasMacros) ...[
                    Text(LanguageService.tr('macros'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _buildMacroNutrients(protein, fats, carbs),
                    const SizedBox(height: 24),
                  ],

                  // Кнопка "Я приготовил"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addToCalorieTracker,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text("Я приготовил это"), // Можно добавить в словарь
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      label: Text(LanguageService.tr('video_recipe'), style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                  ),

                  const Divider(height: 40),

                  // Ингредиенты
                  Text(LanguageService.tr('ingredients_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (widget.recipe['ingredients'] is List)
                    ...List.generate((widget.recipe['ingredients'] as List).length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(child: Text(widget.recipe['ingredients'][index] ?? '', style: const TextStyle(fontSize: 16))),
                          ],
                        ),
                      );
                    }),

                  // === НОВЫЙ БЛОК: КНОПКИ ПОКУПКИ ===
                  const SizedBox(height: 30),
                  const Text(LanguageService.tr('buy_product_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildShopButton("Magnum", Colors.red[700]!, Icons.shopping_cart, () => _shopIngredients('kaspi')),
                        const SizedBox(width: 10),
                        _buildShopButton("Wolt", Colors.blue, Icons.delivery_dining, () => _shopIngredients('wolt')),
                        const SizedBox(width: 10),
                        _buildShopButton("Yandex", Colors.amber[700]!, Icons.fastfood, () => _shopIngredients('yandex')),
                      ],
                    ),
                  ),
                  // ===================================

                  const Divider(height: 40),

                  // Инструкция
                  Text(LanguageService.tr('steps_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Center(child: Text("${index + 1}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Text(widget.recipe['steps'][index] ?? '', style: const TextStyle(fontSize: 16, height: 1.4))),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

  Widget _buildShopButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  Widget _buildMacroNutrients(int p, int f, int c) {
    int total = p + f + c;
    if (total == 0) total = 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem(LanguageService.tr('protein'), p, Colors.greenAccent[700]!, total),
          Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildMacroItem(LanguageService.tr('fats'), f, Colors.orangeAccent[700]!, total),
          Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
          _buildMacroItem(LanguageService.tr('carbs'), c, Colors.blueAccent[700]!, total),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, int value, Color color, int total) {
    double percentage = (value / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Text("$value${LanguageService.tr('g')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        SizedBox(
          width: 60, height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: percentage, backgroundColor: color.withValues(alpha: 0.2), color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return 0;
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
          const SnackBar(content: Text("Войдите, чтобы сохранять рецепты")));
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

  Future<void> _openYouTube() async {
    final recipeName = widget.recipe['name'];
    final query = Uri.encodeComponent("рецепт $recipeName");
    final url = Uri.parse("[https://www.youtube.com/results?search_query=$query](https://www.youtube.com/results?search_query=$query)");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.recipe['name'] ?? 'Food';
    final int lockId = name.hashCode;

    // ИСПОЛЬЗУЕМ LOREMFLICKR (Реальные фото еды высокого качества)
    final imageUrl = 'https://loremflickr.com/320/240/food,dish?lock=$lockId';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openYouTube,
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                      label: const Text("Смотреть видео-рецепт", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                    ),
                  ),
                  const Divider(height: 30),
                  const Text("Ингредиенты:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  const Text("Инструкция:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              child: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.green)),
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
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'recipe_detail_screen.dart';
import '../services/language_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> allRecipes = [];
  List<DocumentSnapshot> filteredRecipes = [];
  String selectedCategory = 'all';
  double maxCalories = 2000;
  int maxTime = 120;
  bool isLoading = true;

  final List<String> categories = ['all', 'breakfast', 'lunch', 'dinner', 'dessert', 'snack', 'vegan'];

  @override
  void initState() {
    super.initState();
    _fetchAllRecipes();
  }

  Future<void> _fetchAllRecipes() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
      if (mounted) {
        setState(() {
          allRecipes = snapshot.docs;
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching recipes: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredRecipes = allRecipes.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Filter by category
        if (selectedCategory != 'all') {
          final category = data['category']?.toString().toLowerCase() ?? '';
          final tags = List<String>.from(data['tags'] ?? []).map((t) => t.toLowerCase()).toList();
          
          if (selectedCategory == 'vegan') {
             if (data['isVegan'] != true && !tags.contains('vegan')) return false;
          } else if (category != selectedCategory && !tags.contains(selectedCategory)) {
            return false;
          }
        }

        // Filter by calories
        final kcal = _parseInt(data['kcal']);
        if (kcal > maxCalories) return false;

        // Filter by time
        final time = _parseInt(data['time']);
        if (time > maxTime) return false;

        // Filter by search query
        if (query.isNotEmpty) {
          final name = (data['name'] ?? '').toString().toLowerCase();
          final ingredients = (data['ingredients'] as List? ?? []).join(' ').toLowerCase();
          return name.contains(query) || ingredients.contains(query);
        }
        
        return true;
      }).toList();
    });
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: LanguageService.tr('search'),
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (_) => _applyFilters(),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _applyFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildAdvancedFilters(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRecipes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: filteredRecipes.length,
                        itemBuilder: (context, index) {
                          final doc = filteredRecipes[index];
                          final recipe = doc.data() as Map<String, dynamic>;
                          recipe['id'] = doc.id;
                          final imageUrl = recipe['imageUrl'] ?? "";

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: 60, height: 60, fit: BoxFit.cover,
                                        memCacheWidth: 120, memCacheHeight: 120,
                                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                                        errorWidget: (context, url, error) => const Icon(Icons.restaurant, color: Colors.green),
                                      )
                                    : Container(
                                        width: 60, height: 60, color: Colors.grey[200],
                                        child: const Icon(Icons.restaurant, color: Colors.green),
                                      ),
                              ),
                              title: Text(
                                recipe['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("${recipe['time'] ?? '??'} ${LanguageService.tr('min')} • ${recipe['kcal'] ?? '??'} ${LanguageService.tr('kcal')}"),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(LanguageService.tr(category)),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  selectedCategory = category;
                  _applyFilters();
                });
              },
              selectedColor: Colors.green.withOpacity(0.2),
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: maxTime.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: "$maxTime ${LanguageService.tr('min')}",
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      maxTime = value.toInt();
                    });
                    _applyFilters();
                  },
                ),
              ),
              Text("$maxTime ${LanguageService.tr('min')}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.local_fire_department_outlined, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: maxCalories,
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  label: "$maxCalories ${LanguageService.tr('kcal')}",
                  activeColor: Colors.orange,
                  onChanged: (value) {
                    setState(() {
                      maxCalories = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
              Text("${maxCalories.toInt()} ${LanguageService.tr('kcal')}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            LanguageService.tr('no_results'),
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

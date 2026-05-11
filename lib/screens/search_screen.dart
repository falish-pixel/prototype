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
  bool isGlutenFree = false;
  bool isLactoseFree = false;

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
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      filteredRecipes = allRecipes.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Извлекаем все текстовые данные для поиска внутри них
        final String name = (data['name'] ?? '').toString().toLowerCase();
        final List tags = (data['tags'] is List) ? data['tags'] : [];
        final String tagsString = tags.join(' ').toLowerCase();
        final List ingredients = (data['ingredients'] is List) ? data['ingredients'] : [];
        final String ingredientsString = ingredients.join(' ').toLowerCase();
        final String categoryField = (data['category'] ?? '').toString().toLowerCase();

        // Объединяем всё в одну строку для "умного" поиска
        final String fullSearchContent = "$name $tagsString $ingredientsString $categoryField";

        // === 1. ФИЛЬТР ПО КАТЕГОРИИ ===
        if (selectedCategory != 'all') {
          // Синонимы для поиска
          final Map<String, List<String>> keywords = {
            'breakfast': ['завтрак', 'breakfast', 'таңғы ас', 'яичница', 'каша', 'блины', 'сырники'],
            'lunch': ['обед', 'lunch', 'түскі ас', 'суп', 'второе', 'борщ'],
            'dinner': ['ужин', 'dinner', 'кешкі ас', 'салат', 'паста'],
            'dessert': ['десерт', 'сладкое', 'торт', 'пирог', 'dessert', 'тәтті', 'печенье'],
            'snack': ['перекус', 'закуска', 'snack', 'тіскебасар', 'бутерброд', 'сэндвич'],
            'vegan': ['веган', 'vegan', 'постн'],
          };

          final List<String> searchWords = keywords[selectedCategory] ?? [selectedCategory];
          if (!searchWords.any((word) => fullSearchContent.contains(word))) {
            return false;
          }
        }

        // === 2. ФИЛЬТР ПО КАЛОРИЯМ ===
        if (maxCalories < 2000) {
          final kcal = _parseInt(data['kcal']);
          if (kcal > 0 && kcal > maxCalories) return false;
        }

        // === 3. ФИЛЬТР ПО ВРЕМЕНИ ===
        if (maxTime < 120) {
          final time = _parseInt(data['time']);
          if (time > 0 && time > maxTime) return false;
        }

        // === 4. ДИЕТИЧЕСКИЕ ФИЛЬТРЫ (Умное исключение) ===
        if (isGlutenFree) {
          // Разрешающие теги
          bool hasGlutenTag = ['без глютена', 'gluten-free', 'глютенсіз'].any((word) => fullSearchContent.contains(word));
          // Запрещенные ингредиенты (все, что содержит глютен)
          bool hasGlutenIngredients = ['мука', 'хлеб', 'макарон', 'тесто', 'пшенич', 'лаваш', 'булоч', 'батон'].any((word) => fullSearchContent.contains(word));

          if (!hasGlutenTag && hasGlutenIngredients) return false;
        }

        if (isLactoseFree) {
          // Разрешающие теги
          bool hasLactoseTag = ['без лактозы', 'lactose-free', 'лактозасыз'].any((word) => fullSearchContent.contains(word));
          // Запрещенные ингредиенты (молочка)
          bool hasLactoseIngredients = ['молоко', 'сыр', 'сливки', 'сметана', 'масло сливочное', 'творог', 'йогурт', 'кефир'].any((word) => fullSearchContent.contains(word));

          if (!hasLactoseTag && hasLactoseIngredients) return false;
        }

        // === 5. ПОИСКОВЫЙ ЗАПРОС ИЗ СТРОКИ ПОИСКА ===
        if (query.isNotEmpty) {
          if (!name.contains(query) && !ingredientsString.contains(query)) return false;
        }

        return true;
      }).toList();
    });
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      String s = value.toLowerCase();
      if (s.contains('ч')) return 121; // Если больше часа, пропускаем через фильтр (считаем за максимум)
      return int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return 0;
  }

  bool get _areFiltersActive => maxCalories < 2000 || maxTime < 120 || isGlutenFree || isLactoseFree;

  void _showFilterBottomSheet() {
    double tempCalories = maxCalories;
    int tempTime = maxTime;
    bool tempGlutenFree = isGlutenFree;
    bool tempLactoseFree = isLactoseFree;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text(LanguageService.tr('filters'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.grey),
                      Text("${LanguageService.tr('max_time')}: $tempTime ${LanguageService.tr('min')}"),
                    ],
                  ),
                  Slider(
                    value: tempTime.toDouble(),
                    min: 5, max: 120, divisions: 23,
                    activeColor: Colors.green,
                    onChanged: (val) => setModalState(() => tempTime = val.toInt()),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.local_fire_department_outlined, color: Colors.orange),
                      Text("${LanguageService.tr('max_kcal')}: ${tempCalories.toInt()}"),
                    ],
                  ),
                  Slider(
                    value: tempCalories,
                    min: 50, max: 2000, divisions: 39,
                    activeColor: Colors.orange,
                    onChanged: (val) => setModalState(() => tempCalories = val),
                  ),

                  const SizedBox(height: 10),
                  Text(LanguageService.tr('dietary'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: [
                      FilterChip(
                        label: Text(LanguageService.tr('gluten_free')),
                        selected: tempGlutenFree,
                        onSelected: (val) => setModalState(() => tempGlutenFree = val),
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                      ),
                      FilterChip(
                        label: Text(LanguageService.tr('lactose_free')),
                        selected: tempLactoseFree,
                        onSelected: (val) => setModalState(() => tempLactoseFree = val),
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setModalState(() {
                            tempCalories = 2000; tempTime = 120;
                            tempGlutenFree = false; tempLactoseFree = false;
                          }),
                          child: Text(LanguageService.tr('reset')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              maxCalories = tempCalories; maxTime = tempTime;
                              isGlutenFree = tempGlutenFree; isLactoseFree = tempLactoseFree;
                            });
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: Text(LanguageService.tr('apply')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilters(),
                      decoration: InputDecoration(
                        hintText: LanguageService.tr('search'),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () { _searchController.clear(); _applyFilters(); })
                            : null,
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                        child: IconButton(
                          icon: const Icon(Icons.tune_rounded),
                          color: _areFiltersActive ? Colors.green : (isDark ? Colors.white : Colors.black87),
                          onPressed: _showFilterBottomSheet,
                        ),
                      ),
                      if (_areFiltersActive)
                        Positioned(right: 8, top: 8, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
                    ],
                  ),
                ],
              ),
            ),
            _buildCategoryFilter(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRecipes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredRecipes.length,
                itemBuilder: (context, index) {
                  final doc = filteredRecipes[index];
                  final recipe = doc.data() as Map<String, dynamic>;
                  recipe['id'] = doc.id;

                  // Получаем имя для хэша картинки-заглушки
                  final name = recipe['name']?.toString() ?? 'Food';
                  // Генерируем красивую заглушку, если картинки в базе нет
                  final imageUrl = recipe['imageUrl'] ?? 'https://loremflickr.com/320/240/food,dish?lock=${name.hashCode.abs() % 1000}';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe))),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 100, height: 100,
                              child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 200, memCacheHeight: 200,
                                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                                  errorWidget: (context, url, error) => const Icon(Icons.restaurant, color: Colors.green)
                              )
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("${recipe['time'] ?? '??'} ${LanguageService.tr('min')}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text("${recipe['kcal'] ?? '??'} ${LanguageService.tr('kcal')}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(LanguageService.tr(cat)),
              selected: isSelected,
              onSelected: (val) { setState(() => selectedCategory = cat); _applyFilters(); },
              selectedColor: Colors.green,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(LanguageService.tr('no_results'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(LanguageService.tr('no_results_desc'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recipe_detail_screen.dart';
import '../services/language_service.dart'; // Импорт сервиса языков

class AiRecipesScreen extends StatefulWidget {
  final String? imagePath;
  final String? ingredientsInput;

  const AiRecipesScreen({
    super.key,
    this.imagePath,
    this.ingredientsInput
  });

  @override
  State<AiRecipesScreen> createState() => _AiRecipesScreenState();
}

class _AiRecipesScreenState extends State<AiRecipesScreen> {
  // ⚠️ API KEY (лучше хранить в .env)
  final String apiKey = '123456789';

  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  String? errorMessage;

  // Текущий список продуктов
  String _currentIngredients = "";

  @override
  void initState() {
    super.initState();
    if (widget.ingredientsInput != null) {
      _currentIngredients = widget.ingredientsInput!;
    }
    _generateRecipes(isInitial: true);
  }

  Future<void> _generateRecipes({bool isInitial = false}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      bool glutenFree = prefs.getBool('glutenFree') ?? false;
      bool lactoseFree = prefs.getBool('lactoseFree') ?? false;
      bool nutAllergy = prefs.getBool('nutAllergy') ?? false;

      List<String> restrictions = [];
      if (glutenFree) restrictions.add("БЕЗ ГЛЮТЕНА/GLUTEN FREE");
      if (lactoseFree) restrictions.add("БЕЗ ЛАКТОЗЫ/LACTOSE FREE");
      if (nutAllergy) restrictions.add("БЕЗ ОРЕХОВ/NUT FREE");

      String restrictionText = restrictions.isEmpty
          ? ""
          : "УЧТИ ОГРАНИЧЕНИЯ: ${restrictions.join(", ")}.";

      // !!! ПОЛУЧАЕМ ИНСТРУКЦИЮ ЯЗЫКА !!!
      String langInstruction = LanguageService.tr('prompt_lang');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final structurePrompt = '''
      Ответ верни СТРОГО в формате JSON объекта (без markdown ```json).
      Структура ответа:
      {
        "detected_ingredients": ["продукт 1", "продукт 2"], 
        "recipes": [
           {
             "name": "Название",
             "time": "Время",
             "kcal": "Ккал",
             "ingredients": ["список", "продуктов"],
             "steps": ["шаг 1", "шаг 2"]
           }
        ]
      }
      ''';

      GenerateContentResponse response;

      if (isInitial && widget.imagePath != null) {
        // --- ФОТО ---
        final imageBytes = await File(widget.imagePath!).readAsBytes();
        final prompt = '''
        Посмотри на это фото. Составь список ВСЕХ увиденных съедобных продуктов.
        $restrictionText
        $langInstruction
        На основе этих продуктов предложи 3 рецепта.
        $structurePrompt
        ''';

        response = await model.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
        ]);
      } else {
        // --- ТЕКСТ ---
        final prompt = '''
        Я буду готовить из следующих продуктов: $_currentIngredients.
        $restrictionText
        $langInstruction
        Предложи 3 рецепта строго из этого списка.
        В поле "detected_ingredients" верни список продуктов на том же языке.
        $structurePrompt
        ''';

        response = await model.generateContent([Content.text(prompt)]);
      }

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        int startIndex = cleanJson.indexOf('{');
        int endIndex = cleanJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        final data = jsonDecode(cleanJson);

        List<dynamic> rawIngredients = data['detected_ingredients'] ?? [];
        List<String> newIngredientsList = rawIngredients.map((e) => e.toString()).toList();

        List<dynamic> rawRecipes = data['recipes'] ?? [];
        List<Map<String, dynamic>> newRecipes = List<Map<String, dynamic>>.from(rawRecipes);

        if (mounted) {
          setState(() {
            // Если анализировали фото, обновляем список продуктов
            if (isInitial && widget.imagePath != null) {
              _currentIngredients = newIngredientsList.join(", ");
            }
            recipes = newRecipes;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Empty response");
      }
    } catch (e) {
      print("Ошибка: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Error: $e";
        });
      }
    }
  }

  void _showEditDialog() {
    final TextEditingController controller = TextEditingController(text: _currentIngredients);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LanguageService.tr('products_label')), // "Продукты:"
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"), // Можно добавить в словарь 'cancel'
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentIngredients = controller.text;
                });
                _generateRecipes(isInitial: false);
              },
              child: Text(LanguageService.tr('update')), // "Обновить"
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.tr('results_title'))), // "Результат"
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                if (widget.imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(widget.imagePath!), fit: BoxFit.cover),
                      ),
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentIngredients.isEmpty
                            ? "..."
                            : "${LanguageService.tr('products_label')} $_currentIngredients",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: _showEditDialog,
                      tooltip: LanguageService.tr('edit'), // "Изменить"
                    )
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? _buildLoading()
                : errorMessage != null
                ? _buildError()
                : _buildRecipeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.green),
          const SizedBox(height: 20),
          Text(LanguageService.tr('chef_thinking'), style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(errorMessage ?? "Error"),
            ElevatedButton(
                onPressed: () => _generateRecipes(isInitial: false),
                child: const Text("Retry")
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    if (recipes.isEmpty) {
      return const Center(child: Text("No recipes found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 15),
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu, color: Colors.green),
            title: Text(recipe['name'] ?? ''),
            subtitle: Text("${recipe['time']} • ${recipe['kcal']}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    );
  }
}
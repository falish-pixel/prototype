import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recipe_detail_screen.dart';

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
  // ⚠️ РЕКОМЕНДАЦИЯ: Храни API ключ в .env или Remote Config
  final String apiKey = '123456789';

  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  String? errorMessage;

  // Здесь мы храним текущий список продуктов (от AI или от пользователя)
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
      if (glutenFree) restrictions.add("БЕЗ ГЛЮТЕНА");
      if (lactoseFree) restrictions.add("БЕЗ ЛАКТОЗЫ");
      if (nutAllergy) restrictions.add("БЕЗ ОРЕХОВ");

      String restrictionText = restrictions.isEmpty
          ? ""
          : "УЧТИ ОГРАНИЧЕНИЯ: ${restrictions.join(", ")}.";

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      // !!! ГЛАВНОЕ ИЗМЕНЕНИЕ: Просим вернуть и ингредиенты, и рецепты !!!
      final structurePrompt = '''
      Ответ верни СТРОГО в формате JSON объекта (без markdown ```json).
      Структура ответа должна быть такой:
      {
        "detected_ingredients": ["продукт 1", "продукт 2"], 
        "recipes": [
           {
             "name": "Название блюда",
             "time": "Время",
             "kcal": "Ккал",
             "ingredients": ["список", "продуктов"],
             "steps": ["шаг 1", "шаг 2"]
           }
        ]
      }
      ''';

      GenerateContentResponse response;

      // Логика:
      // 1. Если это первый запуск И есть фото -> отправляем фото, чтобы AI сам нашел продукты.
      // 2. Если пользователь уже отредактировал список (_currentIngredients не пуст и это не первый авто-анализ) -> отправляем только текст.

      if (isInitial && widget.imagePath != null) {
        // --- ПЕРВИЧНЫЙ АНАЛИЗ ФОТО ---
        final imageBytes = await File(widget.imagePath!).readAsBytes();
        final prompt = '''
        Посмотри на это фото. Составь список ВСЕХ увиденных съедобных продуктов.
        $restrictionText
        На основе этих продуктов предложи 3 рецепта.
        $structurePrompt
        ''';

        response = await model.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])
        ]);
      } else {
        // --- ПОИСК ПО ТЕКСТОВОМУ СПИСКУ (ПОСЛЕ РЕДАКТИРОВАНИЯ) ---
        final prompt = '''
        Я буду готовить из следующих продуктов: $_currentIngredients.
        $restrictionText
        Предложи 3 рецепта строго из этого списка (можно добавить базовые специи/масло/воду).
        В поле "detected_ingredients" просто верни мой список продуктов обратно.
        $structurePrompt
        ''';

        response = await model.generateContent([Content.text(prompt)]);
      }

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // Очистка от мусора до и после JSON
        int startIndex = cleanJson.indexOf('{');
        int endIndex = cleanJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        final data = jsonDecode(cleanJson);

        // 1. Достаем список продуктов
        List<dynamic> rawIngredients = data['detected_ingredients'] ?? [];
        List<String> newIngredientsList = rawIngredients.map((e) => e.toString()).toList();

        // 2. Достаем рецепты
        List<dynamic> rawRecipes = data['recipes'] ?? [];
        List<Map<String, dynamic>> newRecipes = List<Map<String, dynamic>>.from(rawRecipes);

        if (mounted) {
          setState(() {
            // Если это был анализ фото, обновляем наш список тем, что увидел AI
            if (isInitial && widget.imagePath != null) {
              _currentIngredients = newIngredientsList.join(", ");
            }
            recipes = newRecipes;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Пустой ответ от AI");
      }
    } catch (e) {
      print("Ошибка: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Ошибка: $e";
        });
      }
    }
  }

  // Диалог теперь показывает текущие продукты
  void _showEditDialog() {
    // Вставляем текущий список в поле ввода
    final TextEditingController controller = TextEditingController(text: _currentIngredients);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Продукты"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("AI увидел это. Отредактируйте список:", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Список продуктов",
                ),
                maxLines: 4, // Побольше места
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentIngredients = controller.text; // Сохраняем правки пользователя
                });
                // Запускаем поиск заново, но теперь isInitial = false,
                // чтобы использовать текст пользователя, а не анализировать фото снова
                _generateRecipes(isInitial: false);
              },
              child: const Text("Обновить"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Результат")),
      body: Column(
        children: [
          // Блок с фото и списком
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

                // Показываем, какие продукты мы сейчас используем
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentIngredients.isEmpty
                            ? "Определяю продукты..."
                            : "Продукты: $_currentIngredients",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: _showEditDialog,
                      tooltip: "Изменить состав",
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
        children: const [
          CircularProgressIndicator(color: Colors.green),
          SizedBox(height: 20),
          Text("Шеф думает...", style: TextStyle(color: Colors.grey)),
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
            Text(errorMessage ?? "Ошибка"),
            ElevatedButton(
                onPressed: () => _generateRecipes(isInitial: false),
                child: const Text("Повторить")
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
    if (recipes.isEmpty) {
      return const Center(child: Text("Не удалось найти рецепты из этих продуктов"));
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
            title: Text(recipe['name'] ?? 'Без названия'),
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
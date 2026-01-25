import 'dart:convert';
import 'dart:io'; // Для чтения файла
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recipe_detail_screen.dart';

class AiRecipesScreen extends StatefulWidget {
  // Теперь принимаем путь к картинке вместо строки ингредиентов
  final String imagePath;

  const AiRecipesScreen({super.key, required this.imagePath});

  @override
  State<AiRecipesScreen> createState() => _AiRecipesScreenState();
}

class _AiRecipesScreenState extends State<AiRecipesScreen> {
  final String apiKey = '123456789';

  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  String? errorMessage;
  String recognizedIngredients = ""; // Чтобы показать, что AI увидел

  @override
  void initState() {
    super.initState();
    _generateRecipesFromImage();
  }

  Future<void> _generateRecipesFromImage() async {
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

      // !!! Загружаем картинку в байты !!!
      final imageBytes = await File(widget.imagePath).readAsBytes();

      final model = GenerativeModel(
        model: 'gemini-2.5-flash', // Flash отлично работает с картинками
        apiKey: apiKey,
      );

      final prompt = '''
      Посмотри на это фото. Определи, какие продукты здесь есть.
      $restrictionText
      
      На основе увиденных продуктов предложи 3 рецепта.
      
      Ответ верни СТРОГО в формате JSON списка (без markdown ```json).
      Структура:
      {
        "name": "Название блюда",
        "time": "Время",
        "kcal": "Ккал",
        "ingredients": ["список", "продуктов"],
        "steps": ["шаг 1", "шаг 2"]
      }
      ''';

      // Отправляем Мультимодальный запрос (Текст + Картинка)
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes), // Передаем байты картинки
        ])
      ];

      final response = await model.generateContent(content);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // Попробуем найти начало JSON массива, если Gemini написал вступление
        int startIndex = cleanJson.indexOf('[');
        int endIndex = cleanJson.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        List<dynamic> jsonList = jsonDecode(cleanJson);

        if (mounted) {
          setState(() {
            recipes = List<Map<String, dynamic>>.from(jsonList);
            // Можно добавить логику, чтобы вытащить названия увиденных продуктов, но пока просто покажем рецепты
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
          errorMessage = "Ошибка анализа фото: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Анализ фото...")),
      body: Column(
        children: [
          // Показываем миниатюру фото, которое сделал пользователь
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.black,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
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
          Text("Изучаю содержимое холодильника...", style: TextStyle(color: Colors.grey)),
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
                onPressed: _generateRecipesFromImage,
                child: const Text("Повторить")
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList() {
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
            title: Text(recipe['name']),
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
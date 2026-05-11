import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recipe_detail_screen.dart';
import '../services/language_service.dart';
import '../services/ingredient_service.dart';

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
  final String apiKey = 'AIzaSyANmbsTSLyDDtb6uK43mGy4sfb1NeMU5gM';

  List<Map<String, dynamic>> recipes = [];
  bool isLoading = true;
  String? errorMessage;
  String _currentIngredients = "";

  late CameraController controller;
  late FlutterVision vision;
  List<Map<String, dynamic>> yoloResults = [];
  bool isLoaded = false;
  bool isDetecting = false;
  bool showCamera = false;
  Set<String> detectedTags = {};

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    
    if (widget.ingredientsInput != null) {
      _currentIngredients = widget.ingredientsInput!;
      _generateRecipes(isInitial: true);
    } else if (widget.imagePath != null) {
      // Если передано фото, сначала распознаем его локально
      _processStaticImage();
    } else {
      _initCameraAndVision();
    }
  }

  // --- ЛОГИКА ДЛЯ СТАТИЧЕСКОГО ФОТО (ИЗ ГАЛЕРЕИ ИЛИ ПОСЛЕ ФОТО) ---
  Future<void> _processStaticImage() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Загружаем модель, если еще не загружена
      await vision.loadYoloModel(
        modelPath: 'assets/best.tflite',
        labels: 'assets/labels.txt',
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: true,
      );

      // Читаем байты изображения и получаем его размеры
      final Uint8List bytes = await File(widget.imagePath!).readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      // Распознаем продукты на фото локально!
      final result = await vision.yoloOnImage(
        bytesList: bytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.3, // Чуть ниже порог для статичных фото
        classThreshold: 0.5,
      );

      if (result.isNotEmpty) {
        Set<String> localTags = result.map((e) => e['tag'].toString()).toSet();
        _currentIngredients = localTags.map((tag) => IngredientService.translate(tag)).join(", ");
      } else {
        // Если ничего не нашли, оставим пустым или попросим Gemini найти
        _currentIngredients = "";
      }

      // Теперь идем в Gemini за рецептами
      await _generateRecipes(isInitial: true);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error analyzing image: $e";
      });
    }
  }

  // --- ЛОГИКА КАМЕРЫ В РЕАЛЬНОМ ВРЕМЕНИ ---
  Future<void> _initCameraAndVision() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    controller = CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await controller.initialize();

    await vision.loadYoloModel(
      modelPath: 'assets/best.tflite',
      labels: 'assets/labels.txt',
      modelVersion: "yolov8",
      numThreads: 2,
      useGpu: true,
    );

    setState(() {
      isLoaded = true;
      showCamera = true;
      isLoading = false;
    });
  }

  Future<void> _startDetection() async {
    if (!controller.value.isStreamingImages) {
      await controller.startImageStream((image) {
        if (!isDetecting) {
          _yoloOnFrame(image);
        }
      });
    }
  }

  Future<void> _yoloOnFrame(CameraImage image) async {
    isDetecting = true;
    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
        for (var res in result) {
          detectedTags.add(res['tag']);
        }
      });
    }
    isDetecting = false;
  }

  Future<void> _stopDetection() async {
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    setState(() {
      yoloResults.clear();
      showCamera = false;
      isLoading = true;
      _currentIngredients = detectedTags.map((tag) => IngredientService.translate(tag)).join(", ");
    });
    
    _generateRecipes(isInitial: false);
  }

  @override
  void dispose() {
    if (showCamera) {
      controller.dispose();
      vision.closeYoloModel();
    }
    super.dispose();
  }

  // --- ГЕНЕРАЦИЯ РЕЦЕПТОВ ЧЕРЕЗ GEMINI ---
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
      bool isVegan = prefs.getBool('isVegan') ?? false;
      bool isVegetarian = prefs.getBool('isVegetarian') ?? false;

      List<String> restrictions = [];
      if (glutenFree) restrictions.add("БЕЗ ГЛЮТЕНА/GLUTEN FREE");
      if (lactoseFree) restrictions.add("БЕЗ ЛАКТОЗЫ/LACTOSE FREE");
      if (nutAllergy) restrictions.add("БЕЗ ОРЕХОВ/NUT FREE");

      String dietText = "";
      if (isVegan) {
        dietText = LanguageService.tr('prompt_vegan');
      } else if (isVegetarian) {
        dietText = LanguageService.tr('prompt_vegetarian');
      }

      String restrictionText = restrictions.isEmpty
          ? dietText
          : "$dietText УЧТИ ДОПОЛНИТЕЛЬНЫЕ ОГРАНИЧЕНИЯ: ${restrictions.join(", ")}.";
      String langInstruction = LanguageService.tr('prompt_lang');

      // Используем gemini-2.0-flash по требованию пользователя
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final structurePrompt = '''
      Ответ верни СТРОГО в формате JSON объекта (без markdown ```json).
      Убедись, что поля protein, fats, carbs содержат ТОЛЬКО ЧИСЛА (пример: 20, а не "20г").
      ВАЖНО: Поле "detected_ingredients" заполни названиями продуктов на том языке, на котором даешь ответ.
      Структура ответа:
      {
        "detected_ingredients": ["продукт 1", "продукт 2"], 
        "recipes": [
           {
             "name": "Название блюда",
             "time": "Время (например: 30 мин)",
             "kcal": "Ккал (например: 400 ккал)",
             "protein": 20,
             "fats": 15,
             "carbs": 50,
             "ingredients": ["список", "продуктов"],
             "steps": ["шаг 1", "шаг 2"]
           }
        ]
      }
      ''';

      // ТЕПЕРЬ МЫ ВСЕГДА ОТПРАВЛЯЕМ ТЕКСТ, ТАК КАК ПРОДУКТЫ УЖЕ НАШЛА YOLO
      final prompt = '''
      Список найденных продуктов: $_currentIngredients.
      $langInstruction
      Переведи названия этих продуктов и верни их в поле "detected_ingredients".
      Если список пуст, попробуй определить продукты сам по контексту "кухня".
      $restrictionText
      Предложи 6 рецепта.
      $structurePrompt
      ''';

      final response = await model.generateContent([Content.text(prompt)]);

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
            // Если YOLO ничего не нашла, берем то, что нашел Gemini
            if (_currentIngredients.isEmpty) {
              _currentIngredients = newIngredientsList.join(", ");
            }
            recipes = newRecipes;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Empty response from AI");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Error: $e";
        });
      }
    }
  }

  void _showEditDialog() {
    final TextEditingController editController = TextEditingController(text: _currentIngredients);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LanguageService.tr('dialog_add_edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  LanguageService.tr('dialog_hint'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LanguageService.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentIngredients = editController.text;
                });
                _generateRecipes(isInitial: false);
              },
              child: Text(LanguageService.tr('update_recipes')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showCamera) {
      return _buildCameraView();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr('results_title')),
      ),
      body: SingleChildScrollView( // ДОБАВЛЕНО для предотвращения Bottom Overflow
        child: Column(
          children: [
            // Верхняя панель: Фото и Список
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.green.withOpacity(0.15) : Colors.green[50],
              child: Column(
                children: [
                  if (widget.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(widget.imagePath!), fit: BoxFit.contain),
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentIngredients.isEmpty
                              ? LanguageService.tr('chef_thinking')
                              : "${LanguageService.tr('products_label')} $_currentIngredients",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: _showEditDialog,
                        tooltip: LanguageService.tr('edit'),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Список рецептов (используем ListView напрямую)
            isLoading
                ? Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: _buildLoading(),
                  )
                : errorMessage != null
                ? _buildError()
                : _buildRecipeList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (!isLoaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _startDetection();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          CustomPaint(
            painter: YoloPainter(
              yoloResults,
              controller.value.previewSize!,
              MediaQuery.of(context).size,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (detectedTags.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${LanguageService.tr('products_label')} ${detectedTags.map((tag) => IngredientService.translate(tag)).join(", ")}",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: () => Navigator.pop(context),
                      heroTag: "cancel",
                      label: Text(LanguageService.tr('cancel')),
                      icon: const Icon(Icons.close),
                      backgroundColor: Colors.redAccent,
                    ),
                    FloatingActionButton.extended(
                      onPressed: _stopDetection,
                      heroTag: "generate",
                      label: Text(LanguageService.tr('search')),
                      icon: const Icon(Icons.auto_awesome),
                      backgroundColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
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
          Text(
              LanguageService.tr('chef_thinking'),
              style: const TextStyle(color: Colors.grey)
          ),
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
            Text(errorMessage ?? "Error", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () => _generateRecipes(isInitial: false),
                child: Text(LanguageService.tr('retry'))
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
      shrinkWrap: true, // Важно внутри SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(),
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

class YoloPainter extends CustomPainter {
  final List<Map<String, dynamic>> results;
  final Size previewSize;
  final Size screenSize;

  YoloPainter(this.results, this.previewSize, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    double widthRatio = screenSize.width / previewSize.height;
    double heightRatio = screenSize.height / previewSize.width;

    for (var result in results) {
      final box = result['box'];
      final double left = box[0] * widthRatio;
      final double top = box[1] * heightRatio;
      final double right = box[2] * widthRatio;
      final double bottom = box[3] * heightRatio;

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);

      textPainter.text = TextSpan(
        text: "${IngredientService.translate(result['tag'])} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left, top - 20));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

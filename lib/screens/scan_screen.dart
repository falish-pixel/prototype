import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final String apiKey = 'AIzaSyDsKxiLk34XzwwTBrIBy-nZpgGbD9G9zRc';

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

  // --- ГЕНЕРАЦИЯ РЕЦЕПТОВ ЧЕРЕЗ GEMINI (ФИЛЬТР БАЗЫ ДАННЫХ) ---
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

      // 1. ПОЛУЧАЕМ ВСЕ РЕЦЕПТЫ ИЗ FIRESTORE (или кеша)
      final QuerySnapshot recipesSnapshot = await FirebaseFirestore.instance.collection('recipes').get();
      
      // 2. ЛОКАЛЬНАЯ ПРЕ-ФИЛЬТРАЦИЯ (Top 40 кандидатов)
      // Это решает проблему "Chef thinking too long" при 500+ рецептах
      List<String> userIngreds = _currentIngredients.toLowerCase().split(RegExp(r'[,\s]+')).where((s) => s.length > 2).toList();
      
      List<DocumentSnapshot> allDocs = recipesSnapshot.docs;
      
      // Сортируем по количеству совпадений ингредиентов
      allDocs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        
        String getIngStr(dynamic ing) {
          if (ing is List) return ing.join(' ').toLowerCase();
          if (ing is String) return ing.toLowerCase();
          return '';
        }

        final ingA = getIngStr(dataA['ingredients']);
        final ingB = getIngStr(dataB['ingredients']);
        
        int scoreA = userIngreds.where((ui) => ingA.contains(ui)).length;
        int scoreB = userIngreds.where((ui) => ingB.contains(ui)).length;
        return scoreB.compareTo(scoreA); // По убыванию
      });

      // Берем только топ 40
      List<DocumentSnapshot> candidates = allDocs.take(40).toList();

      // Формируем краткий список для Gemini
      List<Map<String, dynamic>> dbRecipesShort = candidates.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "name": data['name'],
          "ingredients": data['ingredients'],
        };
      }).toList();

      List<String> restrictions = [];
      if (glutenFree) restrictions.add("БЕЗ ГЛЮТЕНА");
      if (lactoseFree) restrictions.add("БЕЗ ЛАКТОЗЫ");
      if (nutAllergy) restrictions.add("БЕЗ ОРЕХОВ");

      String dietText = "";
      if (isVegan) dietText = "ТОЛЬКО ВЕГАНСКИЕ РЕЦЕПТЫ.";
      else if (isVegetarian) dietText = "ТОЛЬКО ВЕГЕТАРИАНСКИЕ РЕЦЕПТЫ.";

      // Используем gemini-1.5-flash (самая быстрая для таких задач)
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);

      final prompt = '''
      Ты - профессиональный шеф-повар. Твоя задача: выбрать из предоставленной базы данных рецептов лучшие варианты на основе имеющихся у пользователя продуктов.

      Продукты пользователя: $_currentIngredients.
      
      Ограничения: $dietText ${restrictions.join(", ")}.
      
      База данных рецептов (ID | Название | Ингредиенты):
      ${jsonEncode(dbRecipesShort)}

      Инструкция:
      1. Проанализируй ингредиенты в базе.
      2. Выбери МАКСИМУМ 3 наиболее подходящих рецепта, которые можно приготовить из продуктов пользователя (или с минимальным добавлением базовых специй/масла).
      3. Учти диетические ограничения.
      4. В поле "detected_ingredients" верни переведенный список продуктов пользователя.
      
      Ответ верни СТРОГО в формате JSON:
      {
        "detected_ingredients": ["продукт 1", "продукт 2"],
        "selected_ids": ["id_1", "id_2", "id_3"]
      }
      ''';

      GenerateContentResponse? response;
      int retryCount = 0;
      while (retryCount < 3) {
        try {
          response = await model.generateContent([Content.text(prompt)]);
          break;
        } catch (e) {
          if (e.toString().contains('503') && retryCount < 2) {
            retryCount++;
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
          rethrow;
        }
      }

      if (response != null && response.text != null) {
        String text = response.text!;
        // Более надежное извлечение JSON: ищем первую { и последнюю }
        int startIndex = text.indexOf('{');
        int endIndex = text.lastIndexOf('}');
        
        if (startIndex == -1 || endIndex == -1) {
          throw Exception("Invalid JSON format in Gemini response");
        }
        
        String cleanJson = text.substring(startIndex, endIndex + 1);
        
        final data = jsonDecode(cleanJson);
        List<String> selectedIds = List<String>.from(data['selected_ids'] ?? []);
        List<dynamic> rawIngredients = data['detected_ingredients'] ?? [];
        
        // 2. ПОЛУЧАЕМ ПОЛНЫЕ ДАННЫЕ ВЫБРАННЫХ РЕЦЕПТОВ
        List<Map<String, dynamic>> finalRecipes = [];
        for (String id in selectedIds) {
          final doc = recipesSnapshot.docs.cast<DocumentSnapshot?>().firstWhere(
            (d) => d?.id == id,
            orElse: () => null,
          );
          if (doc != null) {
            final docData = doc.data() as Map<String, dynamic>;
            docData['id'] = doc.id;
            finalRecipes.add(docData);
          }
        }

        if (mounted) {
          setState(() {
            if (_currentIngredients.isEmpty && rawIngredients.isNotEmpty) {
              _currentIngredients = rawIngredients.join(", ");
            }
            recipes = finalRecipes;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Empty response from Gemini");
      }
    } catch (e, stack) {
      debugPrint("Error in _generateRecipes: $e");
      debugPrint("Stack trace: $stack");
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Ошибка при поиске по базе рецептов: ${e.toString()}";
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
        final imageUrl = recipe['imageUrl'] ?? "";

        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 15),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 50, height: 50, fit: BoxFit.cover,
                      memCacheWidth: 100, memCacheHeight: 100,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.restaurant, color: Colors.green),
                    )
                  : const Icon(Icons.restaurant, color: Colors.green),
            ),
            title: Text(recipe['name'] ?? ''),
            subtitle: Text("${recipe['time']} мин • ${recipe['kcal']} ккал"),
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

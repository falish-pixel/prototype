import 'dart:io'; // Для работы с файлами
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Импорт пакета
import 'scan_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Привет, Шеф!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.green, width: 8)),
              child: const Center(child: Text("1250 ккал", style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(height: 40),
            const Text("Что в холодильнике?", style: TextStyle(fontSize: 20)),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Сделай фото продуктов, чтобы получить рецепт", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPickerOptions(context), // Вызов выбора
        label: const Text("Сканировать"),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Меню выбора: Камера или Галерея
  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Выбрать из галереи'),
                  onTap: () {
                    _pickImage(context, ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сделать фото'),
                onTap: () {
                  _pickImage(context, ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Логика получения фото и переход
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      // Переходим на экран AI и передаем путь к фото
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiRecipesScreen(imagePath: image.path),
        ),
      );
    }
  }
}
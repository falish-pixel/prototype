import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_screen.dart';

// 1. Меняем на StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Получаем текущего пользователя
  User? user = FirebaseAuth.instance.currentUser;

  // Функция для обновления данных пользователя при возврате
  void _refreshUser() async {
    await user?.reload(); // Обновляем данные с сервера
    setState(() {
      user = FirebaseAuth.instance.currentUser; // Перечитываем объект
    });
  }

  @override
  Widget build(BuildContext context) {
    // Если имя не задано, используем "Шеф"
    String displayName = user?.displayName ?? "Шеф";
    if (displayName.isEmpty) displayName = "Шеф";

    return Scaffold(
      appBar: AppBar(
        // 2. Используем имя переменной
        title: Text('Привет, $displayName!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Выйти из аккаунта",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // 3. Ждем возврата из настроек и обновляем экран
              await Navigator.pushNamed(context, '/settings');
              _refreshUser();
            },
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
        onPressed: () => _showPickerOptions(context),
        label: const Text("Сканировать"),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ... (методы _showPickerOptions и _pickImage остаются без изменений)
  void _showPickerOptions(BuildContext context) {
    // ... ваш код ...
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

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    // ... ваш код ...
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiRecipesScreen(imagePath: image.path),
        ),
      );
    }
  }
}
// Файл: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_screen.dart';
import 'favorites_screen.dart'; // Не забудь создать этот файл, как мы обсуждали ранее

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Функция для обновления (оставляем её на всякий случай для настроек)
  Future<void> _refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // StreamBuilder автоматически следит за изменениями пользователя (имени, фото)
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            // Логика получения имени
            final displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
                ? user!.displayName!
                : "Шеф";

            return Text('Привет, $displayName!');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          // --- НОВАЯ КНОПКА: ИЗБРАННОЕ ---
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          // -------------------------------
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // 1. Ждем возврата из настроек
              final result = await Navigator.pushNamed(context, '/settings');

              // 2. Если настройки передали true, значит данные изменились
              if (result == true) {
                await FirebaseAuth.instance.currentUser?.reload(); // На всякий случай еще раз
                if (mounted) setState(() {}); // Принудительно перерисовываем экран
              } else {
                // Даже если false, на всякий случай обновим (не повредит)
                await _refreshUser();
              }
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
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 8)
              ),
              child: const Center(
                  child: Text("1250 ккал", style: TextStyle(fontSize: 24))
              ),
            ),
            const SizedBox(height: 40),
            const Text("Что в холодильнике?", style: TextStyle(fontSize: 20)),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  "Сделай фото продуктов или введи список вручную, чтобы получить рецепт",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center
              ),
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

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // --- ВВОД ВРУЧНУЮ ---
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Ввести вручную'),
                onTap: () {
                  Navigator.pop(context); // Закрываем меню
                  _showManualInputDialog(context); // Открываем ввод текста
                },
              ),
              const Divider(),
              // --- ГАЛЕРЕЯ ---
              ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Галерея'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  }),
              // --- КАМЕРА ---
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: const Text('Камера'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ДИАЛОГ ДЛЯ РУЧНОГО ВВОДА ---
  void _showManualInputDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Что есть в холодильнике?"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Например: курица, рис, помидоры",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Отмена"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context); // Закрываем диалог
                  // Переходим на экран рецептов с ТЕКСТОМ
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiRecipesScreen(
                        ingredientsInput: controller.text,
                        // imagePath не передаем, он будет null
                      ),
                    ),
                  );
                }
              },
              child: const Text("Искать рецепты"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AiRecipesScreen(imagePath: image.path)
        ),
      );
    }
  }
}
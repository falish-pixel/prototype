import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scan_screen.dart';
import 'favorites_screen.dart';
import '../services/language_service.dart'; // Импорт сервиса языков

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            final displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
                ? user!.displayName!
                : LanguageService.tr('chef'); // "Шеф"

            // "Привет, Имя!" - тут можно усложнить для мультиязычности,
            // но пока оставим простую склейку, или добавьте ключ 'hello' в словарь
            return Text("${LanguageService.tr('hello')}, $displayName!");
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          // Кнопка ИЗБРАННОЕ
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          // Кнопка НАСТРОЙКИ
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/settings');
              if (result == true) {
                await FirebaseAuth.instance.currentUser?.reload();
                if (mounted) setState(() {});
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Статический круг калорий (пока без сложной логики)
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 8)
              ),
              child: const Center(
                  child: Text("1250 kcal", style: TextStyle(fontSize: 24))
              ),
            ),
            const SizedBox(height: 40),

            // Заголовок "Что в холодильнике?"
            Text(LanguageService.tr('what_in_fridge'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

            Padding(
              padding: const EdgeInsets.all(16.0),
              // Подсказка "Сделай фото..."
              child: Text(
                  LanguageService.tr('scan_hint'),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPickerOptions(context),
        // Кнопка "Сканировать"
        label: Text(LanguageService.tr('scan_button')),
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
              // Ввести вручную
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: Text(LanguageService.tr('manual_input')),
                onTap: () {
                  Navigator.pop(context);
                  _showManualInputDialog(context);
                },
              ),
              const Divider(),
              // Галерея
              ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: Text(LanguageService.tr('gallery')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  }),
              // Камера
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: Text(LanguageService.tr('camera')),
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

  void _showManualInputDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          // Для заголовка используем "Что в холодильнике?" или добавьте ключ 'manual_title'
          title: Text(LanguageService.tr('what_in_fridge')),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "...", // Можно добавить ключ 'hint_text'
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiRecipesScreen(
                        ingredientsInput: controller.text,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Search"),
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
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ВАЖНО: Эта строка нужна для графиков. Если она подчеркнута красным - сделайте "flutter pub get"
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'scan_screen.dart';
import 'favorites_screen.dart';
import '../services/language_service.dart';
import '../services/calorie_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    // Получаем тему и цвета
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            // Исправленная логика проверки имени (убраны лишние !)
            String displayName = LanguageService.tr('chef');
            if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
              displayName = user.displayName!;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${LanguageService.tr('hello')},",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  "$displayName!",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          // Кнопка ИЗБРАННОЕ
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
          // Кнопка НАСТРОЙКИ
          IconButton(
            icon: Icon(Icons.settings_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              if (mounted) setState(() {});
            },
          ),
          // Кнопка ВЫХОД
          IconButton(
            icon: Icon(Icons.logout_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // --- ТРЕКЕР КАЛОРИЙ (Кликабельный) ---
              InkWell(
                onTap: () => _showWeeklyChart(context, isDark, cardColor, primaryColor),
                borderRadius: BorderRadius.circular(24),
                child: _buildCalorieTracker(isDark, cardColor),
              ),

              const SizedBox(height: 30),

              // --- СЕКЦИЯ СКАНИРОВАНИЯ ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.kitchen_rounded, size: 40, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LanguageService.tr('what_in_fridge'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LanguageService.tr('scan_hint'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Кнопка "Сканировать" внутри карточки
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPickerOptions(context),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(LanguageService.tr('scan_button').toUpperCase()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Плавающая кнопка
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPickerOptions(context),
        backgroundColor: primaryColor,
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
      ),
    );
  }

  // --- ВИДЖЕТ ТРЕКЕРА ---
  Widget _buildCalorieTracker(bool isDark, Color cardColor) {
    return StreamBuilder<DocumentSnapshot>(
      stream: CalorieService.getTodayStats(),
      builder: (context, snapshot) {
        int consumed = 0;
        int goal = 2000;

        // Безопасное извлечение данных
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          consumed = data['consumed'] ?? 0;
          goal = data['goal'] ?? 2000;
        }

        double progress = (goal > 0) ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
        bool isOverLimit = consumed > goal;

        // Динамический цвет
        Color progressColor;
        if (progress < 0.5) {
          progressColor = Colors.blueAccent;
        } else if (progress < 0.9) {
          progressColor = Colors.green;
        } else if (!isOverLimit) {
          progressColor = Colors.orange;
        } else {
          progressColor = Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Круг
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 10,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: isOverLimit ? 1.0 : progress,
                        strokeWidth: 10,
                        color: progressColor,
                        backgroundColor: Colors.transparent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(
                        isOverLimit ? Icons.warning_rounded : Icons.local_fire_department_rounded,
                        color: progressColor.withValues(alpha: 0.8), size: 30
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Текст
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.tr('today'),
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "$consumed",
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isOverLimit ? Colors.red : (isDark ? Colors.white : Colors.black87)
                            ),
                          ),
                          TextSpan(
                            text: " / $goal",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.normal
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOverLimit ? LanguageService.tr('limit_exceeded') : LanguageService.tr('kcal'),
                      style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- ГРАФИК ---
  void _showWeeklyChart(BuildContext context, bool isDark, Color bgColor, Color primary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 500,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(LanguageService.tr('history_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: CalorieService.getWeeklyStats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(LanguageService.tr('no_data')));
                    }

                    final data = snapshot.data!.reversed.toList();

                    // Строим график с использованием fl_chart
                    return BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= data.length) return const Text('');
                                final dateStr = data[index]['date'];
                                final date = DateTime.parse(dateStr);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('dd.MM').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: data.asMap().entries.map((entry) {
                          final index = entry.key;
                          final day = entry.value;
                          final consumed = (day['consumed'] as num).toDouble();
                          final goal = (day['goal'] as num).toDouble();
                          final isOver = consumed > goal;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: consumed,
                                color: isOver ? Colors.redAccent : Colors.green,
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                                // ВОТ ТУТ БЫЛА ОШИБКА. ТЕПЕРЬ ИСПРАВЛЕНО:
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: goal > consumed ? goal : consumed,
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  // --- МЕНЮ ВЫБОРА (ФОТО/РУЧНОЙ) ---
  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        final isDark = Theme.of(bc).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF2C2C2C) : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Wrap(
            children: <Widget>[
              Center(
                child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              _buildOptionTile(
                icon: Icons.edit_note_rounded, color: Colors.orange,
                title: LanguageService.tr('manual_input'),
                onTap: () { Navigator.pop(context); _showManualInputDialog(context); },
              ),
              Divider(color: Colors.grey.withValues(alpha: 0.2), indent: 20, endIndent: 20),
              _buildOptionTile(
                icon: Icons.photo_library_rounded, color: Colors.blue,
                title: LanguageService.tr('gallery'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              _buildOptionTile(
                icon: Icons.camera_alt_rounded, color: Colors.green,
                title: LanguageService.tr('camera'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showManualInputDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(LanguageService.tr('what_in_fridge')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: LanguageService.tr('manual_hint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LanguageService.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AiRecipesScreen(ingredientsInput: controller.text),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text(LanguageService.tr('search')),
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
        MaterialPageRoute(builder: (context) => AiRecipesScreen(imagePath: image.path)),
      );
    }
  }
}
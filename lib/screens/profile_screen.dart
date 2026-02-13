import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/user_service.dart';

import 'package:intl/intl.dart'; // <--- Добавь этот импорт для красивой даты
import '../services/calorie_service.dart'; // <--- И этот

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user?.displayName ?? "";
    }
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await UserService.updateNameInFirestore(_nameController.text.trim());
      try {
        await user?.updateDisplayName(_nameController.text.trim());
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LanguageService.tr('name_saved')), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: UserService.getUserStream(),
        builder: (context, snapshot) {
          int level = 1;
          int xp = 0;
          int recipesCooked = 0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            level = data['level'] ?? 1;
            xp = data['xp'] ?? 0;
            recipesCooked = data['recipesCooked'] ?? 0;

            if (!_isLoading && _nameController.text.isEmpty) {
              _nameController.text = data['displayName'] ?? "";
            }
          }

          int xpNextLevel = level * 100;
          double progress = (xp / xpNextLevel).clamp(0.0, 1.0);

          return Scaffold(
            appBar: AppBar(title: Text(LanguageService.tr('edit_profile'))),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.green),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        child: Text("$level", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // ЛОКАЛИЗАЦИЯ: "Шеф-повар Уровня X" / "Бас аспаз деңгейі X"
                  Text("${LanguageService.tr('chef_level')} $level", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: Colors.grey[200],
                      color: Colors.green,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("XP: $xp", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        // ЛОКАЛИЗАЦИЯ: "Цель: 100" / "Мақсат: 100"
                        Text("${LanguageService.tr('goal')}: $xpNextLevel", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      // ЛОКАЛИЗАЦИЯ: Блюд готово
                      Expanded(child: _buildStatCard(Icons.restaurant, "$recipesCooked", LanguageService.tr('dishes_cooked'))),
                      const SizedBox(width: 12),
                      // ЛОКАЛИЗАЦИЯ: Серия дней
                      Expanded(child: _buildStatCard(Icons.local_fire_department, "🔥", LanguageService.tr('day_streak'))),
                    ],
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showHistorySheet, // Вызываем функцию
                      icon: const Icon(Icons.history, color: Colors.orange),
                      label: Text(LanguageService.tr('history_title')), // "История питания"
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: LanguageService.tr('your_name'),
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                          : Text(LanguageService.tr('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(LanguageService.tr('history_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: CalorieService.getHistoryStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(child: Text(LanguageService.tr('empty_history'), style: const TextStyle(color: Colors.grey)));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final kcal = data['amount'] ?? 0;
                        final name = data['label'] ?? 'Food'; // Теперь тут будет название!

                        // Форматируем дату
                        String dateStr = "";
                        if (data['date'] != null) {
                          final date = (data['date'] as Timestamp).toDate();
                          dateStr = DateFormat('dd MMM, HH:mm').format(date);
                        }

                        return ListTile(
                          leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(dateStr),
                          trailing: Text("+$kcal ккал", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        );
                      },
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
}
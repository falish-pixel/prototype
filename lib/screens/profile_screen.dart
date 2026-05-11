import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/user_service.dart';

import 'package:intl/intl.dart';
import '../services/calorie_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _isDeletionMode = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _nameController.text = user?.displayName ?? "";
    }
  }



  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    if (newName == user?.displayName) return;

    setState(() => _isLoading = true);

    try {
      // Это меняет твой ID везде: и в профиле, и для входа
      await _authService.updateUsername(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LanguageService.tr('name_saved')), backgroundColor: Colors.green),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains("username-taken")) msg = LanguageService.tr('username_taken');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final url = await UserService.uploadAvatar(File(image.path));
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Фото профиля обновлено!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LanguageService.tr('delete_confirm_title')),
        content: Text(LanguageService.tr('delete_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LanguageService.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LanguageService.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeletionMode = true);
    }
  }

  Future<void> _finalDelete() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _authService.deleteAccount(password);
      
      // Сбрасываем флаг настройки профиля
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isProfileSetup', false);

      if (mounted) {
        // Очищаем стек и переходим на логин
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = e.code == 'wrong-password' 
          ? LanguageService.tr('invalid_password') 
          : (e.message ?? e.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeletionMode) {
      return _buildDeletionVerificationUI();
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: UserService.getUserStream(),
        builder: (context, snapshot) {
          int level = 1;
          int xp = 0;
          int recipesCooked = 0;
          String displayName = user?.displayName ?? "User";
          String? photoURL = user?.photoURL;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            level = data['level'] ?? 1;
            xp = data['xp'] ?? 0;
            recipesCooked = data['recipesCooked'] ?? 0;
            displayName = data['displayName'] ?? displayName;
            photoURL = data['photoURL'] ?? photoURL;

            if (!_isLoading && _nameController.text.isEmpty) {
              _nameController.text = displayName;
            }
          }

          int xpNextLevel = level * 100;
          double progress = (xp / xpNextLevel).clamp(0.0, 1.0);

          return Scaffold(
            appBar: AppBar(title: Text(LanguageService.tr('account'))),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // АВАТАРКА С КНОПКОЙ РЕДАКТИРОВАНИЯ
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 3),
                          ),
                          child: ClipOval(
                            child: photoURL != null 
                              ? CachedNetworkImage(
                                  imageUrl: photoURL,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 70, color: Colors.green),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.person, size: 70, color: Colors.green),
                          ),
                        ),
                      ),
                      // Уровень в маленьком кружке
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        child: Text("$level", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                      // Кнопка карандаша для фото
                      Positioned(
                        right: 0, top: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ИМЯ ПОЛЬЗОВАТЕЛЯ (Логин)
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Полоса прогресса уровня
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
                        Text("${LanguageService.tr('goal')}: $xpNextLevel", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Карточки статистики
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.restaurant, "$recipesCooked", LanguageService.tr('dishes_cooked'))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Icons.local_fire_department, "🔥", LanguageService.tr('day_streak'))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Кнопка истории
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showHistorySheet,
                      icon: const Icon(Icons.history, color: Colors.orange),
                      label: Text(LanguageService.tr('history_title')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Редактирование отображаемого имени
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: LanguageService.tr('your_name'),
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _updateName,
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Кнопка выхода
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                      label: Text(
                        LanguageService.tr('logout'),
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Удаление аккаунта
                  TextButton.icon(
                    onPressed: _isLoading ? null : _confirmDeleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: Text(
                      LanguageService.tr('delete_account'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildDeletionVerificationUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr('delete_account')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isDeletionMode = false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              LanguageService.tr('enter_password_to_delete'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              LanguageService.tr('delete_account_step2'),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LanguageService.tr('password_label'),
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finalDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(LanguageService.tr('confirm_delete_button'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _isDeletionMode = false),
              child: Text(LanguageService.tr('cancel')),
            ),
          ],
        ),
      ),
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
                        final name = data['label'] ?? 'Food';
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  /// Получаем поток данных пользователя для живого обновления UI (имя, уровень, опыт)
  static Stream<DocumentSnapshot> getUserStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
  }

  /// Обновление имени в Firestore и Auth
  static Future<void> updateName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Обновляем в Auth
    await user.updateDisplayName(newName);

    // Обновляем в Firestore
    await _db.collection('users').doc(user.uid).set({
      'displayName': newName,
    }, SetOptions(merge: true));
  }

  /// Загрузка аватара в Storage и обновление ссылок
  static Future<String?> uploadAvatar(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Сохраняем просто под UID, без расширения .jpg.
      // Это совпадет с правилом match /avatars/{userId} в консоли.
      final ref = _storage.ref().child('avatars').child(user.uid);
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      // Обновляем в Auth
      await user.updatePhotoURL(url);

      // Обновляем в Firestore
      await _db.collection('users').doc(user.uid).set({
        'photoURL': url,
      }, SetOptions(merge: true));

      return url;
    } catch (e) {
      print("Error uploading avatar: $e");
      return null;
    }
  }

  /// Начисление XP и проверка повышения уровня
  static Future<int> addXp(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final userRef = _db.collection('users').doc(user.uid);
    int newLevel = -1; // Сигнал для UI о повышении уровня (-1 = уровня нет)

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      // Текущие данные (если документа нет, ставим 0 и 1 уровень)
      int currentXp = 0;
      int currentLevel = 1;
      int recipesCooked = 0;

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        currentXp = data['xp'] ?? 0;
        currentLevel = data['level'] ?? 1;
        recipesCooked = data['recipesCooked'] ?? 0;
      }

      // Новые значения
      int updatedXp = currentXp + amount;
      int updatedRecipes = recipesCooked + 1;

      // Формула опыта: для перехода на следующий уровень нужно (Level * 100) XP
      int xpNeeded = currentLevel * 100;

      // Проверка на Level Up
      if (updatedXp >= xpNeeded) {
        updatedXp -= xpNeeded; // Остаток опыта переносим на новый уровень
        currentLevel++;
        newLevel = currentLevel;
      }

      // Сохраняем все данные одним пакетом
      transaction.set(userRef, {
        'xp': updatedXp,
        'level': currentLevel,
        'recipesCooked': updatedRecipes,
      }, SetOptions(merge: true));
    });

    return newLevel;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Получаем поток данных пользователя для живого обновления UI (имя, уровень, опыт)
  static Stream<DocumentSnapshot> getUserStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    // Следим за документом пользователя в коллекции 'users'
    return _db.collection('users').doc(user.uid).snapshots();
  }

  /// Сохранение имени пользователя в Firestore (вместо проблемного Auth reload)
  static Future<void> updateNameInFirestore(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'displayName': newName,
    }, SetOptions(merge: true));
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
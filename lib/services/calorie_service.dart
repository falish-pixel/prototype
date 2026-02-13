import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // 1. Статистика за сегодня (Stream)
  static Stream<DocumentSnapshot> getTodayStats() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final date = DateTime.now().toString().split(' ')[0];
    return _db.collection('users').doc(user.uid).collection('daily_stats').doc(date).snapshots();
  }

  // 2. Статистика за неделю (Future)
  static Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final query = await _db.collection('users')
        .doc(user.uid)
        .collection('daily_stats')
        .orderBy(FieldPath.documentId, descending: true)
        .limit(7)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'date': doc.id,
        'consumed': data['consumed'] ?? 0,
        'goal': data['goal'] ?? 2000,
      };
    }).toList();
  }

  // 3. Добавить калории
  static Future<void> addCalories(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final date = DateTime.now().toString().split(' ')[0];
    final dayRef = _db.collection('users').doc(user.uid).collection('daily_stats').doc(date);
    final userRef = _db.collection('users').doc(user.uid);

    return _db.runTransaction((transaction) async {
      final daySnapshot = await transaction.get(dayRef);

      int targetGoal = 2000;
      final userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists && userSnapshot.data()!.containsKey('dailyGoal')) {
        targetGoal = userSnapshot.get('dailyGoal');
      }

      if (!daySnapshot.exists) {
        transaction.set(dayRef, {
          'consumed': amount,
          'goal': targetGoal,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        final currentConsumed = daySnapshot.get('consumed') as int? ?? 0;
        transaction.update(dayRef, {
          'consumed': currentConsumed + amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // 4. Обновить цель
  static Future<void> updateGoal(int newGoal) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final date = DateTime.now().toString().split(' ')[0];

    await _db.collection('users').doc(user.uid).set({
      'dailyGoal': newGoal
    }, SetOptions(merge: true));

    final dayRef = _db.collection('users').doc(user.uid).collection('daily_stats').doc(date);
    final daySnapshot = await dayRef.get();
    if (daySnapshot.exists) {
      await dayRef.update({'goal': newGoal});
    }
  }

  // 5. Получить текущую цель
  static Future<int> getCurrentGoal() async {
    final user = _auth.currentUser;
    if (user == null) return 2000;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()!.containsKey('dailyGoal')) {
      return doc.get('dailyGoal');
    }
    return 2000;
  }
}
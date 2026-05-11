import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Поток для отслеживания состояния пользователя
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // РЕГИСТРАЦИЯ
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final usernameDoc = await _db.collection('usernames').doc(username).get();
      if (usernameDoc.exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Этот логин уже занят');
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // 1. Сохраняем логин в usernames
        await _db.collection('usernames').doc(username).set({
          'email': email,
          'uid': result.user!.uid,
        });

        // 2. Создаем документ пользователя в users
        await _db.collection('users').doc(result.user!.uid).set({
          'displayName': username,
          'username': username,
          'email': email,
          'level': 1,
          'xp': 0,
          'recipesCooked': 0,
        });

        await result.user!.updateDisplayName(username);
        await result.user!.sendEmailVerification();
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // ВХОД
  Future<UserCredential?> signInWithIdentifier(String identifier, String password) async {
    String email = identifier;

    if (!identifier.contains('@')) {
      final cleanIdentifier = identifier.trim();
      final doc = await _db.collection('usernames').doc(cleanIdentifier).get();
      
      if (!doc.exists) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Логин не найден');
      }
      email = doc.data()?['email'];
    }

    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null && !result.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Пожалуйста, подтвердите вашу почту.',
        );
      }
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Неверный логин или пароль.'
        );
      }
      rethrow;
    }
  }

  // ВХОД ЧЕРЕЗ GOOGLE
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // СБРОС ПАРОЛЯ
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ОБНОВЛЕНИЕ ПОЧТЫ
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.verifyBeforeUpdateEmail(newEmail);
    await updateEmailInFirestoreOnly(newEmail);
  }

  // СИНХРОНИЗАЦИЯ ПОЧТЫ ТОЛЬКО В FIRESTORE
  Future<void> updateEmailInFirestoreOnly(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Ищем логин в users
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'];

    if (username != null) {
      await _db.collection('usernames').doc(username).set({
        'email': newEmail,
      }, SetOptions(merge: true));
    }

    // 2. Обновляем в users
    await _db.collection('users').doc(user.uid).set({
      'email': newEmail,
    }, SetOptions(merge: true));
  }

  // ИЗМЕНЕНИЕ ЛОГИНА (ID)
  Future<void> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final oldUsername = userDoc.data()?['username'];

      if (oldUsername == newUsername) return;

      final newDoc = await _db.collection('usernames').doc(newUsername).get();
      if (newDoc.exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Этот логин уже занят');
      }

      await _db.collection('usernames').doc(newUsername).set({
        'email': user.email,
        'uid': user.uid,
      });

      if (oldUsername != null) {
        await _db.collection('usernames').doc(oldUsername).delete();
      }

      await _db.collection('users').doc(user.uid).update({
        'username': newUsername,
        'displayName': newUsername, // Для синхронизации
      });
      
      await user.updateDisplayName(newUsername);
    } catch (e) {
      rethrow;
    }
  }

  // РЕ-АУТЕНТИФИКАЦИЯ
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception("User not found");
    AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  // ОБНОВЛЕНИЕ ПАРОЛЯ
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // ПОЛНОЕ УДАЛЕНИЕ АККАУНТА
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    try {
      await reauthenticate(password);

      final userDoc = await _db.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'];

      if (username != null) {
        await _db.collection('usernames').doc(username).delete();
      }

      await _db.collection('users').doc(user.uid).delete();
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }

  // СИНХРОНИЗАЦИЯ ПОСЛЕ ПОДТВЕРЖДЕНИЯ
  Future<void> syncEmailWithFirestore() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    await updateEmailInFirestoreOnly(user.email!);
  }

  Future<void> reloadUser() async => await _auth.currentUser?.reload();

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}

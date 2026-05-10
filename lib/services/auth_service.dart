import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Поток для отслеживания состояния пользователя
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // РЕГИСТРАЦИЯ: логин + почта + пароль
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1. Проверяем, не занят ли логин в Firestore
      final usernameDoc = await _db.collection('usernames').doc(username).get();
      if (usernameDoc.exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Этот логин уже занят');
      }

      // 2. Создаем аккаунт в Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // 3. Сохраняем связь логина и почты в Firestore
        await _db.collection('usernames').doc(username).set({
          'email': email,
          'uid': result.user!.uid,
        });

        // 4. Обновляем displayName пользователя
        await result.user!.updateDisplayName(username);
        
        // 5. Отправляем письмо (НЕ ВЫХОДИМ, чтобы проверять статус в реальном времени)
        await result.user!.sendEmailVerification();
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // ВХОД: по Email ИЛИ Логину
  Future<UserCredential?> signInWithIdentifier(String identifier, String password) async {
    String email = identifier;

    // Если в identifier нет '@', значит это логин — ищем email в Firestore
    if (!identifier.contains('@')) {
      final doc = await _db.collection('usernames').doc(identifier).get();
      if (!doc.exists) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Логин не найден');
      }
      email = doc.data()?['email'];
    }

    // Выполняем вход
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Проверяем подтверждение почты
    if (result.user != null && !result.user!.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Пожалуйста, подтвердите вашу почту.',
      );
    }

    return result;
  }

  // Вход через Google
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
      print("Ошибка входа Google: $e");
      return null;
    }
  }

  // Сброс пароля
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Обновить данные пользователя (полезно для проверки emailVerified)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // ВЫХОД
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ОБНОВЛЕНИЕ ЛОГИНА (решение бага со входом)
  Future<void> updateUsername(String newUsername) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final oldUsername = user.displayName;
    if (oldUsername == newUsername) return; // Ничего не изменилось

    try {
      // 1. Проверяем, не занят ли НОВЫЙ логин
      final newDoc = await _db.collection('usernames').doc(newUsername).get();
      if (newDoc.exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Этот логин уже занят');
      }

      // 2. Создаем новую запись
      await _db.collection('usernames').doc(newUsername).set({
        'email': user.email,
        'uid': user.uid,
      });

      // 3. Удаляем старую запись
      if (oldUsername != null && oldUsername.isNotEmpty) {
        await _db.collection('usernames').doc(oldUsername).delete();
      }

      // 4. Обновляем displayName в Auth
      await user.updateDisplayName(newUsername);
    } catch (e) {
      rethrow;
    }
  }

  // ПОЛНОЕ УДАЛЕНИЕ АККАУНТА (с проверкой пароля)
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final username = user.displayName;
      final email = user.email;

      if (email == null) return;

      // 1. Ре-аутентификация (обязательно для удаления)
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);

      // 2. Удаляем из коллекции usernames
      if (username != null && username.isNotEmpty) {
        await _db.collection('usernames').doc(username).delete();
      }

      // 3. Удаляем данные пользователя
      await _db.collection('users').doc(user.uid).delete();

      // 4. Удаляем самого пользователя
      await user.delete();
    } catch (e) {
      rethrow;
    }
  }
}

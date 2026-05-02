import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Поток для отслеживания состояния пользователя (вошел/вышел)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Пользователь отменил вход

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

  // Регистрация через Email/Password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Отправляем письмо
      await result.user?.sendEmailVerification();
      // СРАЗУ ВЫХОДИМ, чтобы пользователь не попал в приложение без подтверждения
      await _auth.signOut(); 
      return result;
    } catch (e) {
      print("Ошибка регистрации Email: $e");
      rethrow;
    }
  }

  // Вход через Email/Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Проверяем, подтвержден ли email
      if (result.user != null && !result.user!.emailVerified) {
        // Если не подтвержден — выходим и кидаем ошибку
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email first.',
        );
      }

      return result;
    } catch (e) {
      print("Ошибка входа Email: $e");
      rethrow;
    }
  }

  // Проверка подтверждения Email
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Повторная отправка письма подтверждения
  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Выход
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
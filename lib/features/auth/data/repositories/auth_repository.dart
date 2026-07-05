import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> signOut();
}

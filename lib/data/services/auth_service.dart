

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  // Get the currently logged-in user.
  User? get currentUser => _firebaseAuth.currentUser;

  // Listen for login and logout changes.
  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Register a new user with email and password.
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Save the user's name in their Firebase Auth profile.
    await credential.user?.updateDisplayName(name.trim());

    return credential;
  }

  // Log in an existing user.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Log out the current user.
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  // Send a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
}

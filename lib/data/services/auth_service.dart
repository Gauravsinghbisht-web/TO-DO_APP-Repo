
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirestoreService? firestoreService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

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

    final user = credential.user;

    if (user == null) {
      throw Exception('User account could not be created.');
    }

    // Save the user's name in Firebase Authentication.
    await user.updateDisplayName(name.trim());

    // Save the user's profile in Cloud Firestore.
    await _firestoreService.saveUserProfile(
      name: name.trim(),
      email: user.email ?? email.trim(),
    );

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

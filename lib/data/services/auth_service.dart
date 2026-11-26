
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _firebaseStorage;
  final FirestoreService _firestoreService;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? firebaseStorage,
    FirestoreService? firestoreService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance,
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
      phone: user.phoneNumber ?? '',
      photoUrl: user.photoURL ?? '',
    );

    return credential;
  }

  // Log in an existing user.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      // Backfill profile fields for accounts created before profile storage.
      await _firestoreService.saveUserProfile(
        name: user.displayName ?? '',
        email: user.email ?? email.trim(),
        phone: user.phoneNumber ?? '',
        photoUrl: user.photoURL ?? '',
      );
    }

    return credential;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final snapshot = await _firestoreService.getUserProfile();
    return snapshot.data() ?? <String, dynamic>{};
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
  }) => _firestoreService.updateUserProfile(name: name, phone: phone);

  Future<String> uploadProfileImage(
    XFile image, {
    void Function(double progress)? onProgress,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('You must be signed in to upload a photo.');

    // Reusing the UID path replaces the prior object without leaving an orphan.
    final imageRef = _firebaseStorage.ref('profile_images/${user.uid}.jpg');
    final mimeType = image.mimeType;
    final uploadTask = imageRef.putData(
      await image.readAsBytes(),
      SettableMetadata(
        contentType: mimeType?.startsWith('image/') == true
            ? mimeType
            : 'image/jpeg',
      ),
    );
    final progressSubscription = uploadTask.snapshotEvents.listen(
      (snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      },
      onError: (Object _) {},
    );

    try {
      final uploadedSnapshot = await uploadTask;
      onProgress?.call(1);
      // Use the reference returned by the completed task so the URL lookup
      // targets the exact object that Storage confirms it uploaded.
      final downloadUrl = await uploadedSnapshot.ref.getDownloadURL();
      await _firestoreService.updateUserProfilePhoto(downloadUrl);
      return downloadUrl;
    } finally {
      await progressSubscription.cancel();
    }
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

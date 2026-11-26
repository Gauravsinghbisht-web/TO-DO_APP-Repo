
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _profile = null;
      notifyListeners();
      if (user != null) loadUserProfile();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  bool _isProfileLoading = false;
  bool _isUploadingProfileImage = false;
  double _profileImageUploadProgress = 0;

  Map<String, dynamic>? get profile => _profile;
  bool get isProfileLoading => _isProfileLoading;
  bool get isUploadingProfileImage => _isUploadingProfileImage;
  double get profileImageUploadProgress => _profileImageUploadProgress;

  User? get user => _user;

  bool get isAuthenticated => _user != null;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _startLoading();

    try {
      await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } catch (error) {
      debugPrint('TaskFlow signup error: $error');
      _errorMessage = 'Account creation failed. Please try again.';
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _startLoading();

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } catch (error) {
      debugPrint('TaskFlow login error: $error');
      _errorMessage = 'Login failed. Please try again.';
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<bool> signOut() async {
    _startLoading();

    try {
      await _authService.signOut();
      return true;
    } catch (error) {
      debugPrint('TaskFlow logout error: $error');
      _errorMessage = 'Logout failed. Please try again.';
      return false;
    } finally {
      _stopLoading();
    }
  }

  Future<void> loadUserProfile() async {
    if (_user == null) return;
    _isProfileLoading = true;
    notifyListeners();
    try {
      _profile = await _authService.getUserProfile();
    } catch (error) {
      debugPrint('TaskFlow profile load error: $error');
      _errorMessage = 'Could not load your profile. Please try again.';
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    try {
      await _authService.updateUserProfile(name: name.trim(), phone: phone.trim());
      _profile = {
        ...?_profile,
        'uid': _user?.uid,
        'name': name.trim(),
        'email': _user?.email ?? '',
        'phone': phone.trim(),
      };
      await _user?.updateDisplayName(name.trim());
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('TaskFlow profile update error: $error');
      _errorMessage = 'Could not save your profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProfileImage(XFile image) async {  //it is for upload image 
    _isUploadingProfileImage = true;
    _profileImageUploadProgress = 0;
    _errorMessage = null;
    notifyListeners();
    try {
      final photoUrl = await _authService.uploadProfileImage(
        image,
        onProgress: (progress) {
          _profileImageUploadProgress = progress.clamp(0, 1).toDouble();
          notifyListeners();
        },
      );
      _profile = {...?_profile, 'photoUrl': photoUrl};
      return true;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('TaskFlow profile image Firebase error (${error.code}): $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = switch (error.code) {
        'unauthorized' => 'Firebase Storage denied this upload. Check that Storage is enabled and the deployed rules allow signed-in users to write profile_images/<uid>.jpg.',
        'bucket-not-found' || 'no-default-bucket' => 'Firebase Storage is not configured for this Firebase project. Set up its Storage bucket and verify the app storageBucket.',
        'canceled' => 'The profile photo upload was canceled.',
        'quota-exceeded' => 'The Firebase Storage quota has been exceeded.',
        'object-not-found' => 'Firebase Storage could not find the uploaded profile photo while creating its download URL. Check the deployed Storage rules and the profile_images/<uid>.jpg object in the Firebase console.',
        _ => 'Could not upload profile photo (${error.code}). ${error.message ?? 'Please try again.'}',
      };
      return false;
    } catch (error, stackTrace) {
      debugPrint('TaskFlow profile image upload error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = 'Could not upload your profile photo: $error';
      return false;
    } finally {
      _isUploadingProfileImage = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _startLoading();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } catch (error) {
      debugPrint('TaskFlow password reset error: $error');
      _errorMessage = 'Could not send the reset email. Please try again.';
      return false;
    } finally {
      _stopLoading();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}

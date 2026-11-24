
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

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

import 'package:caller_app/core/services/firebase_messaging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_service.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseMessagingService _firebaseMessagingService =
      FirebaseMessagingService.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
      );

      _isLoading = false;
      _error = null;
      notifyListeners();

      return user != null;
    } catch (e) {
      _isLoading = false;

      if (e is FirebaseAuthException) {
        // Only show the clean message without code
        _error = e.message ?? 'An unknown error occurred.';
      } else {
        final raw = e.toString();
        // Extract only the human-readable message after the last closing bracket
        final regex = RegExp(r'\]\s*(.*)$');
        final match = regex.firstMatch(raw);
        _error = match != null
            ? match.group(1)!.trim()
            : 'An unexpected error occurred.';
      }

      print('SignIn Error: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, bool isListener) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _firebaseService.signUpWithEmailAndPassword(
        email,
        password,
      );

      if (user != null) {
        final fcmToken = await _firebaseMessagingService.getFCMToken();
        await _firebaseService.saveUserData(
          user.uid,
          email,
          fcmToken ?? '',
          isListener,
        );
      }

      _isLoading = false;
      _error = null;
      notifyListeners();

      return user != null;
    } catch (e) {
      _isLoading = false;

      if (e is FirebaseAuthException) {
        // Only show the clean message without code
        _error = e.message ?? 'An unknown error occurred.';
      } else {
        final raw = e.toString();
        // Extract only the human-readable message after the last closing bracket
        final regex = RegExp(r'\]\s*(.*)$');
        final match = regex.firstMatch(raw);
        _error = match != null
            ? match.group(1)!.trim()
            : 'An unexpected error occurred.';
      }

      print('SignIn Error: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    notifyListeners();
  }
}

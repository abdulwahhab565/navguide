import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthViewContract {
  void showLoading();
  void hideLoading();
  void onAuthSuccess(UserModel user);
  void onAuthError(String message);
}

class AuthPresenter {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  AuthViewContract? _view;

  void attachView(AuthViewContract view) {
    _view = view;
  }

  void detachView() {
    _view = null;
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _view?.onAuthError('Please enter both email and password.');
      return;
    }

    _view?.showLoading();
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser != null) {
        UserModel? userProfile = await _firestoreService.getUserProfile(firebaseUser.uid);

        userProfile ??= UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          displayName: firebaseUser.displayName ?? _extractNameFromEmail(email),
          role: 'Student',
          createdAt: DateTime.now(),
        );

        _view?.hideLoading();
        _view?.onAuthSuccess(userProfile);
      } else {
        _view?.hideLoading();
        _view?.onAuthError('Failed to retrieve user data after login.');
      }
    } catch (e) {
      _view?.hideLoading();
      _view?.onAuthError(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    String role = 'Student',
  }) async {
    if (displayName.trim().isEmpty) {
      _view?.onAuthError('Please enter your full name.');
      return;
    }
    if (email.trim().isEmpty) {
      _view?.onAuthError('Please enter an email address.');
      return;
    }
    if (password.isEmpty) {
      _view?.onAuthError('Please enter a password.');
      return;
    }
    if (password.length < 6) {
      _view?.onAuthError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      _view?.onAuthError('Passwords do not match.');
      return;
    }

    _view?.showLoading();

    try {
      print('🚀 Step 1: Creating Firebase Auth user...');
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('User creation failed - no user returned.');
      }

      print('✅ Step 1 complete! UID: ${firebaseUser.uid}');

      try {
        await firebaseUser.updateDisplayName(displayName.trim());
        print('✅ Updated Auth display name');
      } catch (e) {
        print('⚠️ Could not update Auth display name: $e');
      }

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email.trim(),
        displayName: displayName.trim(),
        role: role,
        createdAt: DateTime.now(),
        bookmarkedLocationIds: const [],
      );

      print('🚀 Step 2: Saving user to Firestore...');

      try {
        await _firestoreService.saveUserProfile(newUser);
        print('✅ Step 2 complete! User saved to Firestore.');
      } catch (firestoreError) {
        print('❌ Firestore save failed: $firestoreError');

        try {
          await firebaseUser.delete();
          print('🗑️ Cleaned up Firebase Auth user because Firestore save failed.');
        } catch (deleteError) {
          print('⚠️ Could not delete auth user: $deleteError');
        }

        throw 'Failed to create user profile: ${firestoreError.toString()}. Please check your internet connection and Firestore rules.';
      }

      _view?.hideLoading();
      _view?.onAuthSuccess(newUser);

    } catch (e) {
      _view?.hideLoading();
      print('❌ Registration error: $e');
      _view?.onAuthError(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _view?.onAuthError(e.toString());
    }
  }

  String _extractNameFromEmail(String email) {
    if (email.contains('@')) {
      final name = email.split('@').first;
      return name[0].toUpperCase() + name.substring(1);
    }
    return 'Campus User';
  }
}
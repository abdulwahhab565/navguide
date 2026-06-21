import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthViewContract {
  void showLoading();
  void hideLoading();
  void showError(String message);
  void onAuthSuccess();
}

class AuthPresenter {
  final AuthViewContract _view;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthPresenter(this._view);

  // ── CHECK IF USER EXISTS ──────────────────────────────────────
  void checkCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('✅ Current user exists: ${user.email} (UID: ${user.uid})');
    } else {
      print('❌ No user is currently signed in');
    }
  }

  // ── LOGIN ──────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    final String trimmedEmail = email.trim();
    final String trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      _view.showError('Please fill in all credentials.');
      return;
    }

    _view.showLoading();
    try {
      await _authService.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      _view.hideLoading();
      await Future.delayed(const Duration(milliseconds: 300));
      _view.onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      _view.hideLoading();
      _view.showError(_getLoginErrorMessage(e));
    } catch (e) {
      _view.hideLoading();
      _view.showError('An unexpected error occurred. Please try again.');
    }
  }

  // ── REGISTER ───────────────────────────────────────────────────
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    required String role,
  }) async {
    // Trim all inputs
    final String trimmedEmail = email.trim();
    final String trimmedPassword = password.trim();
    final String trimmedName = displayName.trim();

    // ── Validation ──────────────────────────────────────────────
    if (trimmedEmail.isEmpty) {
      _view.showError('Email is required.');
      return;
    }
    if (trimmedName.isEmpty) {
      _view.showError('Full name is required.');
      return;
    }
    if (role.isEmpty) {
      _view.showError('Please select a role.');
      return;
    }
    if (trimmedPassword.isEmpty) {
      _view.showError('Password is required.');
      return;
    }
    if (password != confirmPassword) {
      _view.showError('Passwords do not match.');
      return;
    }
    if (trimmedPassword.length < 6) {
      _view.showError('Password must be at least 6 characters.');
      return;
    }

    // Email format validation
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
      _view.showError('Please enter a valid email address.');
      return;
    }

    _view.showLoading();

    try {
      print('🔵 STEP 1: Creating Firebase user...');
      // 1. Create Firebase Auth user
      UserCredential credential = await _authService.signUpWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      User? firebaseUser = credential.user;
      print('🔵 STEP 2: Firebase user created: ${firebaseUser?.uid}');

      if (firebaseUser != null) {
        print('🔵 STEP 3: User created successfully!');

        // ⭐ CHECK: Verify user exists in Firebase Auth
        print('🔍 Checking if user exists in Firebase Auth...');
        checkCurrentUser(); // This will print the user details

        // ⭐ SKIP FIRESTORE FOR NOW - Just create the user
        // We'll add Firestore later

        print('🔵 STEP 4: Hiding loading...');
        _view.hideLoading();

        print('🔵 STEP 5: Waiting 500ms...');
        await Future.delayed(const Duration(milliseconds: 500));

        print('🔵 STEP 6: Calling onAuthSuccess...');
        _view.onAuthSuccess();
        print('✅ STEP 7: Registration complete!');

        // ⭐ FINAL CHECK: Verify user still exists after navigation
        print('🔍 Final check - current user: ${FirebaseAuth.instance.currentUser?.email}');
      } else {
        print('❌ ERROR: Firebase user is null!');
        _view.hideLoading();
        _view.showError('Failed to create user account.');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH ERROR: ${e.code} - ${e.message}');
      _view.hideLoading();
      _view.showError(_getRegisterErrorMessage(e));
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      _view.hideLoading();
      _view.showError('An unexpected error occurred. Please try again.');
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _view.showError('Error signing out: $e');
    }
  }

  // ── ERROR MESSAGES ────────────────────────────────────────────
  String _getLoginErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Login failed: ${e.message}';
    }
  }

  String _getRegisterErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters with letters and numbers.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Registration failed: ${e.message}';
    }
  }
}
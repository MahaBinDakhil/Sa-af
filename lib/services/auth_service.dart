import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Save the user's name in Firebase Authentication.
    if (credential.user != null && name.trim().isNotEmpty) {
      await credential.user!.updateDisplayName(name.trim());
    }

    return credential;
  }

  // Alias in case your Create Account screen uses signUp()
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return createAccount(
      name: name,
      email: email,
      password: password,
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<UserCredential> logIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logOut() async {
    await _auth.signOut();
  }

  // ============================================================
  // ERROR MESSAGES
  // ============================================================

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';

        case 'user-not-found':
          return 'No account was found with this email.';

        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';

        case 'email-already-in-use':
          return 'An account already exists with this email.';

        case 'weak-password':
          return 'Password is too weak. Please use a stronger password.';

        case 'network-request-failed':
          return 'Please check your internet connection and try again.';

        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';

        case 'user-disabled':
          return 'This account has been disabled.';

        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
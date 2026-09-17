import 'package:firebase_auth/firebase_auth.dart';

/// Wraps FirebaseAuth so widgets never call Firebase directly (see CLAUDE.md).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Cross-platform Google OAuth via Firebase's own provider flow — no
  /// separate google_sign_in package needed (see CLAUDE.md > dependencias).
  Future<void> signInWithGoogle() {
    return _auth.signInWithProvider(GoogleAuthProvider());
  }

  Future<void> signOut() => _auth.signOut();
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

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

  /// On web, Firebase's own popup-based OAuth flow works fine. On Android
  /// it doesn't: Chrome's storage-partitioning breaks the Custom-Tabs
  /// redirect signInWithProvider relies on ("missing initial state" error,
  /// found testing on a real device), so native platforms use the
  /// google_sign_in plugin instead and hand Firebase the resulting ID token.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithProvider(GoogleAuthProvider());
      return;
    }
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final account = await googleSignIn.authenticate();
    final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';
import 'main_shell.dart';

/// Routes between the public landing page and the logged-in app shell
/// based on FirebaseAuth's auth state stream (see CLAUDE.md > Auth).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.hasData ? const MainShell() : LandingScreen();
      },
    );
  }
}

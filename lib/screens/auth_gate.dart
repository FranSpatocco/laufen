import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';
import 'main_shell.dart';

/// Entry point: landing first, then the app shell — signed in or not.
/// Being signed in is no longer required to use the app (guest mode, see
/// CLAUDE.md > Auth); it only decides whether runs can be saved. A
/// returning signed-in user skips the landing and lands in the app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authStateChanges = AuthService().authStateChanges;

  /// Once inside the app, stay there: signing out turns the user into a
  /// guest instead of kicking them back to the landing page.
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) _entered = true;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          child: _entered
              ? const MainShell(key: ValueKey('shell'))
              : LandingScreen(
                  key: const ValueKey('landing'),
                  onStart: () => setState(() => _entered = true),
                ),
        );
      },
    );
  }
}

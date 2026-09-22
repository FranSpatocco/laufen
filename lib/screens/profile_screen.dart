import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

/// "Perfil" tab: who's logged in and sign out (see CLAUDE.md > Auth).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.accent,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(email, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: authService.signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

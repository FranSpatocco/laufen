import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/reveal.dart';
import 'login_screen.dart';

/// "Perfil" tab. Signed in: who's logged in and sign out (see CLAUDE.md >
/// Auth). Guest: the pitch to create an account — but with "try a run
/// first" right next to it, since nothing in the app requires an account
/// until there's a run worth saving.
class ProfileScreen extends StatelessWidget {
  final User? user;
  final VoidCallback onTryRun;

  const ProfileScreen({super.key, required this.user, required this.onTryRun});

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: user == null ? _GuestProfile(onTryRun: onTryRun) : _SignedInProfile(user: user),
        ),
      ),
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  final User user;

  const _SignedInProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    final email = user.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Column(
      children: [
        const SizedBox(height: 12),
        Reveal(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.accent,
            child: Text(
              initial,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: const Duration(milliseconds: 80),
          child: Text(email, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 32),
        Reveal(
          delay: const Duration(milliseconds: 160),
          child: OutlinedButton.icon(
            onPressed: AuthService().signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}

class _GuestProfile extends StatelessWidget {
  final VoidCallback onTryRun;

  const _GuestProfile({required this.onTryRun});

  static const _benefits = [
    (Icons.map_outlined, 'Guardá cada carrera con su mapa y sus parciales'),
    (Icons.emoji_events_outlined, 'Seguí tu historial y tus récords personales'),
    (Icons.devices_outlined, 'Tus datos sincronizados en el celular y la web'),
  ];

  void _openLogin(BuildContext context, {required bool register}) {
    // MainShell listens to auth state, so on success this tab rebuilds into
    // the signed-in profile on its own — no need to read the result.
    Navigator.of(context).push(
      FadeSlideRoute(builder: (_) => LoginScreen(startRegistering: register)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const stagger = Duration(milliseconds: 80);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Reveal(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                child: const Icon(Icons.person_outline, size: 36, color: AppTheme.accentDark),
              ),
              const SizedBox(height: 12),
              Text('Estás como invitado', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: stagger,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.accent, AppTheme.accentDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentDark.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Creá tu cuenta gratis',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Te lleva un minuto, con Google o con tu email.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < _benefits.length; i++)
                  Reveal(
                    delay: stagger * (2 + i),
                    offsetY: 12,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(_benefits[i].$1, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_benefits[i].$2, style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.accentDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _openLogin(context, register: true),
                    child: const Text('Crear cuenta'),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => _openLogin(context, register: false),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Reveal(
          delay: stagger * 5,
          child: Column(
            children: [
              Text(
                '¿Preferís probar primero?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Hacé una carrera sin cuenta. Al terminar decidís si la guardás.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onTryRun,
                icon: const Icon(Icons.directions_run),
                label: const Text('Probar una carrera'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/runs_service.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/reveal.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

/// "Perfil" tab. Signed in: personal data (age, weight, level, goal...),
/// weekly km goal progress and sign out (see CLAUDE.md > Auth). Guest: the pitch to create an account — but with "try a run
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

class _SignedInProfile extends StatefulWidget {
  final User user;

  const _SignedInProfile({required this.user});

  @override
  State<_SignedInProfile> createState() => _SignedInProfileState();
}

class _SignedInProfileState extends State<_SignedInProfile> {
  late final Stream<UserProfile?> _profile = FirestoreService().watchProfile(widget.user.uid);
  late final Stream<List<RunModel>> _runs = RunsService().watchRuns(widget.user.uid);

  void _edit(UserProfile? current) {
    Navigator.of(context).push(
      FadeSlideRoute(builder: (_) => EditProfileScreen(uid: widget.user.uid, initial: current)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const stagger = Duration(milliseconds: 80);
    final email = widget.user.email ?? '';

    return StreamBuilder<UserProfile?>(
      stream: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final hasData = profile != null && !profile.isEmpty;
        final name = profile?.name ?? '';
        final initialSource = name.isNotEmpty ? name : email;
        final initial = initialSource.isNotEmpty ? initialSource[0].toUpperCase() : '?';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Reveal(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.accent,
                    child: Text(
                      initial,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (name.isNotEmpty)
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Reveal(
              delay: stagger,
              child: hasData ? _ProfileFacts(profile: profile) : _CompleteProfileCard(onTap: () => _edit(profile)),
            ),
            const SizedBox(height: 16),
            Reveal(
              delay: stagger * 2,
              child: StreamBuilder<List<RunModel>>(
                stream: _runs,
                builder: (context, runsSnapshot) => _WeeklyGoalCard(
                  runs: runsSnapshot.data ?? const [],
                  goalKm: profile?.weeklyGoalKm ?? UserProfile.defaultWeeklyGoalKm,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Reveal(
              delay: stagger * 3,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (hasData)
                    FilledButton.tonalIcon(
                      onPressed: () => _edit(profile),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar perfil'),
                    ),
                  OutlinedButton.icon(
                    onPressed: AuthService().signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompleteProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CompleteProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.accentDark, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completá tu perfil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Edad, peso, experiencia y tu objetivo: te lleva 30 segundos.'),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.accentDark),
            ],
          ),
        ),
      ),
    );
  }
}

/// The answered questions as small tiles — unanswered ones are skipped.
class _ProfileFacts extends StatelessWidget {
  final UserProfile profile;

  const _ProfileFacts({required this.profile});

  @override
  Widget build(BuildContext context) {
    final weight = profile.weightKg;
    final facts = [
      if (profile.age != null) (Icons.cake_outlined, 'Edad', '${profile.age} años'),
      if (weight != null)
        (
          Icons.monitor_weight_outlined,
          'Peso',
          '${weight == weight.roundToDouble() ? weight.toInt() : weight.toStringAsFixed(1)} kg',
        ),
      if (profile.heightCm != null) (Icons.height, 'Altura', '${profile.heightCm} cm'),
      if (profile.level != null) (Icons.trending_up, 'Nivel', profile.level!.label),
      if (profile.goal != null) (Icons.flag_outlined, 'Objetivo', profile.goal!.label),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final (icon, label, value) in facts)
          Container(
            constraints: const BoxConstraints(minWidth: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.accent, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Progress towards the weekly km goal (Monday to now), computed
/// client-side from the same runs stream the dashboard uses.
class _WeeklyGoalCard extends StatelessWidget {
  final List<RunModel> runs;
  final double goalKm;

  const _WeeklyGoalCard({required this.runs, required this.goalKm});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekKm =
        runs.where((r) => !r.date.isBefore(weekStart)).fold<double>(0, (sum, r) => sum + r.distanceKm);
    final progress = goalKm <= 0 ? 0.0 : (weekKm / goalKm).clamp(0.0, 1.0);
    final done = weekKm >= goalKm;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(done ? Icons.emoji_events : Icons.calendar_today_outlined, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Meta semanal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${weekKm.toStringAsFixed(1)} / ${goalKm.round()} km',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fills from 0 on first build, like the dashboard counters.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                color: AppTheme.accent,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            done
                ? '¡Cumpliste tu meta de esta semana!'
                : 'Te faltan ${(goalKm - weekKm).toStringAsFixed(1)} km para cumplirla.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
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

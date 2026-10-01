import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../services/runs_service.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'run_detail_screen.dart';

/// "Historial" tab: the user's runs, most recent first
/// (see CLAUDE.md > Historial). Embedded directly in MainShell, so it has
/// no Scaffold/AppBar of its own. A guest ([uid] null) sees the example
/// run plus a nudge to sign in and keep their own.
class HistoryScreen extends StatelessWidget {
  final String? uid;

  const HistoryScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final isGuest = uid == null;

    return StreamBuilder<List<RunModel>>(
      stream: RunsService().watchRuns(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final runs = snapshot.data ?? const <RunModel>[];
        if (runs.isEmpty) {
          return const Center(child: Text('Todavía no registraste ninguna carrera.'));
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: runs.length + (isGuest ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (isGuest && index == 0) return const _GuestBanner();
            final run = runs[index - (isGuest ? 1 : 0)];
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                  child: Icon(run.type.icon, color: AppTheme.accentDark),
                ),
                title: Text(RunFormatters.distanceKm(run.distanceKm)),
                subtitle: Text(
                  '${run.isSample ? 'Ejemplo · ' : ''}${run.type.label} · ${run.date.day.toString().padLeft(2, '0')}/${run.date.month.toString().padLeft(2, '0')}/${run.date.year} · '
                  '${RunFormatters.duration(run.durationSeconds)} · ${RunFormatters.pace(run.avgPaceMinPerKm)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  FadeSlideRoute(builder: (_) => RunDetailScreen(run: run)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppTheme.accentDark),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Esta es una carrera de ejemplo. Iniciá sesión para guardar las tuyas.'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              FadeSlideRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }
}

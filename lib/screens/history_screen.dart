import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import 'run_detail_screen.dart';

/// "Historial" tab: the user's runs, most recent first
/// (see CLAUDE.md > Historial). Embedded directly in MainShell, so it has
/// no Scaffold/AppBar of its own.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;

    return StreamBuilder<List<RunModel>>(
      stream: FirestoreService().watchRuns(uid),
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
          itemCount: runs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final run = runs[index];
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
                  '${run.type.label} · ${run.date.day.toString().padLeft(2, '0')}/${run.date.month.toString().padLeft(2, '0')}/${run.date.year} · '
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

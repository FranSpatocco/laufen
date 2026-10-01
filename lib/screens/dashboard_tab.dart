import 'package:flutter/material.dart';

import '../models/run_model.dart';
import '../services/runs_service.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/animated_stat_tile.dart';
import '../widgets/reveal.dart';
import 'run_detail_screen.dart';

/// "Inicio" tab: dashboard stats (client-side aggregation over
/// users/{uid}/runs, see CLAUDE.md > Funcionalidad core) plus a shortcut
/// into training and a peek at recent activity. A guest ([uid] null) sees
/// the same dashboard built from the example run (RunsService).
///
/// Sections enter with a staggered Reveal (tiles first, then the CTA, then
/// recent activity) so the screen builds itself up instead of popping in.
class DashboardTab extends StatelessWidget {
  final String? uid;
  final VoidCallback onStartTraining;
  final VoidCallback onViewHistory;

  const DashboardTab({super.key, required this.uid, required this.onStartTraining, required this.onViewHistory});

  static const _stagger = Duration(milliseconds: 70);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RunModel>>(
      stream: RunsService().watchRuns(uid),
      builder: (context, snapshot) {
        final runs = snapshot.data ?? const <RunModel>[];
        final totalKm = runs.fold<double>(0, (sum, r) => sum + r.distanceKm);
        final bestPace = runs.isEmpty ? 0.0 : runs.map((r) => r.avgPaceMinPerKm).reduce((a, b) => a < b ? a : b);
        final longestKm = runs.isEmpty ? 0.0 : runs.map((r) => r.distanceKm).reduce((a, b) => a > b ? a : b);
        final recentRuns = runs.take(3).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // 4 tiles in a row on desktop, 2x2 on phones.
                  final wide = constraints.maxWidth >= 720;
                  final tiles = [
                    AnimatedStatTile(
                      value: totalKm,
                      formatter: RunFormatters.distanceKm,
                      label: 'Total',
                      icon: Icons.route_outlined,
                    ),
                    AnimatedStatTile(
                      value: runs.length.toDouble(),
                      formatter: (v) => v.round().toString(),
                      label: 'Carreras',
                      icon: Icons.event_repeat_outlined,
                    ),
                    AnimatedStatTile(
                      value: bestPace,
                      formatter: (v) => runs.isEmpty ? '--:--' : RunFormatters.pace(v),
                      label: 'Mejor pace',
                      icon: Icons.speed_outlined,
                    ),
                    AnimatedStatTile(
                      value: longestKm,
                      formatter: (v) => runs.isEmpty ? '--' : RunFormatters.distanceKm(v),
                      label: 'Carrera más larga',
                      icon: Icons.emoji_events_outlined,
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: wide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: wide ? 1.9 : 1.5,
                    children: [for (var i = 0; i < tiles.length; i++) Reveal(delay: _stagger * i, child: tiles[i])],
                  );
                },
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: _stagger * 4,
                child: _StartTrainingCard(onTap: onStartTraining),
              ),
              if (recentRuns.isNotEmpty) ...[
                const SizedBox(height: 28),
                Reveal(
                  delay: _stagger * 5,
                  child: Row(
                    children: [
                      Text('Actividad reciente', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(onPressed: onViewHistory, child: const Text('Ver todo')),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < recentRuns.length; i++)
                  Reveal(
                    delay: _stagger * (6 + i),
                    child: _RecentRunTile(run: recentRuns[i]),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StartTrainingCard extends StatelessWidget {
  final VoidCallback onTap;

  const _StartTrainingCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.accent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.directions_run, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Empezar a entrenar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Carrera libre, trote, caminata o intervalos',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRunTile extends StatelessWidget {
  final RunModel run;

  const _RecentRunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
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
          '${run.isSample ? 'Ejemplo · ' : ''}${run.type.label} · ${RunFormatters.duration(run.durationSeconds)} · ${RunFormatters.pace(run.avgPaceMinPerKm)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(FadeSlideRoute(builder: (_) => RunDetailScreen(run: run))),
      ),
    );
  }
}

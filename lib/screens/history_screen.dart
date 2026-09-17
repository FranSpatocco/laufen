import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import 'run_detail_screen.dart';

/// List of the user's runs, most recent first (see CLAUDE.md > Historial).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: StreamBuilder<List<RunModel>>(
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
            padding: const EdgeInsets.all(16),
            itemCount: runs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final run = runs[index];
              return Card(
                child: ListTile(
                  title: Text(RunFormatters.distanceKm(run.distanceKm)),
                  subtitle: Text(
                    '${run.date.day.toString().padLeft(2, '0')}/${run.date.month.toString().padLeft(2, '0')}/${run.date.year} · '
                    '${RunFormatters.duration(run.durationSeconds)} · ${RunFormatters.pace(run.avgPaceMinPerKm)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RunDetailScreen(run: run)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

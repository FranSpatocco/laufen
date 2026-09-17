import 'package:flutter/material.dart';
import '../models/run_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/stat_display.dart';
import 'history_screen.dart';
import 'live_run_screen.dart';

/// Logged-in home: dashboard stats (client-side aggregation over
/// users/{uid}/runs, see CLAUDE.md > Funcionalidad core) plus the entry
/// point to start a new run and to the full history.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final uid = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laufen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: authService.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<RunModel>>(
          stream: FirestoreService().watchRuns(uid),
          builder: (context, snapshot) {
            final runs = snapshot.data ?? const <RunModel>[];
            final totalKm = runs.fold<double>(0, (sum, r) => sum + r.distanceKm);
            final bestPace = runs.isEmpty
                ? 0.0
                : runs.map((r) => r.avgPaceMinPerKm).reduce((a, b) => a < b ? a : b);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatDisplay(value: RunFormatters.distanceKm(totalKm), label: 'Total'),
                      StatDisplay(value: '${runs.length}', label: 'Carreras'),
                      StatDisplay(
                        value: runs.isEmpty ? '--:--' : RunFormatters.pace(bestPace),
                        label: 'Mejor pace',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: const Icon(Icons.directions_run),
                    label: const Text('Empezar a correr'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LiveRunScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    child: const Text('Ver historial'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

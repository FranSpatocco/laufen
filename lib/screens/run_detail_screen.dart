import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/run_model.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/splits_table.dart';
import '../widgets/stat_display.dart';

/// Detail of a single past run: its route on a map plus its stats
/// (see CLAUDE.md > Historial).
class RunDetailScreen extends StatelessWidget {
  final RunModel run;

  const RunDetailScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    // A single point can't draw a line and produces a degenerate (zero-size)
    // camera bounds, so treat it the same as no route.
    final hasRoute = run.route.length >= 2;

    final map = hasRoute
        ? FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(run.route),
                padding: const EdgeInsets.all(40),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.laufen.laufen',
              ),
              PolylineLayer(polylines: [
                Polyline(points: run.route, strokeWidth: 4, color: AppTheme.accent),
              ]),
            ],
          )
        : const Center(child: Text('Esta carrera no tiene ruta registrada.'));

    final stats = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StatDisplay(value: RunFormatters.distanceKm(run.distanceKm), label: 'Distancia'),
        StatDisplay(value: RunFormatters.duration(run.durationSeconds), label: 'Tiempo'),
        StatDisplay(value: RunFormatters.pace(run.avgPaceMinPerKm), label: 'Pace'),
      ],
    );

    // On a desktop browser the map takes the left side and stats + splits
    // live in a side panel, instead of a phone layout stretched sideways.
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(RunFormatters.distanceKm(run.distanceKm)),
        actions: [
          if (run.isSample)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(label: Text('Ejemplo'), side: BorderSide.none),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(run.type.icon, size: 18, color: AppTheme.accentDark),
              label: Text(run.type.label),
              backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                Expanded(child: map),
                SizedBox(
                  width: 420,
                  child: SafeArea(
                    left: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          stats,
                          if (run.splits.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            SplitsTable(splits: run.splits, avgPaceMinPerKm: run.avgPaceMinPerKm),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(flex: 5, child: map),
                // The map stays edge-to-edge; only the stats row needs to clear
                // the bottom system nav bar (see live_run_screen.dart for the
                // same issue — found testing on a 3-button-nav Android phone).
                SafeArea(
                  top: false,
                  // When the splits table sits below, it's the one touching the
                  // bottom edge and clears the nav bar instead.
                  bottom: run.splits.isEmpty,
                  child: Padding(padding: const EdgeInsets.all(24), child: stats),
                ),
                // Splits get their own scrollable area below the stats, instead of
                // putting the map inside a scroll view (the map's pan gesture and
                // the list's vertical scroll would fight each other).
                if (run.splits.isNotEmpty)
                  Expanded(
                    flex: 4,
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: SplitsTable(splits: run.splits, avgPaceMinPerKm: run.avgPaceMinPerKm),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

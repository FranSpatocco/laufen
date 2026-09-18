import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/run_model.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/stat_display.dart';

/// Detail of a single past run: its route on a map plus its stats
/// (see CLAUDE.md > Historial).
class RunDetailScreen extends StatelessWidget {
  final RunModel run;

  const RunDetailScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final hasRoute = run.route.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(RunFormatters.distanceKm(run.distanceKm))),
      body: Column(
        children: [
          Expanded(
            child: hasRoute
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
                        Polyline(points: run.route, strokeWidth: 4, color: AppTheme.accentOrange),
                      ]),
                    ],
                  )
                : const Center(child: Text('Esta carrera no tiene ruta registrada.')),
          ),
          // The map stays edge-to-edge; only the stats row needs to clear
          // the bottom system nav bar (see live_run_screen.dart for the
          // same issue — found testing on a 3-button-nav Android phone).
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatDisplay(value: RunFormatters.distanceKm(run.distanceKm), label: 'Distancia'),
                  StatDisplay(value: RunFormatters.duration(run.durationSeconds), label: 'Tiempo'),
                  StatDisplay(value: RunFormatters.pace(run.avgPaceMinPerKm), label: 'Pace'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';
import 'km_split.dart';
import 'run_model.dart';
import 'training_type.dart';

/// A built-in example run shown to guests (not signed in), so Inicio,
/// Historial and the run detail aren't empty on a first visit — especially
/// on a desktop browser, where there's no real GPS movement to record.
/// Never written to Firestore; flagged in the UI as "Ejemplo".
class SampleRun {
  static const id = 'sample';

  static final RunModel run = RunModel(
    id: id,
    date: DateTime.now().subtract(const Duration(days: 1)),
    distanceKm: 3.21,
    durationSeconds: 1043,
    avgPaceMinPerKm: (1043 / 60) / 3.21,
    route: _loopRoute(),
    type: TrainingType.freeRun,
    splits: const [
      KmSplit(distanceKm: 1, durationSeconds: 335),
      KmSplit(distanceKm: 1, durationSeconds: 328),
      KmSplit(distanceKm: 1, durationSeconds: 316),
      KmSplit(distanceKm: 0.21, durationSeconds: 64),
    ],
  );

  /// A ~3.2 km loop through the Bosques de Palermo (Buenos Aires), laid out
  /// as an elongated, slightly wobbly ellipse around the Rosedal lake, between
  /// Av. del Libertador and the railway — reads like a real GPS track without shipping a hardcoded
  /// list of hundreds of coordinates.
  static List<LatLng> _loopRoute() {
    const center = LatLng(-34.5710, -58.4129);
    const semiMajorKm = 0.72;
    const semiMinorKm = 0.24;
    // The park runs ~22° south of east; rotate the ellipse to match.
    const angle = -22 * math.pi / 180;
    const kmPerDegLat = 111.0;
    final kmPerDegLng = 111.0 * math.cos(center.latitude * math.pi / 180);
    const points = 160;
    return [
      for (var i = 0; i <= points; i++)
        () {
          final t = 2 * math.pi * i / points;
          final wobble = 1 + 0.04 * math.sin(4 * t) + 0.02 * math.cos(7 * t);
          final x = semiMajorKm * math.cos(t) * wobble;
          final y = semiMinorKm * math.sin(t) * wobble;
          final eastKm = x * math.cos(angle) - y * math.sin(angle);
          final northKm = x * math.sin(angle) + y * math.cos(angle);
          return LatLng(
            center.latitude + northKm / kmPerDegLat,
            center.longitude + eastKm / kmPerDegLng,
          );
        }(),
    ];
  }
}

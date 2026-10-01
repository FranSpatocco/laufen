import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'km_split.dart';
import 'training_type.dart';

/// A completed run, stored under users/{uid}/runs/{runId} (see CLAUDE.md).
class RunModel {
  final String? id;
  final DateTime date;
  final double distanceKm;
  final int durationSeconds;
  final double avgPaceMinPerKm;
  final List<LatLng> route;
  final TrainingType type;

  /// Per-km splits. Empty for runs saved before splits existed — their
  /// route has no timestamps, so they can't be reconstructed afterwards.
  final List<KmSplit> splits;

  const RunModel({
    this.id,
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPaceMinPerKm,
    required this.route,
    this.type = TrainingType.freeRun,
    this.splits = const [],
  });

  /// The built-in example run guests see (models/sample_run.dart).
  bool get isSample => id == 'sample';

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'avg_pace': avgPaceMinPerKm,
        'route': route.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'type': type.storageKey,
        'splits': splits.map((s) => s.toMap()).toList(),
      };

  factory RunModel.fromMap(String id, Map<String, dynamic> map) {
    final rawRoute = (map['route'] as List?) ?? const [];
    return RunModel(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      distanceKm: (map['distance_km'] as num).toDouble(),
      durationSeconds: (map['duration_seconds'] as num).toInt(),
      avgPaceMinPerKm: (map['avg_pace'] as num).toDouble(),
      route: rawRoute
          .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
          .toList(),
      // Older runs saved before training types existed don't have this
      // field — fromStorageKey(null) falls back to freeRun.
      type: TrainingType.fromStorageKey(map['type'] as String?),
      splits: ((map['splits'] as List?) ?? const [])
          .map((s) => KmSplit.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}

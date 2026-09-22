import 'package:flutter/material.dart';

/// Training variants for a run — all use the same RunModel/live-tracking
/// flow, only the label, icon and stored `type` differ (see CLAUDE.md).
enum TrainingType {
  freeRun('carrera_libre', 'Carrera libre', Icons.directions_run),
  jog('trote', 'Trote', Icons.directions_walk),
  walk('caminata', 'Caminata', Icons.hiking);

  const TrainingType(this.storageKey, this.label, this.icon);

  final String storageKey;
  final String label;
  final IconData icon;

  static TrainingType fromStorageKey(String? key) {
    return TrainingType.values.firstWhere(
      (t) => t.storageKey == key,
      orElse: () => TrainingType.freeRun,
    );
  }
}

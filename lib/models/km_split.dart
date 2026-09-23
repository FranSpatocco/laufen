/// One per-kilometer split of a run. Every split is 1 km except possibly
/// the last one, which holds the leftover distance (e.g. the 0.43 of a
/// 5.43 km run) — same convention Strava uses.
class KmSplit {
  final double distanceKm;
  final int durationSeconds;

  const KmSplit({required this.distanceKm, required this.durationSeconds});

  /// Decimal minutes per km, same unit as RunModel.avgPaceMinPerKm. For the
  /// partial last split this is normalized to a full km, so it's comparable.
  double get paceMinPerKm => distanceKm <= 0 ? 0 : (durationSeconds / 60) / distanceKm;

  bool get isPartial => distanceKm < 0.999;

  Map<String, dynamic> toMap() => {
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
      };

  factory KmSplit.fromMap(Map<String, dynamic> map) => KmSplit(
        distanceKm: (map['distance_km'] as num).toDouble(),
        durationSeconds: (map['duration_seconds'] as num).toInt(),
      );
}

/// Turns the stream of accepted GPS fixes into per-km splits while the run
/// is live. Kept free of Flutter/geolocator so the math is unit-testable.
///
/// GPS fixes arrive every few meters, so the exact moment a km boundary was
/// crossed usually falls *between* two fixes — we interpolate linearly
/// inside that segment instead of snapping to the next fix, otherwise every
/// split would be off by a few seconds.
class KmSplitTracker {
  final List<KmSplit> _completed = [];
  double _distanceMeters = 0;
  double _lastElapsedSeconds = 0;
  double _splitStartSeconds = 0;

  List<KmSplit> get completed => List.unmodifiable(_completed);

  /// Registers a new segment: [segmentMeters] covered, ending at
  /// [elapsedSeconds] since the run started.
  void addSegment(double segmentMeters, double elapsedSeconds) {
    final segmentStartMeters = _distanceMeters;
    final segmentStartSeconds = _lastElapsedSeconds;
    _distanceMeters += segmentMeters;
    _lastElapsedSeconds = elapsedSeconds;

    // A while-loop rather than an if: one long segment (e.g. after a GPS
    // gap) could in theory cross more than one km boundary.
    while (_distanceMeters >= (_completed.length + 1) * 1000) {
      final boundaryMeters = (_completed.length + 1) * 1000.0;
      final fraction = (boundaryMeters - segmentStartMeters) / segmentMeters;
      final crossedAt = segmentStartSeconds + fraction * (elapsedSeconds - segmentStartSeconds);
      _completed.add(KmSplit(
        distanceKm: 1,
        durationSeconds: (crossedAt - _splitStartSeconds).round(),
      ));
      _splitStartSeconds = crossedAt;
    }
  }

  /// All splits, including the in-progress partial km, closed at
  /// [totalElapsedSeconds] — called once when the run is finished.
  List<KmSplit> finish(double totalElapsedSeconds) {
    final leftoverKm = (_distanceMeters - _completed.length * 1000) / 1000;
    return [
      ..._completed,
      // Ignore a few meters of GPS drift after the last full km.
      if (leftoverKm >= 0.01)
        KmSplit(
          distanceKm: leftoverKm,
          durationSeconds: (totalElapsedSeconds - _splitStartSeconds).round(),
        ),
    ];
  }
}

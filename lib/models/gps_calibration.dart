/// Decides when the GPS is good enough to start a run. Pure Dart so the
/// rules are unit-tested (test/gps_calibration_test.dart).
///
/// There's no fixed "GPS warm-up time": with a recent fix (warm start) a
/// precise reading arrives in a few seconds, from cold it can take 30 s or
/// more. So instead of waiting a fixed time, we wait for the signal itself
/// to be good — [requiredGoodFixes] consecutive readings within
/// [goodAccuracyMeters] — plus a short [minDuration] so a single lucky fix
/// can't start the run and the runner has a moment to put the phone away.
/// If it never gets there (indoors, a desktop browser), [fallbackAfter]
/// lets the user start anyway.
class GpsCalibration {
  static const goodAccuracyMeters = 15.0;
  static const minDuration = Duration(seconds: 3);
  static const fallbackAfter = Duration(seconds: 30);

  /// Accuracy at or above this shows as "no signal" (0 quality).
  static const _worstAccuracyMeters = 100.0;

  /// 2 on phones (native GPS delivers ~1 fix/s). Browsers only report a
  /// new position when it changes, so a runner standing still may get a
  /// single fix — the web asks for 1.
  final int requiredGoodFixes;

  GpsCalibration({this.requiredGoodFixes = 2});

  int _goodStreak = 0;
  double? _lastAccuracy;

  double? get lastAccuracyMeters => _lastAccuracy;

  void addFix(double accuracyMeters) {
    _lastAccuracy = accuracyMeters;
    _goodStreak = accuracyMeters <= goodAccuracyMeters ? _goodStreak + 1 : 0;
  }

  bool isReady(Duration elapsed) => elapsed >= minDuration && _goodStreak >= requiredGoodFixes;

  bool canStartAnyway(Duration elapsed) => elapsed >= fallbackAfter;

  /// 0 (no fix / terrible) → 1 (good enough), for the signal bar.
  double get quality {
    final accuracy = _lastAccuracy;
    if (accuracy == null) return 0;
    if (accuracy <= goodAccuracyMeters) return 1;
    final t = (accuracy - goodAccuracyMeters) / (_worstAccuracyMeters - goodAccuracyMeters);
    return (1 - t).clamp(0.0, 1.0);
  }
}

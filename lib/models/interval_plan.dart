/// Run/walk interval training: the user picks how long each running and
/// walking stretch lasts, and they alternate (run first) until the run is
/// finished. Pure Dart — the phase math is unit-tested in
/// test/interval_plan_test.dart.
class IntervalPlan {
  final int runSeconds;
  final int walkSeconds;

  const IntervalPlan({required this.runSeconds, required this.walkSeconds});

  int get cycleSeconds => runSeconds + walkSeconds;

  /// Where in the plan we are after [elapsedSeconds] of tracking. Derived
  /// from the run's stopwatch instead of a separate countdown timer, so it
  /// can never drift from the run's total time.
  IntervalStatus statusAt(int elapsedSeconds) {
    final inCycle = elapsedSeconds % cycleSeconds;
    final round = elapsedSeconds ~/ cycleSeconds + 1;
    if (inCycle < runSeconds) {
      return IntervalStatus(
        phase: IntervalPhase.run,
        round: round,
        remainingSeconds: runSeconds - inCycle,
        phaseSeconds: runSeconds,
      );
    }
    return IntervalStatus(
      phase: IntervalPhase.walk,
      round: round,
      remainingSeconds: cycleSeconds - inCycle,
      phaseSeconds: walkSeconds,
    );
  }

  Map<String, dynamic> toMap() => {'run_seconds': runSeconds, 'walk_seconds': walkSeconds};

  factory IntervalPlan.fromMap(Map<String, dynamic> map) => IntervalPlan(
        runSeconds: (map['run_seconds'] as num).toInt(),
        walkSeconds: (map['walk_seconds'] as num).toInt(),
      );
}

enum IntervalPhase { run, walk }

class IntervalStatus {
  final IntervalPhase phase;

  /// 1-based: one round = one running stretch + one walking stretch.
  final int round;
  final int remainingSeconds;
  final int phaseSeconds;

  const IntervalStatus({
    required this.phase,
    required this.round,
    required this.remainingSeconds,
    required this.phaseSeconds,
  });

  /// 0 → 1 across the current stretch, for a progress bar.
  double get progress => 1 - remainingSeconds / phaseSeconds;
}

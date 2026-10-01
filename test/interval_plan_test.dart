import 'package:flutter_test/flutter_test.dart';
import 'package:laufen/models/interval_plan.dart';
import 'package:laufen/models/user_profile.dart';

void main() {
  const plan = IntervalPlan(runSeconds: 120, walkSeconds: 60);

  test('starts running, with the full running stretch left', () {
    final s = plan.statusAt(0);
    expect(s.phase, IntervalPhase.run);
    expect(s.round, 1);
    expect(s.remainingSeconds, 120);
  });

  test('switches to walking exactly when the running stretch ends', () {
    expect(plan.statusAt(119).phase, IntervalPhase.run);
    expect(plan.statusAt(119).remainingSeconds, 1);
    final s = plan.statusAt(120);
    expect(s.phase, IntervalPhase.walk);
    expect(s.remainingSeconds, 60);
    expect(s.round, 1);
  });

  test('a new round starts running again after the walk', () {
    final s = plan.statusAt(180);
    expect(s.phase, IntervalPhase.run);
    expect(s.round, 2);
    expect(s.remainingSeconds, 120);
    expect(plan.statusAt(180 * 3 + 150).round, 4);
  });

  test('interval plan round-trips through Firestore map', () {
    final back = IntervalPlan.fromMap(plan.toMap());
    expect(back.runSeconds, 120);
    expect(back.walkSeconds, 60);
  });

  test('user profile round-trips and unknown/missing values stay null', () {
    const profile = UserProfile(
      name: 'Ana',
      age: 31,
      weightKg: 58.5,
      heightCm: 165,
      level: RunnerLevel.intermediate,
      goal: RunnerGoal.race,
      weeklyGoalKm: 25,
    );
    final back = UserProfile.fromMap(profile.toMap());
    expect(back.name, 'Ana');
    expect(back.weightKg, 58.5);
    expect(back.level, RunnerLevel.intermediate);
    expect(back.goal, RunnerGoal.race);
    expect(back.weeklyGoalKm, 25);

    final empty = UserProfile.fromMap({'level': 'otro'});
    expect(empty.level, isNull);
    expect(empty.isEmpty, isTrue);
    expect(empty.weeklyGoalKm, UserProfile.defaultWeeklyGoalKm);
  });
}

/// The runner's personal data, filled in from Perfil → "Editar perfil".
/// Stored as a `profile` map on the users/{uid} document (the same doc
/// that owns the runs subcollection, so the existing security rules
/// already cover it). Every field is optional — nobody is forced to
/// answer before using the app.
class UserProfile {
  final String name;
  final int? age;
  final double? weightKg;
  final int? heightCm;
  final RunnerLevel? level;
  final RunnerGoal? goal;
  final double weeklyGoalKm;

  static const defaultWeeklyGoalKm = 15.0;

  const UserProfile({
    this.name = '',
    this.age,
    this.weightKg,
    this.heightCm,
    this.level,
    this.goal,
    this.weeklyGoalKm = defaultWeeklyGoalKm,
  });

  /// True until the user saves the form at least once with some data.
  bool get isEmpty =>
      name.isEmpty && age == null && weightKg == null && heightCm == null && level == null && goal == null;

  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'level': level?.storageKey,
        'goal': goal?.storageKey,
        'weekly_goal_km': weeklyGoalKm,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        name: (map['name'] as String?) ?? '',
        age: (map['age'] as num?)?.toInt(),
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        heightCm: (map['height_cm'] as num?)?.toInt(),
        level: RunnerLevel.fromStorageKey(map['level'] as String?),
        goal: RunnerGoal.fromStorageKey(map['goal'] as String?),
        weeklyGoalKm: (map['weekly_goal_km'] as num?)?.toDouble() ?? defaultWeeklyGoalKm,
      );
}

enum RunnerLevel {
  beginner('principiante', 'Principiante'),
  intermediate('intermedio', 'Intermedio'),
  advanced('avanzado', 'Avanzado');

  const RunnerLevel(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static RunnerLevel? fromStorageKey(String? key) {
    for (final level in values) {
      if (level.storageKey == key) return level;
    }
    return null;
  }
}

enum RunnerGoal {
  health('salud', 'Salud y bienestar'),
  weightLoss('bajar_peso', 'Bajar de peso'),
  speed('mejorar_tiempos', 'Mejorar mis tiempos'),
  race('preparar_carrera', 'Preparar una carrera');

  const RunnerGoal(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static RunnerGoal? fromStorageKey(String? key) {
    for (final goal in values) {
      if (goal.storageKey == key) return goal;
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../utils/theme.dart';

/// Form for the runner's personal data (Perfil → "Editar perfil"). Every
/// question is optional — only what's filled in gets shown on the profile.
class EditProfileScreen extends StatefulWidget {
  final String uid;
  final UserProfile? initial;

  const EditProfileScreen({super.key, required this.uid, this.initial});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _age = TextEditingController(text: widget.initial?.age?.toString() ?? '');
  late final _weight = TextEditingController(text: _formatWeight(widget.initial?.weightKg));
  late final _height = TextEditingController(text: widget.initial?.heightCm?.toString() ?? '');
  late RunnerLevel? _level = widget.initial?.level;
  late RunnerGoal? _goal = widget.initial?.goal;
  late double _weeklyGoalKm =
      (widget.initial?.weeklyGoalKm ?? UserProfile.defaultWeeklyGoalKm).clamp(5, 100).toDouble();

  static String _formatWeight(double? kg) {
    if (kg == null) return '';
    return kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  /// Validator for an optional number field: empty is fine, otherwise it
  /// must parse and fall inside a sane range.
  String? Function(String?) _range(num min, num max, String unit) {
    return (value) {
      final text = value?.trim().replaceAll(',', '.') ?? '';
      if (text.isEmpty) return null;
      final n = num.tryParse(text);
      if (n == null || n < min || n > max) return 'Entre $min y $max $unit';
      return null;
    };
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    num? parse(TextEditingController c) => num.tryParse(c.text.trim().replaceAll(',', '.'));
    FirestoreService().saveProfile(
      widget.uid,
      UserProfile(
        name: _name.text.trim(),
        age: parse(_age)?.toInt(),
        weightKg: parse(_weight)?.toDouble(),
        heightCm: parse(_height)?.toInt(),
        level: _level,
        goal: _goal,
        weeklyGoalKm: _weeklyGoalKm,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil guardado'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionStyle = Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final digitsOnly = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Sobre vos', style: sectionStyle),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: '¿Cómo te llamás?'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _age,
                            keyboardType: TextInputType.number,
                            inputFormatters: digitsOnly,
                            decoration: const InputDecoration(labelText: 'Edad', suffixText: 'años'),
                            validator: _range(10, 100, 'años'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _weight,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Peso', suffixText: 'kg'),
                            validator: _range(30, 250, 'kg'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _height,
                            keyboardType: TextInputType.number,
                            inputFormatters: digitsOnly,
                            decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm'),
                            validator: _range(100, 230, 'cm'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text('¿Cuánta experiencia tenés corriendo?', style: sectionStyle),
                    const SizedBox(height: 12),
                    SegmentedButton<RunnerLevel>(
                      segments: [
                        for (final level in RunnerLevel.values)
                          ButtonSegment(value: level, label: Text(level.label)),
                      ],
                      selected: {?_level},
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _level = s.isEmpty ? null : s.first),
                    ),
                    const SizedBox(height: 28),
                    Text('¿Cuál es tu objetivo principal?', style: sectionStyle),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final goal in RunnerGoal.values)
                          ChoiceChip(
                            label: Text(goal.label),
                            selected: _goal == goal,
                            onSelected: (selected) => setState(() => _goal = selected ? goal : null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: Text('¿Cuántos km querés correr por semana?', style: sectionStyle)),
                        Text(
                          '${_weeklyGoalKm.round()} km',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.accentDark,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _weeklyGoalKm,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: '${_weeklyGoalKm.round()} km',
                      onChanged: (v) => setState(() => _weeklyGoalKm = v),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _save,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

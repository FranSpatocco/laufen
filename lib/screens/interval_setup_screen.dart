import 'package:flutter/material.dart';
import '../models/interval_plan.dart';
import '../models/training_type.dart';
import '../utils/formatters.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/reveal.dart';
import 'live_run_screen.dart';

/// Set up interval training before starting: how long each running and
/// walking stretch lasts. They alternate (running first) until the user
/// taps "Finalizar" — no fixed number of rounds to configure.
class IntervalSetupScreen extends StatefulWidget {
  const IntervalSetupScreen({super.key});

  @override
  State<IntervalSetupScreen> createState() => _IntervalSetupScreenState();
}

class _IntervalSetupScreenState extends State<IntervalSetupScreen> {
  static const _presets = [
    ('Principiante', IntervalPlan(runSeconds: 60, walkSeconds: 120)),
    ('Intermedio', IntervalPlan(runSeconds: 180, walkSeconds: 60)),
    ('Avanzado', IntervalPlan(runSeconds: 300, walkSeconds: 60)),
  ];

  static const _step = 15;
  static const _min = 15;
  static const _max = 30 * 60;

  int _runSeconds = 120;
  int _walkSeconds = 60;

  IntervalPlan get _plan => IntervalPlan(runSeconds: _runSeconds, walkSeconds: _walkSeconds);

  void _start() {
    // Replace the setup screen: finishing (or backing out of) the run
    // returns straight to Entrenar, not to this form.
    Navigator.of(context).pushReplacement(
      FadeSlideRoute(
        builder: (_) => LiveRunScreen(trainingType: TrainingType.intervals, intervalPlan: _plan),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const stagger = Duration(milliseconds: 70);

    return Scaffold(
      appBar: AppBar(title: const Text('Intervalos')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    child: Text(
                      'Alterná tramos de correr y caminar. Elegí cuánto dura cada uno: '
                      'se repiten hasta que finalices, y el celular vibra en cada cambio.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade800),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: stagger,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (label, plan) in _presets)
                          ChoiceChip(
                            label: Text(
                              '$label · ${RunFormatters.clock(plan.runSeconds)} / '
                              '${RunFormatters.clock(plan.walkSeconds)}',
                            ),
                            selected: plan.runSeconds == _runSeconds && plan.walkSeconds == _walkSeconds,
                            onSelected: (_) => setState(() {
                              _runSeconds = plan.runSeconds;
                              _walkSeconds = plan.walkSeconds;
                            }),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: stagger * 2,
                    child: _DurationPicker(
                      label: 'Correr',
                      icon: Icons.directions_run,
                      color: AppTheme.accent,
                      seconds: _runSeconds,
                      onChanged: (v) => setState(() => _runSeconds = v.clamp(_min, _max)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Reveal(
                    delay: stagger * 3,
                    child: _DurationPicker(
                      label: 'Caminar',
                      icon: Icons.directions_walk,
                      color: AppTheme.walk,
                      seconds: _walkSeconds,
                      onChanged: (v) => setState(() => _walkSeconds = v.clamp(_min, _max)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Reveal(delay: stagger * 4, child: _CyclePreview(plan: _plan)),
                  const SizedBox(height: 28),
                  Reveal(
                    delay: stagger * 5,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Empezar intervalos'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int seconds;
  final ValueChanged<int> onChanged;

  const _DurationPicker({
    required this.label,
    required this.icon,
    required this.color,
    required this.seconds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const step = _IntervalSetupScreenState._step;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
          IconButton.outlined(
            tooltip: '-15 s',
            onPressed: seconds > _IntervalSetupScreenState._min ? () => onChanged(seconds - step) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 72,
            child: Text(
              RunFormatters.clock(seconds),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: '+15 s',
            onPressed: seconds < _IntervalSetupScreenState._max ? () => onChanged(seconds + step) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// A bar showing three rounds to scale, so the run/walk ratio is visible
/// at a glance while adjusting the times.
class _CyclePreview extends StatelessWidget {
  final IntervalPlan plan;

  const _CyclePreview({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Así se ven 3 rondas (${RunFormatters.duration(plan.cycleSeconds * 3)})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  _segment(plan.runSeconds, AppTheme.accent),
                  _segment(plan.walkSeconds, AppTheme.walk),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _segment(int seconds, Color color) => Expanded(
        flex: seconds,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 2),
          color: color,
        ),
      );
}

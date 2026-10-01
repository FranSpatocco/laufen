import 'package:flutter/material.dart';
import '../models/training_type.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import '../widgets/reveal.dart';
import 'live_run_screen.dart';

/// "Entrenar" tab: pick a training variant before starting to track
/// (see CLAUDE.md > Funcionalidad core — same RunModel/live-tracking flow
/// for all three, only the label/icon differ).
class TrainScreen extends StatelessWidget {
  final bool isGuest;

  const TrainScreen({super.key, this.isGuest = false});

  @override
  Widget build(BuildContext context) {
    const stagger = Duration(milliseconds: 70);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: Text(
              '¿Qué querés entrenar hoy?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < TrainingType.values.length; i++) ...[
            Reveal(delay: stagger * (i + 1), child: _TrainingTypeCard(type: TrainingType.values[i])),
            const SizedBox(height: 14),
          ],
          if (isGuest)
            Reveal(
              delay: stagger * (TrainingType.values.length + 1),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No necesitás cuenta para probar: al terminar decidís si guardás la carrera.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrainingTypeCard extends StatelessWidget {
  final TrainingType type;

  const _TrainingTypeCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          FadeSlideRoute(builder: (_) => LiveRunScreen(trainingType: type)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
                child: Icon(type.icon, color: AppTheme.accentDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  type.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

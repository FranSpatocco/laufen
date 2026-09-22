import 'package:flutter/material.dart';
import '../models/training_type.dart';
import '../utils/page_transitions.dart';
import '../utils/theme.dart';
import 'live_run_screen.dart';

/// "Entrenar" tab: pick a training variant before starting to track
/// (see CLAUDE.md > Funcionalidad core — same RunModel/live-tracking flow
/// for all three, only the label/icon differ).
class TrainScreen extends StatelessWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Qué querés entrenar hoy?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          for (final type in TrainingType.values) ...[
            _TrainingTypeCard(type: type),
            const SizedBox(height: 14),
          ],
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

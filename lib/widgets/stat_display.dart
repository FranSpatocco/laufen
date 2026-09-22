import 'package:flutter/material.dart';

/// Big bold stat (distance, pace, time) reused across the live-run and
/// detail screens — these numbers are the protagonists of the UI
/// (see CLAUDE.md > Diseño). The dashboard uses AnimatedStatTile instead,
/// which adds the count-up animation and card styling.
class StatDisplay extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const StatDisplay({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

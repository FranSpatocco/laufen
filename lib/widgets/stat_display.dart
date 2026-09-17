import 'package:flutter/material.dart';

/// Big bold stat (distance, pace, time) reused across live-run, detail
/// and dashboard screens — these numbers are the protagonists of the UI
/// (see CLAUDE.md > Diseño).
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

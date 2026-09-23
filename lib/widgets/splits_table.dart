import 'package:flutter/material.dart';
import '../models/km_split.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

/// Per-km pace table for a finished run: one row per km, a bar showing
/// how fast each km was relative to the others (Strava-style), the fastest
/// km highlighted, and the whole-run average pace as the closing row.
class SplitsTable extends StatelessWidget {
  final List<KmSplit> splits;
  final double avgPaceMinPerKm;

  const SplitsTable({super.key, required this.splits, required this.avgPaceMinPerKm});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final paces = splits.map((s) => s.paceMinPerKm).where((p) => p > 0);
    final fastest = paces.isEmpty ? 0.0 : paces.reduce((a, b) => a < b ? a : b);
    final slowest = paces.isEmpty ? 0.0 : paces.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Parciales', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (var i = 0; i < splits.length; i++)
          _SplitRow(
            label: splits[i].isPartial ? RunFormatters.distanceKm(splits[i].distanceKm) : 'Km ${i + 1}',
            pace: splits[i].paceMinPerKm,
            // Bars are relative to the slowest km (not a fixed scale), so
            // even small pace differences are visible. Floor at 20% so the
            // slowest km still shows a bar.
            barFraction: slowest <= 0 ? 0 : (0.2 + 0.8 * (slowest - splits[i].paceMinPerKm) / (slowest - fastest + 1e-9)).clamp(0.2, 1.0),
            isFastest: splits.length > 1 && splits[i].paceMinPerKm == fastest,
          ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(child: Text('Ritmo total', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))),
            Text(RunFormatters.pace(avgPaceMinPerKm), style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  final String label;
  final double pace;
  final double barFraction;
  final bool isFastest;

  const _SplitRow({
    required this.label,
    required this.pace,
    required this.barFraction,
    required this.isFastest,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = isFastest ? AppTheme.accentDark : AppTheme.accent.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: textTheme.bodyMedium)),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: barFraction,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 84,
            child: Text(
              RunFormatters.pace(pace),
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isFastest ? FontWeight.bold : FontWeight.w500,
                color: isFastest ? AppTheme.accentDark : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Paleta "tierra / asfalto" como seed color de Material 3 (reemplaza al
/// verde esmeralda y, antes, al naranja estilo Strava — ver CLAUDE.md > Diseño).
/// Light theme only for now — dark mode is not part of the v1 scope.
class AppTheme {
  static const Color accent = Color(0xFF9C5A32);
  static const Color accentDark = Color(0xFF6B3D20);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF3EEE4),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: accent.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? accentDark : Colors.grey.shade600,
        ),
      ),
    ),
  );
}

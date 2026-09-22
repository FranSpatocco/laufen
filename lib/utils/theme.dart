import 'package:flutter/material.dart';

/// Emerald-green accent as the Material 3 seed color (moved away from the
/// original Strava-orange per product direction — see CLAUDE.md > Diseño).
/// Light theme only for now — dark mode is not part of the v1 scope.
class AppTheme {
  static const Color accent = Color(0xFF10B981);
  static const Color accentDark = Color(0xFF047857);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F9F8),
    navigationBarTheme: NavigationBarThemeData(
      // Fixed height with breathing room: the label switching weight
      // between states (below) changes its rendered metrics slightly,
      // which overflowed the default height on a real device.
      height: 72,
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

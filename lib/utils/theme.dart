import 'package:flutter/material.dart';

/// Strava-style orange accent as the Material 3 seed color.
/// Light theme only for now — dark mode is not part of the v1 scope (see CLAUDE.md).
class AppTheme {
  static const Color accentOrange = Color(0xFFFC4C02);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentOrange,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
}

import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() {
  runApp(const LaufenApp());
}

class LaufenApp extends StatelessWidget {
  const LaufenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LandingScreen(),
    );
  }
}

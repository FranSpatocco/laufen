import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laufen/screens/landing_screen.dart';
import 'package:laufen/utils/constants.dart';

void main() {
  testWidgets('Landing screen shows the app name', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}

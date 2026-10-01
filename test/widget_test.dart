import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laufen/models/content_model.dart';
import 'package:laufen/screens/landing_screen.dart';
import 'package:laufen/widgets/animated_route_card.dart';
import 'package:laufen/widgets/laufen_wordmark.dart';

void main() {
  Widget landing({required VoidCallback onStart}) => MaterialApp(
        home: LandingScreen(
          contentStream: Stream<LandingContent?>.value(null),
          onStart: onStart,
        ),
      );

  testWidgets('Landing screen shows the wordmark and the animated route', (tester) async {
    await tester.pumpWidget(landing(onStart: () {}));
    // The route card loops forever, so pumpAndSettle would never return —
    // advance past the intro timeline instead.
    await tester.pump(const Duration(seconds: 3));

    // The logo is drawn as a wordmark (not a plain Text), so look for the widget.
    expect(find.byType(LaufenWordmark), findsOneWidget);
    expect(find.byType(AnimatedRouteCard), findsOneWidget);
  });

  testWidgets('"Empezar" enters the app without asking to log in', (tester) async {
    var started = false;
    await tester.pumpWidget(landing(onStart: () => started = true));
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('Empezar'));
    expect(started, isTrue);
  });

  testWidgets('Landing fits a desktop-width window', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(landing(onStart: () {}));
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Empezar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Landing fits a small phone without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(landing(onStart: () {}));
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });
}

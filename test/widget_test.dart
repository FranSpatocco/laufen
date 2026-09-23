import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laufen/models/content_model.dart';
import 'package:laufen/screens/landing_screen.dart';
import 'package:laufen/widgets/laufen_wordmark.dart';

void main() {
  testWidgets('Landing screen shows the wordmark', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LandingScreen(contentStream: Stream<LandingContent?>.value(null)),
    ));

    // The logo is drawn as a wordmark (not a plain Text), so look for the widget.
    expect(find.byType(LaufenWordmark), findsOneWidget);
  });
}

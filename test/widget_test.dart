import 'package:flutter_test/flutter_test.dart';

import 'package:laufen/main.dart';
import 'package:laufen/utils/constants.dart';

void main() {
  testWidgets('Landing screen shows the app name', (WidgetTester tester) async {
    await tester.pumpWidget(const LaufenApp());

    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}

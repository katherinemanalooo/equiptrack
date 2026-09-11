import 'package:flutter_test/flutter_test.dart';

import 'package:equiptrack/main.dart';

void main() {
  testWidgets(
    'EquipTrack app starts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const EquipTrackApp(),
      );

      expect(
        find.text('EquipTrack'),
        findsOneWidget,
      );

      expect(
        find.text('Connect to Server'),
        findsOneWidget,
      );
    },
  );
}
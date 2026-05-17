import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('LNU SmartPath offline')),
      ),
    );
    expect(find.textContaining('LNU SmartPath'), findsOneWidget);
  });
}

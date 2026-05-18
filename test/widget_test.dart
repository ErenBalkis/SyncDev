import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onyxfi_frontend/main.dart';

void main() {
  testWidgets('OnyxFi app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const OnyxFiApp(),
    );
    // Verify the onboarding screen renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

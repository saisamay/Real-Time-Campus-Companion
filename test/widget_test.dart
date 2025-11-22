import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_time_campus_companion/main.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    // FIX: Changed 'MyApp' to 'RootApp' to match your main.dart
    await tester.pumpWidget(const RootApp());

    // Verify that the app finds one MaterialApp widget (proof it started)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
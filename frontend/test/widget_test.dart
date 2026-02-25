import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediremind/main.dart'; // ✅ Correct package name

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build the MediRemind app and trigger a frame
    await tester.pumpWidget(const MediRemindApp());

    // Verify that the home screen is displayed
    expect(find.text('MediRemind'), findsOneWidget);
  });
}

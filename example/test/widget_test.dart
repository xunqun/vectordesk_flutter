// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('VectorDesk SDK Example app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: Since Firebase is not mocked, real Firebase initialization might throw
    // a PlatformException in test environments, but we catch it or handle it in client.
    await tester.pumpWidget(const MyApp());

    // Verify that the AppBar title is correct.
    expect(find.text('VectorDesk SDK Example'), findsOneWidget);
  });
}

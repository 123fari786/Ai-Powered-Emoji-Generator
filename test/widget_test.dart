import 'package:ai_image_makerr/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const MyApp());

    // Let all frames render
    await tester.pumpAndSettle();

    // Just verify app built successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

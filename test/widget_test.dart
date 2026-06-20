import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catatin/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Just verify the app boots without crashing
    await tester.pumpWidget(const CatatinApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

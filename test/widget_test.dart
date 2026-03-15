import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/main.dart';

void main() {
  group('[Widget] MyApp', () {
    testWidgets('should render the app title text when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('Run Check'), findsOneWidget);
    });

    testWidgets('should configure a MaterialApp when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, 'Run Check');
    });

    testWidgets('should show a centered scaffold body when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });
  });
}

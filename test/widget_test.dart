import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_check/app.dart';
import 'package:run_check/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('[Widget] RunCastApp', () {
    testWidgets('should render the home route when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: RunCastApp()));
      await tester.pumpAndSettle();

      expect(find.text('RunCheck'), findsOneWidget);
    });

    testWidgets('should configure a MaterialApp when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: RunCastApp()));
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.title, 'Run Check');
    });

    testWidgets('should apply the shared app theme when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: RunCastApp()));
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.theme, same(appTheme));
    });

    testWidgets('should show a centered scaffold body when built', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: RunCastApp()));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Tap to set your location'), findsOneWidget);
    });
  });
}

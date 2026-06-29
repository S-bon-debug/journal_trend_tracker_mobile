import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_tracker_mobile/main.dart';

void main() {
  testWidgets('Navigation smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that bottom navigation bar is present (NavigationBar is the new widget)
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify that the trends tab is initially selected and displaying the title
    expect(find.text('Trends Dashboard'), findsOneWidget);

    // Tap the Profile tab
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    // Verify that it switched to Profile screen by finding the title
    expect(find.text('My Profile'), findsOneWidget);
  });
}


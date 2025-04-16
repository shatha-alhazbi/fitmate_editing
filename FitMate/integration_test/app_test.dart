// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmate/main.dart' as app;
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end app tests', () {
    tearDown(() async {
      await TestHelpers.cleanup();
    });

    testWidgets('App launches and login succeeds', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait for splash screen

      // Login with test credentials
      await TestHelpers.login(tester);
      
      // Verify we're on the home page
      expect(find.text('TODAY\'S FOOD'), findsOneWidget);
    });

    testWidgets('Can navigate to workout screen', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await TestHelpers.login(tester);
      
      // Navigate to workout screen
      await TestHelpers.navigateToWorkoutScreen(tester);
      
      // Verify workout screen content appears
      expect(find.text('Today\'s Workout'), findsOneWidget);
      expect(find.text('FitMate AI'), findsOneWidget);
    });

    testWidgets('Navigate to form check list screen', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await TestHelpers.login(tester);
      
      // Navigate to workout screen
      await TestHelpers.navigateToWorkoutScreen(tester);
      
      // Find and tap on the "FitMate AI" option
      final formCheckButton = find.text('FitMate AI');
      expect(formCheckButton, findsOneWidget);
      await tester.tap(formCheckButton);
      await tester.pumpAndSettle();
      
      // Verify we're on the form check screen
      expect(find.text('Form Check'), findsOneWidget);
      
      // Verify that there are exercise options listed
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Plank'), findsOneWidget);
      expect(find.text('Bicep Curl'), findsOneWidget);
    });

    testWidgets('Can navigate to nutrition screen', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await TestHelpers.login(tester);
      
      // Tap on the nutrition icon in nav bar (index 2)
      final bottomNavItems = find.byType(BottomNavigationBarItem);
      await tester.tap(bottomNavItems.at(2));
      await tester.pumpAndSettle();
      
      // Verify we're on nutrition screen
      expect(find.text('NUTRITION'), findsOneWidget);
    });

    testWidgets('Can view profile screen', (WidgetTester tester) async {
      // Start the app and login
      app.main();
      await tester.pumpAndSettle();
      await TestHelpers.login(tester);
      
      // Tap on the profile icon in nav bar (index 3)
      final bottomNavItems = find.byType(BottomNavigationBarItem);
      await tester.tap(bottomNavItems.at(3));
      await tester.pumpAndSettle();
      
      // Verify profile screen content
      expect(find.text('EDIT PROFILE'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Weight'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Height'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Age'), findsOneWidget);
    });
  });
}
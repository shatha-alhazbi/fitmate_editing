// integration_test/helpers/test_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to assist with common test operations
class TestHelpers {
  /// Login with test credentials
  static Future<void> login(WidgetTester tester, {
    String email = 'test@example.com',
    String password = 'password123',
  }) async {
    // Find and tap the login button on welcome screen
    await tester.pumpAndSettle();
    final loginButton = find.text('LOG IN');
    expect(loginButton, findsOneWidget);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    
    // Enter login credentials
    final emailField = find.widgetWithText(TextFormField, 'example@email.com');
    final passwordField = find.widgetWithText(TextFormField, 'Password');
    
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);
    
    // Submit login form
    final submitButton = find.widgetWithText(ElevatedButton, 'LOGIN');
    await tester.tap(submitButton);
    await tester.pumpAndSettle(const Duration(seconds: 3)); // Allow time for login
    
    // Verify we're on the homepage
    expect(find.text('WELCOME,'), findsOneWidget);
  }
  
  /// Navigate to the workout screen
  static Future<void> navigateToWorkoutScreen(WidgetTester tester) async {
    await tester.pumpAndSettle();
    
    // Find the workout icon in the bottom nav bar (index 1)
    final bottomNavItems = find.byType(BottomNavigationBarItem);
    await tester.tap(bottomNavItems.at(1));
    await tester.pumpAndSettle();
    
    // Verify we're on the workout screen
    expect(find.text('WORKOUT'), findsOneWidget);
  }
  
  /// Navigate to the form check screen
  static Future<void> navigateToFormCheckScreen(WidgetTester tester) async {
    // First navigate to workout screen
    await navigateToWorkoutScreen(tester);
    
    // Find and tap on the "FitMate AI" option
    final formCheckButton = find.text('FitMate AI');
    expect(formCheckButton, findsOneWidget);
    await tester.tap(formCheckButton);
    await tester.pumpAndSettle();
    
    // Verify we're on the form check screen
    expect(find.text('Form Check'), findsOneWidget);
  }
  
  /// Mocks dependencies for testing
  static void setupMocks() {
    // Here you would set up any mock services needed for testing
    // This would depend on your app's dependency injection setup
  }
  
  /// Clean up after tests
  static Future<void> cleanup() async {
    try {
      // Sign out if logged in
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Config
import 'package:fitmate/config/provider_setup.dart';

// Login and Register Screens
import 'package:fitmate/screens/login_screens/login_screen.dart';
import 'package:fitmate/screens/login_screens/forgot_password_screen.dart';
import 'package:fitmate/screens/login_screens/welcome_screen.dart';
import 'package:fitmate/screens/register_screens/age_question.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';

// Food Recognition and Nutrition Screens
import 'screens/food_recognition/food_recognition_screen.dart';
import 'screens/nutrition_screens/log_food_manually.dart';

// Services and Repositories
import 'services/workout_service.dart';
import 'repositories/food_repository.dart';
import 'services/food_recognition_services.dart';
import 'services/food_logging_service.dart';

void main() async {
  // Ensure widgets are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence
  enableOfflinePersistence();

  // Run the app with MultiProvider
  runApp(const MyApp());
}

void enableOfflinePersistence() {
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Include all providers from provider_setup.dart
        ...providers,
        
        // Additional providers from the second file
        Provider<FoodRepository>(
          create: (_) => FoodRepository(),
        ),
        ChangeNotifierProvider<Food_recognition_service>(
          create: (_) => Food_recognition_service(),
        ),
        ChangeNotifierProvider<FoodLoggingService>(
          create: (_) => FoodLoggingService(),
        ),
        Provider<WorkoutService>(
          create: (_) => WorkoutService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthCheck(), // Check if user is logged in
        routes: {
          '/login': (context) => const LoginPage(),
          '/forgot-password': (context) => ForgotPasswordPage(),
          '/register': (context) => AgeQuestionPage(age: 0),
          '/home': (context) => HomePage(),
          '/food_recognition': (context) => const FoodRecognitionScreen(),
          '/manual_food_log': (context) => const LogFoodManuallyScreen(),
        },
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Loading state
        }
        if (snapshot.hasData) {
          return HomePage(); // User is logged in
        } else {
          return const WelcomePage(); // User is not logged in
        }
      },
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/screens/login_screens/welcome_screen.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart'; // Added for ByteData loading

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // flags for animation and navigation
  bool _animationCompleted = false;
  User? _currentUser;
  
  // animation controller for transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // controller to track Lottie animation
  ValueNotifier<bool> _lottieLoaded = ValueNotifier<bool>(false);
  
  // Pre-loaded animation data
  ByteData? _preloadedAnimation;
  
  // animation duration - shortened for better UX
  final Duration _animationDuration = const Duration(milliseconds: 4500);

  @override
  void initState() {
    super.initState();
    
    // fade controller for exit transition
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)
    );
    
    // Preload animation and check auth in parallel
    _preloadAnimationData();
    _checkAuth();
  }

  // Preload animation data
  Future<void> _preloadAnimationData() async {
    try {
      // Load animation data from assets
      _preloadedAnimation = await rootBundle.load('assets/data/lottie/intro_mascot.json');
      if (mounted) {
        setState(() {});  // Trigger rebuild once data is loaded
      }
    } catch (e) {
      print('Animation preload error: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lottieLoaded.dispose();
    super.dispose();
  }

  // auth check
  Future<void> _checkAuth() async {
    try {
      // get user
      _currentUser = FirebaseAuth.instance.currentUser;
    } catch (e) {
      // handle errors
      print('Auth check error: $e');
    }
  }

  // triggered when Lottie animation completes
  void _onLottieAnimationComplete() {
    if (mounted) {
      setState(() {
        _animationCompleted = true;
      });
      _navigateToNextScreen();
    }
  }
  
  // triggered when animation has loaded
  void _onLottieLoaded() {
    _lottieLoaded.value = true;
  }

  // navigation after animation completes
  void _navigateToNextScreen() {
    // start fade-out
    _fadeController.forward();
    
    // navigate after fade
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (_currentUser != null) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 700),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const WelcomePage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 700),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie animation with optimized loading
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: 1.3,
                        child: _preloadedAnimation != null
                            ? Lottie.asset(
                                'assets/data/lottie/intro_mascot.json',
                                repeat: false,
                                fit: BoxFit.contain,
                                frameRate: FrameRate(60), // Optimize frame rate
                                delegates: LottieDelegates(
                                  values: [
                                    // Optionally optimize specific animations
                                    ValueDelegate.color(
                                      const ['**'], // Target all color properties
                                      value: Colors.green, // Optional color override for performance
                                    ),
                                  ],
                                ),
                                onLoaded: (composition) {
                                  _onLottieLoaded();
                                  // Only start the timer once the animation is actually loaded
                                  Future.delayed(Duration(milliseconds: 100), () {
                                    // Use a slightly shorter duration than the actual animation
                                    // to ensure navigation happens even if animation stalls
                                    Timer(
                                      (composition.duration ?? _animationDuration),
                                      _onLottieAnimationComplete
                                    );
                                  });
                                },
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD2EB50),
                                ),
                              ),
                      ),
                    ),
                  ),
                  
                  // loading indicator
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      children: [
                        Text(
                          "Loading your fitness journey...",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<bool>(
                          valueListenable: _lottieLoaded,
                          builder: (context, loaded, child) {
                            return loaded && !_animationCompleted 
                              ? Text(
                                  "Animation playing...",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                )
                              : const CircularProgressIndicator(
                                  color: Color(0xFFD2EB50),
                                  strokeWidth: 3.0,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
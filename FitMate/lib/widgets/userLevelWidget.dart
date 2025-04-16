import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLevelWidget extends StatefulWidget {
  const UserLevelWidget({Key? key}) : super(key: key);

  @override
  State<UserLevelWidget> createState() => _UserLevelWidgetState();
}

class _UserLevelWidgetState extends State<UserLevelWidget> with SingleTickerProviderStateMixin {
  // User fitness data
  String _fitnessLevel = 'Beginner';
  int _fitnessSubLevel = 1;
  int _workoutsCompleted = 0;
  int _workoutsUntilNextLevel = 20;
  DateTime? _lastUpdated;
  bool _isLoading = true;
  bool _showAnimation = false;
  bool _isMaxLevel = false;
  String _lastAnimatedLevel = '';

  // Animation controller
  late AnimationController _levelAnimationController;

  @override
  void initState() {
    super.initState();
    _levelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user progress document
        DocumentSnapshot userProgress = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userProgress')
            .doc('progress')
            .get();

        if (!userProgress.exists) {
          // Create progress document if it doesn't exist
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .set({
            'fitnessLevel': 'Beginner',
            'fitnessSubLevel': 1,
            'workoutsCompleted': 0,
            'workoutsUntilNextLevel': 20,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Reload after creating
          userProgress = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .get();
        }

        if (mounted) {
          final progressData = userProgress.data() as Map<String, dynamic>;
          final newFitnessLevel = progressData['fitnessLevel'] ?? 'Beginner';
          final newFitnessSubLevel = progressData['fitnessSubLevel'] ?? 1;

          // Check if user is at max level (Advanced Level 3)
          final newIsMaxLevel = newFitnessLevel == 'Advanced' && newFitnessSubLevel == 3;

          // Check if we should show the animation (new level achieved)
          await _checkAndShowLevelAnimation(newFitnessLevel, newFitnessSubLevel);

          setState(() {
            _fitnessLevel = newFitnessLevel;
            _fitnessSubLevel = newFitnessSubLevel;
            _workoutsCompleted = progressData['workoutsCompleted'] ?? 0;
            _workoutsUntilNextLevel = progressData['workoutsUntilNextLevel'] ?? 20;
            _lastUpdated = progressData['lastUpdated']?.toDate();
            _isMaxLevel = newIsMaxLevel;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  Future<void> _checkAndShowLevelAnimation(String newLevel, int newSubLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final lastAnimatedLevel = prefs.getString('lastAnimatedLevel') ?? '';
    final currentLevelKey = '$newLevel-$newSubLevel';

    if (lastAnimatedLevel != currentLevelKey && !(newLevel == 'Beginner' && newSubLevel == 1)) {
      // Store that we've shown this animation
      await prefs.setString('lastAnimatedLevel', currentLevelKey);

      // Show animation (slight delay to allow the widget to build)
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showAnimation = true;
          });
          _levelAnimationController.forward().then((_) {
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _showAnimation = false;
                });
                _levelAnimationController.reset();
              }
            });
          });
        }
      });
    }
  }

  String _getMotivationalMessage() {
    if (_isMaxLevel) {
      return "Master level achieved! Keep crushing your goals!";
    }

    double progress = _workoutsCompleted / _workoutsUntilNextLevel;

    if (progress < 0.25) {
      return "Keep pushing! You've got this.";
    } else if (progress < 0.5) {
      return "Halfway there! Stay strong.";
    } else if (progress < 0.75) {
      return "The finish line is in sight!";
    } else {
      return "So close to leveling up! Push harder!";
    }
  }

  Widget _buildCelebrationAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated circle
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 1 + (value * 0.5),
              child: Opacity(
                opacity: 1 - (value * 0.7),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getLevelPrimaryColor().withOpacity(0.6),
                  ),
                ),
              ),
            );
          },
        ),
        // Sparkle animation
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 1000),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(
                Icons.emoji_events,
                size: 26,
                color: Colors.amber,
              ),
            );
          },
        ),
      ],
    );
  }

  // Get primary color based on fitness level
  Color _getLevelPrimaryColor() {
    switch (_fitnessLevel.toLowerCase()) {
      case 'beginner':
        return Color(0xFFD2EB50); // Vibrant Lime Green
      case 'intermediate':
        return Color(0xFF83CFDF); // Bright Teal
      case 'advanced':
        return Color(0xFFFFBE3D); // Golden Yellow
      default:
        return Color(0xFFD2EB50); // Default Lime Green
    }
  }

  // Get secondary color based on fitness level
  Color _getLevelSecondaryColor() {
    switch (_fitnessLevel.toLowerCase()) {
      case 'beginner':
        return Color(0xFFB8D143); // Deeper Lime Green
      case 'intermediate':
        return Color(0xFF69B5C3); // Deeper Teal
      case 'advanced':
        return Color(0xFFD87974); // Deeper Gold
      default:
        return Color(0xFFB8D143); // Default Deeper Lime
    }
  }

  // Get icon based on fitness level
  IconData _getLevelIcon() {
    switch (_fitnessLevel.toLowerCase()) {
      case 'beginner':
        return Icons.self_improvement;
      case 'intermediate':
        return Icons.whatshot;
      case 'advanced':
        return Icons.emoji_events;
      default:
        return Icons.self_improvement;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate level progress for progress bar
    double levelProgress = _workoutsCompleted / _workoutsUntilNextLevel;
    levelProgress = levelProgress.clamp(0.0, 1.0);

    // Get level colors
    final Color primaryColor = _getLevelPrimaryColor();
    final Color secondaryColor = _getLevelSecondaryColor();

    if (_isLoading) {
      return Container(
        height: 120, // Even smaller height
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 42, // Smaller size
                width: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.8),
                      primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _showAnimation
                      ? _buildCelebrationAnimation()
                      : Icon(
                    _getLevelIcon(),
                    size: 24, // Smaller icon
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fitnessLevel,
                    style: GoogleFonts.bebasNeue(
                      color: Color(0xFF2D3748),
                      fontSize: 20, // Smaller text
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.9),
                          primaryColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.15),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      "Level $_fitnessSubLevel",
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$_workoutsCompleted/$_workoutsUntilNextLevel",
                  style: GoogleFonts.bebasNeue(
                    color: secondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isMaxLevel ? "Master Level" : "Next Level",
                      style: GoogleFonts.bebasNeue(
                        color: Color(0xFF4A5568),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Stack(
                      children: [
                        // Background bar
                        Container(
                          height: 8, // Extra slim progress bar
                          decoration: BoxDecoration(
                            color: Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Progress bar
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 800),
                              height: 8,
                              width: constraints.maxWidth * levelProgress,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    secondaryColor.withOpacity(0.8),
                                    primaryColor,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${(levelProgress * 100).toInt()}%",
                  style: GoogleFonts.bebasNeue(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Color(0xFFE2E8F0),
                width: 0.5, // Thinner border
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: secondaryColor,
                  size: 14,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getMotivationalMessage(),
                    style: GoogleFonts.bebasNeue(
                      color: Color(0xFF4A5568),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.1, // Tighter line height
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
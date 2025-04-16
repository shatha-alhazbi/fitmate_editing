import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart' hide LottieCache;
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/workout_completion_viewmodel.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';
import 'package:fitmate/utils/lottie_cache.dart';

class WorkoutCompletionScreen extends StatelessWidget {
  final int completedExercises;
  final int totalExercises;
  final String duration;
  final String category;

  const WorkoutCompletionScreen({
    Key? key,
    required this.completedExercises,
    required this.totalExercises,
    required this.duration,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WorkoutCompletionViewModel(
        repository: context.read<WorkoutRepository>(),
        workoutService: context.read<WorkoutService>(),
        completedExercises: completedExercises,
        totalExercises: totalExercises,
        duration: duration,
        category: category,
      )..init(),
      child: const _WorkoutCompletionScreenContent(),
    );
  }
}

class _WorkoutCompletionScreenContent extends StatefulWidget {
  const _WorkoutCompletionScreenContent();

  @override
  _WorkoutCompletionScreenContentState createState() => _WorkoutCompletionScreenContentState();
}

class _WorkoutCompletionScreenContentState extends State<_WorkoutCompletionScreenContent> 
    with TickerProviderStateMixin {
  // Multiple animation controllers for staged reveal
  late AnimationController _masterController;
  late AnimationController _titleController;
  late AnimationController _statsController;
  late AnimationController _categoryController;
  late AnimationController _celebrationController;
  late AnimationController _transitionController;
  
  // Animations
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _titleAnimation;
  late Animation<int> _counterAnimation;
  late Animation<double> _statsSlideAnimation;
  late Animation<double> _categorySlideAnimation;
  late Animation<double> _celebrationScaleAnimation;
  late Animation<double> _pageTransitionAnimation;
  
  // Stage tracking
  int _currentStage = 0;
  final int _totalStages = 4;
  
  // Animation path
  final String _animationPath = 'assets/data/lottie/celebration_mascot.json';
  // Placeholder path
  final String _placeholderPath = 'assets/data/images/mascot/celebration_mascot.png';
  
  // State to keep track of animation status
  bool _animationLoaded = false;
  bool _showFullScreenCelebration = false;
  bool _isTransitioning = false;
  
  final TextStyle _whiteText = GoogleFonts.dmSans(
    color: Colors.white,
    fontSize: 16,
  );
  
  final TextStyle _accentText = GoogleFonts.dmSans(
    color: const Color(0xFFD2EB50),
    fontSize: 16,
  );
  
  @override
  void initState() {
    super.initState();
    
    // Initialize all animation controllers
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Increased stats animation duration from 800ms to 1600ms
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    
    // Increased category animation duration from 600ms to 1000ms
    _categoryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    
    // Set up animations
    _fadeInAnimation = CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    
    _titleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.1).chain(
          CurveTween(curve: Curves.easeInOut)
        ),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut)
        ),
        weight: 60,
      ),
    ]).animate(_titleController);
    
    _statsSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      // Modified the curve to be a bit slower at the beginning
      curve: Curves.easeOutQuad,
    ));
    
    _categorySlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _categoryController,
      curve: Curves.easeOutCubic,
    ));
    
    _celebrationScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.2).chain(
          CurveTween(curve: Curves.easeOut)
        ),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut)
        ),
        weight: 40,
      ),
    ]).animate(_celebrationController);
    
    _pageTransitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    );
    
    // Start preloading animation immediately
    _preloadLottieAnimation();
    
    // Start the staged reveal
    _startStagedReveal();
  }
  
  // Preload Lottie animation
  Future<void> _preloadLottieAnimation() async {
    // Check if already loaded
    if (LottieCache().isLottieLoaded(_animationPath)) {
      setState(() {
        _animationLoaded = true;
      });
      return;
    }
    
    // Start loading if not already loading
    if (!LottieCache().isLottieLoading(_animationPath)) {
      LottieCache().preloadAnimation(_animationPath);
    }
    
    // Check periodically until loaded
    _checkAnimationStatus();
  }
  
  // Check if animation is loaded
  void _checkAnimationStatus() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      if (LottieCache().isLottieLoaded(_animationPath)) {
        setState(() {
          _animationLoaded = true;
        });
      } else {
        _checkAnimationStatus();
      }
    });
  }
  
  // Start the staged reveal sequence
  void _startStagedReveal() {
    // Stage 1: Title animation
    _titleController.forward().then((_) {
      setState(() {
        _currentStage = 1;
      });
      
      // Stage 2: Stats animation
      _statsController.forward().then((_) {
        setState(() {
          _currentStage = 2;
        });
        
        // Stage 3: Category animation
        _categoryController.forward().then((_) {
          setState(() {
            _currentStage = 3;
          });
          
          // Increased delay from 1200ms to 2000ms before transitioning
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (!mounted) return;
            
            // Start transition to celebration screen
            _prepareForTransition();
          });
        });
      });
    });
    
    // Start the master controller that will animate progress bars, counters, etc.
    _masterController.forward();
  }
  
  // Prepare for transition to celebration
  void _prepareForTransition() {
    if (_animationLoaded) {
      // If animation is already loaded, begin transition
      _beginTransition();
    } else {
      // If not loaded yet, show loading indicator for a moment
      setState(() {
        _isTransitioning = true;
      });
      
      // Increased delay from 800ms to 1500ms to allow for loading
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _beginTransition();
        }
      });
    }
  }
  
  // Begin the transition to celebration screen
  void _beginTransition() {
    _transitionController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showFullScreenCelebration = true;
          _isTransitioning = false;
          _currentStage = 4;
        });
        
        _celebrationController.forward();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<WorkoutCompletionViewModel>(context);
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: viewModel.completionRatio,
    ).animate(CurvedAnimation(
      parent: _masterController,
      // Slowed down the progress animation
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _counterAnimation = IntTween(
      begin: 0,
      end: viewModel.completedExercises,
    ).animate(CurvedAnimation(
      parent: _masterController,
      // Slowed down the counter animation
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));
  }
  
  @override
  void dispose() {
    _masterController.dispose();
    _titleController.dispose();
    _statsController.dispose();
    _categoryController.dispose();
    _celebrationController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutCompletionViewModel>(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Full-screen celebration view
    if (_showFullScreenCelebration) {
      return _buildFullScreenCelebration(viewModel, screenSize);
    }
    
    // Staged reveal view
    return AnimatedBuilder(
      animation: _pageTransitionAnimation,
      builder: (context, child) {
        // Apply transition effect - fade out and scale up
        return Opacity(
          opacity: 1.0 - _pageTransitionAnimation.value,
          child: Transform.scale(
            scale: 1.0 + (_pageTransitionAnimation.value * 0.1),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated title
                      RepaintBoundary(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _titleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _titleAnimation.value,
                                child: FadeTransition(
                                  opacity: _fadeInAnimation,
                                  child: Text(
                                    'WORKOUT COMPLETE',
                                    style: GoogleFonts.dmSans(
                                      color: const Color(0xFFD2EB50),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Stats - animated in when ready
                      if (_currentStage >= 1)
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _statsSlideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _statsSlideAnimation.value),
                                child: FadeTransition(
                                  opacity: _statsController,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Section title with animated line
                                        Row(
                                          children: [
                                            Text(
                                              'Workout Stats',
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: AnimatedBuilder(
                                                animation: _statsController,
                                                builder: (context, child) {
                                                  return Container(
                                                    height: 1,
                                                    width: double.infinity,
                                                    color: Colors.grey[700],
                                                    child: FractionallySizedBox(
                                                      alignment: Alignment.centerLeft,
                                                      widthFactor: _statsController.value,
                                                      child: Container(
                                                        height: 1,
                                                        color: const Color(0xFFD2EB50),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        // Completion stats
                                        _buildStatsCard(viewModel),
                                        
                                        const SizedBox(height: 25),
                                        
                                        // Category info (animated in when ready)
                                        if (_currentStage >= 2)
                                          AnimatedBuilder(
                                            animation: _categorySlideAnimation,
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(0, _categorySlideAnimation.value),
                                                child: FadeTransition(
                                                  opacity: _categoryController,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Section title with animated line
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Workout Type',
                                                            style: GoogleFonts.dmSans(
                                                              color: Colors.white,
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Expanded(
                                                            child: AnimatedBuilder(
                                                              animation: _categoryController,
                                                              builder: (context, child) {
                                                                return Container(
                                                                  height: 1,
                                                                  width: double.infinity,
                                                                  color: Colors.grey[700],
                                                                  child: FractionallySizedBox(
                                                                    alignment: Alignment.centerLeft,
                                                                    widthFactor: _categoryController.value,
                                                                    child: Container(
                                                                      height: 1,
                                                                      color: const Color(0xFFD2EB50),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      
                                                      const SizedBox(height: 15),
                                                      
                                                      _buildCategoryCard(viewModel),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      
                      // Loading indicator during transition
                      if (_isTransitioning)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Text(
                                  "Preparing celebration...",
                                  style: _whiteText.copyWith(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Progress indicator (only shown during early stages)
                      if (_currentStage < 3 && !_isTransitioning)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFD2EB50),
                                ),
                                value: _currentStage / _totalStages,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Full screen celebration view shown after all stats are revealed
  Widget _buildFullScreenCelebration(WorkoutCompletionViewModel viewModel, Size screenSize) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main celebration content
          Center(
            child: AnimatedBuilder(
              animation: _celebrationScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _celebrationScaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie animation
                      SizedBox(
                        height: screenSize.height * 0.4,
                        child: LottieAnimationWidget(
                          animationPath: _animationPath,
                          height: screenSize.height * 0.4,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Congratulatory text
                      Text(
                        'Great Job!',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Text(
                        'You completed ${viewModel.completedExercises} exercises',
                        style: GoogleFonts.dmSans(
                          color: Colors.grey[300],
                          fontSize: 18,
                        ),
                      ),
                      
                      const SizedBox(height: 5),
                      
                      Text(
                        'in ${viewModel.duration}',
                        style: GoogleFonts.dmSans(
                          color: Colors.grey[300],
                          fontSize: 18,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Continue button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => HomePage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2EB50),
                          minimumSize: const Size(220, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'CONTINUE',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Back button at top left
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showFullScreenCelebration = false;
                  _celebrationController.reset();
                  _transitionController.reset();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Stats card with animated progress
  Widget _buildStatsCard(WorkoutCompletionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercises completed counter animation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercises Completed',
                    style: _whiteText.copyWith(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _counterAnimation,
                    builder: (context, child) {
                      return Row(
                        children: [
                          Text(
                            '${_counterAnimation.value}',
                            style: _accentText.copyWith(
                              color: const Color(0xFFD2EB50),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/${viewModel.totalExercises}',
                            style: _whiteText.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              
              // Duration - animated typing effect
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration',
                    style: _whiteText.copyWith(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFD2EB50),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      AnimatedBuilder(
                        animation: _masterController,
                        builder: (context, child) {
                          final durationText = viewModel.duration;
                          // Slowed down the typing effect by changing interval range
                          final visibleLength = (durationText.length * 
                              Interval(0.1, 0.6, curve: Curves.easeOut)
                                .transform(_masterController.value))
                              .floor();
                          
                          return Text(
                            durationText.substring(0, 
                                visibleLength.clamp(0, durationText.length)),
                            style: _whiteText.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Animated progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion',
                    style: _whiteText.copyWith(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                        style: _accentText.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // Background
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[800],
                    ),
                  ),
                  // Animated progress
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFD2EB50),
                                Color(0xFFA4B838),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Category card with icon
  Widget _buildCategoryCard(WorkoutCompletionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with animated background
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Colors.transparent, 
                    const Color(0xFFD2EB50).withOpacity(0.2),
                    value,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(viewModel.category),
                  color: const Color(0xFFD2EB50),
                  size: 28,
                ),
              );
            },
          ),
          
          const SizedBox(width: 20),
          
          // Category text with animated reveal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.category,
                  style: _whiteText.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Workout type description - dynamically generated based on category
                AnimatedBuilder(
                  animation: _categoryController,
                  builder: (context, child) {
                    final description = _getCategoryDescription(viewModel.category);
                    final visibleLength = (description.length * 
                        Interval(0.2, 1.0, curve: Curves.easeOut)
                          .transform(_categoryController.value))
                          .floor();
                          
                    return Text(
                      description.substring(0, 
                          visibleLength.clamp(0, description.length)),
                      style: _whiteText.copyWith(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.timer;
      case 'yoga':
        return Icons.spa;
      default:
        return Icons.sports_gymnastics;
    }
  }
  
  String _getCategoryDescription(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return 'Improved cardiovascular health and endurance';
      case 'strength':
        return 'Built muscle strength and increased power';
      case 'flexibility':
        return 'Enhanced range of motion and reduced injury risk';
      case 'hiit':
        return 'Maximized calorie burn and boosted metabolism';
      case 'yoga':
        return 'Improved balance, flexibility and mindfulness';
      default:
        return 'Comprehensive fitness training for overall health';
    }
  }
}

// Helper widget to render Lottie animation from the cache
class LottieAnimationWidget extends StatelessWidget {
  final String animationPath;
  final double height;
  
  const LottieAnimationWidget({
    Key? key,
    required this.animationPath,
    required this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Try to get the cached composition
    final cachedComposition = LottieCache().getComposition(animationPath);
    
    // Fixed null safety issue - properly check if composition is not null
    if (cachedComposition != null) {
      // Use the cached composition
      return Lottie(
        composition: cachedComposition,
        height: height,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        frameRate: FrameRate.max,
      );
    } else {
      // Fall back to loading from asset (should rarely happen as we preload)
      return Lottie.asset(
        animationPath,
        height: height,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        frameRate: FrameRate.max,
      );
    }
  }
}
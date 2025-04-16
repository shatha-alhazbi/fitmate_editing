import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:fitmate/services/voice_feedback_service.dart';
import 'analyzers/squat_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'base_exercise_detection_screen.dart';
import 'package:fitmate/widgets/pose_painter.dart';
import 'dart:math' as math;

class SquatDetectionScreen extends BaseExerciseDetectionScreen {
  const SquatDetectionScreen({Key? key}) 
      : super(key: key, exerciseType: 'Squat');
  
  @override
  _SquatDetectionScreenState createState() => _SquatDetectionScreenState();
}

class _SquatDetectionScreenState extends BaseExerciseDetectionState<SquatDetectionScreen> {
  late SquatAnalyzer analyzer;
  late VoiceFeedbackService voiceFeedback;
  String lastFormFeedback = '';
  String lastPositionFeedback = '';
  bool hasSpokenPositionFeedback = false;

  // UI enhancement vars
  bool showCountdown = true;
  int countdownValue = 3;
  bool showPoseGuide = true;
  bool showDebugInfo = false;
  
  @override
  void initState() {
    // Set preferred camera to front for squat detection
    preferredCameraLensDirection = CameraLensDirection.front;
    
    // Create analyzer before calling super.initState() which starts camera
    analyzer = SquatAnalyzer();
    voiceFeedback = VoiceFeedbackService();
    _initializeServices();
    
    super.initState();
    
    // Start countdown
    _startCountdown();
    
    // Delay the start of voice feedback
    Future.delayed(Duration(seconds: 8), () {
      if (mounted) {
        print("Voice feedback system activated");
        // This marks when we start allowing voice feedback
        lastFormFeedbackTime = DateTime.now().millisecondsSinceEpoch;
        lastPositiveFeedbackTime = DateTime.now().millisecondsSinceEpoch;
      }
    });
  }

  Future<void> _initializeServices() async {
    try {
      await voiceFeedback.initialize();
      print("Voice feedback service initialized");
    } catch (e) {
      print("Error initializing voice feedback: $e");
    }
  }
  
  void _startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (countdownValue > 1) {
            countdownValue--;
            _startCountdown(); // Continue countdown recursively
          } else {
            // When we reach 1, set showCountdown to false
            showCountdown = false;
          }
        });
      }
    });
  }
  
  void _toggleDebugInfo() {
    setState(() {
      showDebugInfo = !showDebugInfo;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }
  
  @override
  Future<void> processPose(Pose pose) async {
    // Process pose using the squat analyzer
    analyzer.analyzePose(pose);
    
    // Check position feedback first
    String currentPositionFeedback = '';
    if (analyzer.facingDirection == "Sideways") {
      currentPositionFeedback = "Please face the camera directly for proper squat analysis";
    }
    
    // Handle position feedback with voice
    if (currentPositionFeedback.isNotEmpty && 
        (currentPositionFeedback != lastPositionFeedback || !hasSpokenPositionFeedback)) {
      print("Speaking position feedback: $currentPositionFeedback");
      voiceFeedback.speak(currentPositionFeedback);
      lastPositionFeedback = currentPositionFeedback;
      hasSpokenPositionFeedback = true;
      
      // Reset the flag after 10 seconds to allow reminding again if needed
      Future.delayed(Duration(seconds: 10), () {
        if (mounted) {
          hasSpokenPositionFeedback = false;
        }
      });
    } else if (currentPositionFeedback.isEmpty) {
      // Reset when position is correct
      lastPositionFeedback = '';
      hasSpokenPositionFeedback = false;
    }
    
    // Only process form feedback if position is correct
    if (analyzer.facingDirection != "Sideways") {
      // Get current form feedback text
      String currentFormFeedback = analyzer.getFormFeedback();
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Check if feedback has changed
      if (currentFormFeedback != lastFormFeedback) {
        print("Feedback changed to: $currentFormFeedback");
        lastFormFeedback = currentFormFeedback;
        
        // Determine if this feedback should be spoken
        bool shouldSpeak = shouldSpeakFeedback(currentFormFeedback);
        
        // Check if enough time has passed since last feedback
        bool timeCheckPassed = (currentTime - lastFormFeedbackTime) > minMsBetweenFormFeedback;
        
        if (shouldSpeak && timeCheckPassed) {
          print("Speaking feedback: $currentFormFeedback");
          voiceFeedback.speak(currentFormFeedback);
          lastFormFeedbackTime = currentTime;
        }
      }
      
      // Provide occasional positive feedback when form is good
      // Check if form indicators suggest good form
      bool goodForm = analyzer.footPlacement == "Good" && 
                     analyzer.kneePlacement == "Good" &&
                     currentFormFeedback.contains("Good");
                     
      if (goodForm) {
        // Check if enough time has passed since last positive feedback
        bool positiveTimeCheckPassed = (currentTime - lastPositiveFeedbackTime) > minMsBetweenPositiveFeedback;
        
        if (positiveTimeCheckPassed) {
          // Select a random positive feedback message
          final random = math.Random();
          final message = positiveFeedbackMessages[random.nextInt(positiveFeedbackMessages.length)];
          
          print("Speaking positive feedback: $message");
          voiceFeedback.speak(message);
          lastPositiveFeedbackTime = currentTime;
        }
      }
    }
    
    // Update UI after processing
    if (mounted) setState(() {});
  }
  
  // Determine which feedback messages should be spoken
  bool shouldSpeakFeedback(String feedback) {
    // List of important feedback phrases to speak out loud
    List<String> importantPhrases = [ 
      "Stand with feet wider apart", "Bring your feet closer together",
      "Push your knees outward as you squat"
    ];
    
    // Check if the feedback contains any of the important phrases
    for (String phrase in importantPhrases) {
      if (feedback.toLowerCase().contains(phrase.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  // Delay between form feedback voice messages
  int lastFormFeedbackTime = 0;
  final int minMsBetweenFormFeedback = 4000; // 4 seconds between feedback
  
  // For positive feedback when form is good
  int lastPositiveFeedbackTime = 0;
  final int minMsBetweenPositiveFeedback = 15000; // 15 seconds between positive feedback
  final List<String> positiveFeedbackMessages = [
    "Excellent form",
    "Great job, keep it up",
    "Perfect form, you're doing great",
    "You've got it, excellent technique"
  ];
  
  @override
  void dispose() {
    // Clean up voice feedback
    voiceFeedback.stop();
    print("Voice feedback stopped");
    super.dispose();
  }
  
  @override
  Widget buildExerciseUI() {
    return Stack(
      children: [
        // Camera Preview with proper aspect ratio
        Container(
          width: double.infinity,
          height: double.infinity,
          child: AspectRatio(
            aspectRatio: cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
          ),
        ),
        
        // Pose guide removed
        
        // Pose overlay when pose is detected
        if (currentPose != null && !showCountdown)
          CustomPaint(
            painter: PosePainter(
              pose: currentPose!,
              imageSize: Size(
                cameraController!.value.previewSize!.height,
                cameraController!.value.previewSize!.width,
              ),
              isFrontCamera: true,
            ),
            size: Size.infinite,
          ),
        
        // Countdown overlay
        if (showCountdown)
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Ready!',
                    style: GoogleFonts.bebasNeue(
                      color: ExerciseUIComponents.primaryColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: ExerciseUIComponents.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        countdownValue.toString(),
                        style: GoogleFonts.bebasNeue(
                          color: Colors.black,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Face the camera with feet shoulder-width apart',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        
        if (!showCountdown) ...[
          // Position warning if user is not facing the camera
          if (analyzer.facingDirection == "Sideways")
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please face the camera directly for proper squat analysis",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // No longer needed since status row is at the top
          
          // Status row - moved back to the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ExerciseUIComponents.buildStatusRow(
              statusBoxes: [
                // Knee placement
                ExerciseUIComponents.buildStatusBox(
                  label: 'KNEES',
                  value: analyzer.kneePlacement == "UNK" ? '—' : analyzer.kneePlacement,
                  color: ExerciseUIComponents.getStatusColor(analyzer.kneePlacement),
                ),
                
                // Foot placement
                ExerciseUIComponents.buildStatusBox(
                  label: 'FEET',
                  value: analyzer.footPlacement == "UNK" ? '—' : analyzer.footPlacement,
                  color: ExerciseUIComponents.getStatusColor(analyzer.footPlacement),
                ),
              ],
            ),
          ),
          
          // Bottom feedback and instructions
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Form feedback with enhanced styling
                ExerciseUIComponents.buildFeedbackBox(
                  feedbackText: analyzer.getFormFeedback(),
                ),
              ],
            ),
          ),
          
          // Help button removed
        ],
      ],
    );
  }
}
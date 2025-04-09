import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import  'package:fitmate/services/voice_feedback_service.dart';
import 'analyzers/squat_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'base_exercise_detection_screen.dart';
import 'package:fitmate/widgets/pose_painter.dart';

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
            // Show pose guide briefly
            Future.delayed(Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  showPoseGuide = false;
                });
              }
            });
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
     // Get current feedback text
    String currentFeedback = analyzer.getFormFeedback();
    
    // Check if feedback has changed
    if (currentFeedback != lastFormFeedback) {
      print("Feedback changed to: $currentFeedback");
      lastFormFeedback = currentFeedback;
      
      // Determine if this feedback should be spoken
      bool shouldSpeak = shouldSpeakFeedback(currentFeedback);
      
      if (shouldSpeak) {
        print("Speaking feedback: $currentFeedback");
        voiceFeedback.speak(currentFeedback);
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
        
        // Pose guide overlay (transparent outline of correct form)
        if (showPoseGuide && !showCountdown)
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Container(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/data/images/workouts/image 2.png',
                  height: MediaQuery.of(context).size.height * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        
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
          // Top status row - Counter and Foot placement with enhanced design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ExerciseUIComponents.buildStatusRow(
              statusBoxes: [
                // Reps counter with animation
                ExerciseUIComponents.buildRepCounter(
                  count: analyzer.counter,
                ),
                
                // Foot placement status
                ExerciseUIComponents.buildStatusBox(
                  label: 'FEET',
                  value: analyzer.footPlacement,
                  color: ExerciseUIComponents.getStatusColor(analyzer.footPlacement),
                ),
              ],
            ),
          ),
          
          // Second status row - Knee placement and Current stage
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: ExerciseUIComponents.buildStatusRow(
              statusBoxes: [
                // Knee placement
                ExerciseUIComponents.buildStatusBox(
                  label: 'KNEES',
                  value: analyzer.kneePlacement,
                  color: ExerciseUIComponents.getStatusColor(analyzer.kneePlacement),
                ),
                
                // Current stage with icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: analyzer.currentStage == "down" 
                        ? Colors.orange 
                        : ExerciseUIComponents.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'STAGE',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            analyzer.currentStage == "down" 
                                ? Icons.arrow_downward 
                                : Icons.arrow_upward,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            analyzer.currentStage.toUpperCase(),
                            style: GoogleFonts.bebasNeue(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
          
          // Help button
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black54,
              child: Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {
                setState(() {
                  showPoseGuide = !showPoseGuide;
                });
              },
            ),
          ),
          
      
        ],
      ],
    );
  }
}
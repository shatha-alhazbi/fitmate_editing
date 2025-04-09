import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/services/voice_feedback_service.dart';
import 'analyzers/bicep_curl_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'base_exercise_detection_screen.dart';
import 'package:fitmate/widgets/pose_painter.dart';

class BicepCurlDetectionScreen extends BaseExerciseDetectionScreen {
  const BicepCurlDetectionScreen({Key? key}) 
      : super(key: key, exerciseType: 'Bicep Curl');
  
  @override
  _BicepCurlDetectionScreenState createState() => _BicepCurlDetectionScreenState();
}

class _BicepCurlDetectionScreenState extends BaseExerciseDetectionState<BicepCurlDetectionScreen> {
  late BicepCurlAnalyzer analyzer;
  late VoiceFeedbackService voiceFeedback;
  bool showCountdown = true;
  int countdownValue = 3;
  bool showPoseGuide = true;
  String lastFormFeedback = '';
  
  @override
  void initState() {
    // Set preferred camera to front for better self-viewing
    preferredCameraLensDirection = CameraLensDirection.front;
    
    // Create analyzer before calling super.initState() which starts camera
    analyzer = BicepCurlAnalyzer();
    voiceFeedback = VoiceFeedbackService();
    
    // Initialize voice feedback service
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
  
  @override
  Future<void> processPose(Pose pose) async {
    // Process pose using the bicep curl analyzer
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
      "keep your elbow close","Curl all the way up"
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
        
        // Pose guide overlay (transparent outline of correct form)
        if (showPoseGuide && !showCountdown)
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Container(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/data/images/workouts/image 5.png',
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
                    'Position yourself sideways to the camera',
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
          // Top status row with enhanced design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ExerciseUIComponents.buildStatusRow(
              statusBoxes: [
                // Custom Rep counter
                analyzer.activeArm == "none" 
                ? ExerciseUIComponents.buildStatusBox(
                    label: 'REPS',
                    value: 'UNK',
                    color: Colors.grey,
                    fontSize: 20,
                  )
                : ExerciseUIComponents.buildRepCounter(
                    count: analyzer.activeArmAnalysis.counter,
                  ),
                
                // Active arm display with icon
                ExerciseUIComponents.buildStatusBox(
                  label: 'ARM',
                  value: analyzer.activeArm.toUpperCase(),
                  color: analyzer.activeArm == "none" 
                         ? Colors.grey 
                         : ExerciseUIComponents.primaryColor,
                ),
              ],
            ),
          ),
          
          // Second status row - Elbow and Form status with improved design
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: ExerciseUIComponents.buildStatusRow(
              statusBoxes: [
                // Elbow status with appropriate color
                ExerciseUIComponents.buildStatusBox(
                  label: 'ELBOW',
                  value: analyzer.activeArm == "none" ? 
                         'UNK' : analyzer.activeArmAnalysis.elbowStatus,
                  color: analyzer.activeArm == "none" ? 
                         Colors.grey : ExerciseUIComponents.getStatusColor(
                           analyzer.activeArmAnalysis.elbowStatus
                         ),
                ),
                
                // Form status with appropriate color
                ExerciseUIComponents.buildStatusBox(
                  label: 'FORM',
                  value: analyzer.activeArm == "none" ? 
                         'UNK' : analyzer.activeArmAnalysis.formStatus,
                  color: analyzer.activeArm == "none" ? 
                         Colors.grey : ExerciseUIComponents.getStatusColor(
                           analyzer.activeArmAnalysis.formStatus
                         ),
                ),
              ],
            ),
          ),
          
          // Bottom feedback with enhanced design
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Form feedback with icon
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
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fitmate/screens/exercise_form/utils/pose_utils.dart';
import 'dart:math' as math;

/// Analyzer for plank form detection
class PlankAnalyzer {
  // Form status
  String formStatus = "UNK";
  String backStatus = "UNK";
  
  // Visibility threshold for landmarks
  static const double VISIBILITY_THRESHOLD = 0.5;
  
  // Thresholds for plank form
  static const double MAX_ACCEPTABLE_BACK_ANGLE = 15.0; // Degrees deviation from straight line
  
  // Duration counter
  int startTime = 0;
  int currentDuration = 0; // in seconds
  bool isCountingDuration = false;
  bool hasStartedPlank = false; // Track if plank has ever been started
  int lastGoodFormTime = 0; // Time when good form was last detected
  
  // Required landmarks for plank analysis
  final List<PoseLandmarkType> REQUIRED_LANDMARKS = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];
  
  // Debug values
  double backAngle = 0.0;
  
  /// Process a new pose frame for plank analysis
  void analyzePose(Pose pose) {
    try {
      // Convert pose to landmark map for easier access
      Map<PoseLandmarkType, PoseLandmark> landmarks = PoseUtils.createLandmarkMap(pose);
      
      // Check visibility of critical landmarks
      bool allLandmarksVisible = PoseUtils.areLandmarksVisible(
        landmarks, 
        REQUIRED_LANDMARKS,
        VISIBILITY_THRESHOLD
      );
      
      if (!allLandmarksVisible) {
        formStatus = "UNK";
        backStatus = "UNK";
        return;
      }

      // Analyze back position (straight, too high, too low)
      _analyzeBackPosition(landmarks);
      
      
      // Update overall form status
      _updateFormStatus();
      
      // Update duration counter if form is correct
      _updateDurationCounter();
      
    } catch (e) {
      print('Error in PlankAnalyzer.analyzePose: $e');
      formStatus = "UNK";
    }
  }
  
  /// Analyze if the back is straight, too high, or too low
  void _analyzeBackPosition(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Get the midpoints of shoulders, hips, and ankles
    final shoulderMidpoint = _getMidpoint(
      landmarks[PoseLandmarkType.leftShoulder]!,
      landmarks[PoseLandmarkType.rightShoulder]!
    );
    
    final hipMidpoint = _getMidpoint(
      landmarks[PoseLandmarkType.leftHip]!,
      landmarks[PoseLandmarkType.rightHip]!
    );
    
    final ankleMidpoint = _getMidpoint(
      landmarks[PoseLandmarkType.leftAnkle]!,
      landmarks[PoseLandmarkType.rightAnkle]!
    );
    
    // Calculate the angle between shoulder-hip-ankle
    // In a perfect plank, this should be close to 180 degrees (straight line)
    backAngle = PoseUtils.calculateAngle(
      shoulderMidpoint,
      hipMidpoint,
      ankleMidpoint
    );
    
    // Convert to deviation from 180 degrees (straight line)
    double deviationAngle = 180.0 - backAngle;
    
    // Classify back position based on deviation angle
    if (deviationAngle.abs() <= MAX_ACCEPTABLE_BACK_ANGLE) {
      backStatus = "Good";
    } else if (deviationAngle > MAX_ACCEPTABLE_BACK_ANGLE) {
      // If deviation is positive, hips are too high
      backStatus = "Too High";
    } else {
      // If deviation is negative, hips are too low
      backStatus = "Too Low";
    }
  }
  
  
  /// Update overall form status based on individual checks
  void _updateFormStatus() {
    if (backStatus == "UNK") {
      formStatus = "UNK";
    } else if (backStatus == "Good") {
      formStatus = "Good";
      // Record the time when good form was last seen
      lastGoodFormTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      formStatus = "Needs Correction";
    }
  }
  
  /// Calculate midpoint between two landmarks
  List<double> _getMidpoint(PoseLandmark landmarkA, PoseLandmark landmarkB) {
    return [
      (landmarkA.x + landmarkB.x) / 2,
      (landmarkA.y + landmarkB.y) / 2
    ];
  }
  
  /// Update duration counter if form is correct
  void _updateDurationCounter() {
    final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
    
    if (formStatus == "Good") {
      if (!isCountingDuration) {
        // Start counting if it's the first good form detection
        startTime = currentTimeMs;
        isCountingDuration = true;
        hasStartedPlank = true; // Mark that plank has been started
      }
      
      // Update current duration
      currentDuration = ((currentTimeMs - startTime) / 1000).floor(); // Convert to seconds
    } else if (formStatus != "UNK" && hasStartedPlank) {
      // If form is not good but plank was started before, 
      // we don't reset the timer, just pause it
      isCountingDuration = false;
    }
  }
  
  /// Reset duration counter
  void resetDuration() {
    startTime = 0;
    currentDuration = 0;
    isCountingDuration = false;
    hasStartedPlank = false;
  }
  
  /// Get form feedback text based on current form analysis
  String getFormFeedback() {
    // If no pose is detected or visibility is low
    if (formStatus == "UNK") {
      return "Position yourself so your full body is visible";
    }
    
    // Form feedback based on status
    if (backStatus == "Too High") {
      return "Lower your hips to form a straight line with your body";
    } else if (backStatus == "Too Low") {
      return "Lift your hips to form a straight line with your body";
    } else if (formStatus == "Good") {
      if (currentDuration < 5) {
        return "Great form! Maintain this position";
      } else if (currentDuration < 15) {
        return "Keep going! Breathe normally";
      } else if (currentDuration < 30) {
        return "Excellent! Stay tight and maintain your form";
      } else {
        return "Amazing plank! Focus on breathing and core engagement";
      }
    } else {
      return "Align your body to form a straight line from head to heels";
    }
  }
  
  /// Get position instructions for plank
  String getPositionInstructions() {
    return "Position yourself in a forearm plank with side view to camera";
  }
}
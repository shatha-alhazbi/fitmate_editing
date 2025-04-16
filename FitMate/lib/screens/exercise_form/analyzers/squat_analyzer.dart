import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fitmate/screens/exercise_form/utils/pose_utils.dart';

/// Analyzer for squat form and rep counting
class SquatAnalyzer {
  // Counter vars
  int counter = 0;
  String currentStage = "up";
  static const double PREDICTION_PROB_THRESHOLD = 0.7;
  
  // Visibility threshold
  static const double VISIBILITY_THRESHOLD = 0.4;
  
  // Form analysis thresholds
  static const List<double> FOOT_SHOULDER_RATIO_THRESHOLDS = [1.2, 2.8];
  static const Map<String, List<double>> KNEE_FOOT_RATIO_THRESHOLDS = {
    "up": [0.5, 1.0],
    "middle": [0.7, 1.0],
    "down": [0.85, 1.2],
  };
  
  // Form status
  String footPlacement = "UNK";
  String kneePlacement = "UNK";
  String facingDirection = "UNK"; // Added direction status
  
  // Debug values
  double kneeFootRatio = 0.0;
  double footShoulderRatio = 0.0;
  double shoulderWidth = 0.0; // Added for position detection
  
  // Added to prevent counting reps too quickly
  int _lastRepTimestamp = 0;
  final int _minMillisBetweenReps = 500; // Minimum 0.5 seconds between reps
  
  // Important landmarks for analysis
  final List<PoseLandmarkType> REQUIRED_LANDMARKS = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];
  
  /// Process a new pose frame for squat analysis
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
      
      // If any critical landmarks are missing, set to UNK but continue for partial analysis
      if (!allLandmarksVisible) {
        footPlacement = "UNK";
        kneePlacement = "UNK";
        facingDirection = "UNK";
      }

      // Check position/orientation for squat (should be facing the camera)
      _analyzeFacingDirection(landmarks);

      // Do rep counting ONLY if all landmarks are visible
      if (allLandmarksVisible) {
        _countReps(landmarks);
      }
      
      // Front view analysis for foot and knee positioning - can still run with partial visibility
      _analyzeFootKneePlacement(landmarks);
      
    } catch (e) {
      print('Error in SquatAnalyzer.analyzePose: $e');
    }
  }
  
  /// Analyze if the user is facing the camera or sideways
  void _analyzeFacingDirection(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final nose = landmarks[PoseLandmarkType.nose];
    
    // If key points aren't visible, can't determine direction
    if (leftShoulder == null || rightShoulder == null || nose == null ||
        leftShoulder.likelihood < VISIBILITY_THRESHOLD ||
        rightShoulder.likelihood < VISIBILITY_THRESHOLD ||
        nose.likelihood < VISIBILITY_THRESHOLD) {
      facingDirection = "UNK";
      return;
    }
    
    // Calculate shoulder width
    shoulderWidth = PoseUtils.calculateDistance(
      [leftShoulder.x, leftShoulder.y],
      [rightShoulder.x, rightShoulder.y],
    );
    
    // Calculate shoulder midpoint
    List<double> shoulderMidpoint = [
      (leftShoulder.x + rightShoulder.x) / 2,
      (leftShoulder.y + rightShoulder.y) / 2
    ];
    
    // Check if nose is aligned with shoulder midpoint
    // If facing the camera, nose should be close to shoulder midpoint horizontally
    double noseToMidpointHorizontalDiff = (nose.x - shoulderMidpoint[0]).abs();
    
    // Calculate relative distance (normalized by shoulder width to handle different distances from camera)
    double relativeHorizontalDiff = noseToMidpointHorizontalDiff / shoulderWidth;
    
    // When user is facing sideways, the nose will be significantly off-center from shoulder midpoint
    // When user is facing the camera, the nose will be close to the midpoint
    if (relativeHorizontalDiff > 0.25) { // Threshold for sideways orientation
      facingDirection = "Sideways";
    } else {
      facingDirection = "Facing Camera";
    }
  }

  /// Count reps based on knee angle
  void _countReps(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Calculate knee angle
    final kneeAngle = _calculateKneeAngle(landmarks);
    
    // Determine stage based on knee angle
    String predictedClass = "up";
    double predictionProbability = 0.0;
    
    if (kneeAngle < 140) {
      predictedClass = "down";
      predictionProbability = 0.9; // Confidence level
    } else {
      predictedClass = "up";
      predictionProbability = 0.9; // Confidence level
    }
    
    // Evaluate model prediction with time protection
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    bool timeCheckPassed = (currentTime - _lastRepTimestamp) > _minMillisBetweenReps;
    
    if (predictedClass == "down" && predictionProbability >= PREDICTION_PROB_THRESHOLD) {
      currentStage = "down";
    } else if (currentStage == "down" && predictedClass == "up" && 
              predictionProbability >= PREDICTION_PROB_THRESHOLD &&
              timeCheckPassed) {
      currentStage = "up";
      counter++;
      _lastRepTimestamp = currentTime;
    }
  }
  
  /// Calculate knee angle (used for rep counting)
  double _calculateKneeAngle(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Try using the side with better visibility
    PoseLandmark? leftHip = landmarks[PoseLandmarkType.leftHip];
    PoseLandmark? leftKnee = landmarks[PoseLandmarkType.leftKnee];
    PoseLandmark? leftAnkle = landmarks[PoseLandmarkType.leftAnkle];
    
    PoseLandmark? rightHip = landmarks[PoseLandmarkType.rightHip];
    PoseLandmark? rightKnee = landmarks[PoseLandmarkType.rightKnee];
    PoseLandmark? rightAnkle = landmarks[PoseLandmarkType.rightAnkle];
    
    double leftVisibility = (leftHip?.likelihood ?? 0) + (leftKnee?.likelihood ?? 0) + (leftAnkle?.likelihood ?? 0);
    double rightVisibility = (rightHip?.likelihood ?? 0) + (rightKnee?.likelihood ?? 0) + (rightAnkle?.likelihood ?? 0);
    
    // Use the side with better visibility
    if (leftVisibility >= rightVisibility && leftHip != null && leftKnee != null && leftAnkle != null) {
      return PoseUtils.calculateAngle(
        [leftHip.x, leftHip.y],
        [leftKnee.x, leftKnee.y],
        [leftAnkle.x, leftAnkle.y],
      );
    } else if (rightHip != null && rightKnee != null && rightAnkle != null) {
      return PoseUtils.calculateAngle(
        [rightHip.x, rightHip.y],
        [rightKnee.x, rightKnee.y],
        [rightAnkle.x, rightAnkle.y],
      );
    }
    
    // Default to standing position if can't calculate
    return 180.0;
  }
  
  /// Analyze foot and knee placement for form feedback
  void _analyzeFootKneePlacement(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Get foot landmarks
    PoseLandmark? leftFoot = landmarks[PoseLandmarkType.leftFootIndex] ?? landmarks[PoseLandmarkType.leftAnkle];
    PoseLandmark? rightFoot = landmarks[PoseLandmarkType.rightFootIndex] ?? landmarks[PoseLandmarkType.rightAnkle];
    final leftKnee = landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = landmarks[PoseLandmarkType.rightKnee];
    
    // If visibility of any keypoints is low, exit early
    if (leftFoot == null || rightFoot == null || 
        leftKnee == null || rightKnee == null ||
        leftFoot.likelihood < VISIBILITY_THRESHOLD ||
        rightFoot.likelihood < VISIBILITY_THRESHOLD ||
        leftKnee.likelihood < VISIBILITY_THRESHOLD ||
        rightKnee.likelihood < VISIBILITY_THRESHOLD) {
      footPlacement = "UNK";
      kneePlacement = "UNK";
      return;
    }
    
    // Calculate shoulder width
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftShoulder == null || rightShoulder == null ||
        leftShoulder.likelihood < VISIBILITY_THRESHOLD ||
        rightShoulder.likelihood < VISIBILITY_THRESHOLD) {
      footPlacement = "UNK";
      kneePlacement = "UNK";
      return;
    }
    
    final shoulderWidth = PoseUtils.calculateDistance(
      [leftShoulder.x, leftShoulder.y],
      [rightShoulder.x, rightShoulder.y],
    );
    
    // Calculate foot width
    final footWidth = PoseUtils.calculateDistance(
      [leftFoot.x, leftFoot.y],
      [rightFoot.x, rightFoot.y],
    );
    
    // Calculate foot and shoulder ratio
    footShoulderRatio = (footWidth / shoulderWidth * 10).round() / 10;
    
    // Analyze FOOT PLACEMENT
    final minRatioFootShoulder = FOOT_SHOULDER_RATIO_THRESHOLDS[0];
    final maxRatioFootShoulder = FOOT_SHOULDER_RATIO_THRESHOLDS[1];
    
    if (minRatioFootShoulder <= footShoulderRatio && footShoulderRatio <= maxRatioFootShoulder) {
      footPlacement = "Good";
    } else if (footShoulderRatio < minRatioFootShoulder) {
      footPlacement = "Too narrow";
    } else if (footShoulderRatio > maxRatioFootShoulder) {
      footPlacement = "Too wide";
    }
    
    // Calculate knee width
    final kneeWidth = PoseUtils.calculateDistance(
      [leftKnee.x, leftKnee.y],
      [rightKnee.x, rightKnee.y],
    );
    
    // Calculate knee-foot ratio
    kneeFootRatio = (kneeWidth / footWidth * 10).round() / 10;
    
    // Get thresholds for current stage
    String usedStage = currentStage.isEmpty ? "up" : currentStage;
    final List<double>? thresholds = KNEE_FOOT_RATIO_THRESHOLDS[usedStage] ?? 
                                 KNEE_FOOT_RATIO_THRESHOLDS["up"];
    
    if (thresholds == null || thresholds.length < 2) {
      kneePlacement = "UNK";
      return;
    }
    
    final minRatioKneeFoot = thresholds[0];
    final maxRatioKneeFoot = thresholds[1];
    
    
    if (minRatioKneeFoot <= kneeFootRatio && kneeFootRatio <= maxRatioKneeFoot) {
      kneePlacement = "Good"; // Correct
    } else if (kneeFootRatio < minRatioKneeFoot) {
      kneePlacement = "Too narrow"; // Too tight (knees too close)
    } else {
      kneePlacement = "UNK";
    }
  }
  
  /// Get form feedback text based on current form analysis
  String getFormFeedback() {
    // Check position first - highest priority feedback
    if (facingDirection == "Sideways") {
      return "Please face the camera directly for proper squat analysis";
    }
    
    // If no pose is detected or visibility is low
    if (footPlacement == "UNK" && kneePlacement == "UNK") {
      return "Position yourself so your lower body is clearly visible";
    }
    
    // Front view feedback
    if (footPlacement == "Too narrow") {
      return "Stand with feet wider apart";
    } else if (footPlacement == "Too wide") {
      return "Bring your feet closer together";
    } else if (kneePlacement == "Too narrow") {
      return "Push your knees outward as you squat";
    } else if (currentStage == "down") {
      return "Good form! Push through your heels to stand up";
    } else {
      return "Good! Now bend your knees and squat down";
    }
  }
  
  /// Get position instructions for squat
  String getPositionInstructions() {
    return "Face the camera with feet shoulder-width apart, full body visible";
  }
}
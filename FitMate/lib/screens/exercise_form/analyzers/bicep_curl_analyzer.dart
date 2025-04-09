import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fitmate/screens/exercise_form/utils/pose_utils.dart';
import 'dart:math' as math;

/// Single arm analysis class
class ArmAnalysis {
  final String side;
  int counter = 0;
  String stage = "down";
  bool isVisible = false;
  
  // Thresholds
  final double stageDownThreshold = 120.0;
  final double stageUpThreshold = 90.0;
  final double peakContractionThreshold = 60.0;
  final double looseUpperArmAngleThreshold = 40.0;
  final double visibilityThreshold = 0.65;
  
  // Minimum angle range required to count as a rep
  final double minAngleChangeForRep = 40.0;
  
  // Track angle ranges for rep quality
  double lowestUpAngle = 180.0;
  double highestDownAngle = 0.0;
  
  // Timestamp for last rep count
  int lastRepTimestamp = 0;
  final int minMillisBetweenReps = 500; // Minimum 0.5 seconds between reps
  
  // Track coordinates
  List<double>? shoulder;
  List<double>? elbow;
  List<double>? wrist;
  
  // For peak contraction tracking
  double peakContractionAngle = 1000;
  
  // Form status values
  String elbowStatus = "UNK";
  String formStatus = "UNK";
  
  // Store actual angles for debugging
  int elbowAngle = 0;
  int curlAngle = 0;
  
  ArmAnalysis({required this.side});
  
  /// Process landmarks and analyze form
  void analyzePose(Map<PoseLandmarkType, PoseLandmark> landmarks) {
    // Get proper landmarks based on side
    final shoulderLandmark = side == "left" 
        ? landmarks[PoseLandmarkType.leftShoulder] 
        : landmarks[PoseLandmarkType.rightShoulder];
    
    final elbowLandmark = side == "left" 
        ? landmarks[PoseLandmarkType.leftElbow] 
        : landmarks[PoseLandmarkType.rightElbow];
    
    final wristLandmark = side == "left" 
        ? landmarks[PoseLandmarkType.leftWrist] 
        : landmarks[PoseLandmarkType.rightWrist];
    
    // Check visibility
    if (shoulderLandmark == null || elbowLandmark == null || wristLandmark == null ||
        shoulderLandmark.likelihood < visibilityThreshold ||
        elbowLandmark.likelihood < visibilityThreshold ||
        wristLandmark.likelihood < visibilityThreshold) {
      isVisible = false;
      return;
    }
    
    isVisible = true;
    
    // Store coordinates
    shoulder = [shoulderLandmark.x, shoulderLandmark.y];
    elbow = [elbowLandmark.x, elbowLandmark.y];
    wrist = [wristLandmark.x, wristLandmark.y];
    
    // Calculate curl angle (shoulder-elbow-wrist)
    double armAngle = PoseUtils.calculateAngle(shoulder!, elbow!, wrist!);
    curlAngle = armAngle.toInt();
    
    String prevStage = stage;
    
    // Determine current stage based on arm angle
    if (armAngle <= stageUpThreshold) {
      // Moving to up position
      stage = "up";
      
      // Track the lowest angle reached during the up phase
      if (armAngle < lowestUpAngle) {
        lowestUpAngle = armAngle;
      }
    } else if (armAngle >= stageDownThreshold) {
      // Moving to down position
      stage = "down";
      
      // Track the highest angle reached during the down phase
      if (armAngle > highestDownAngle) {
        highestDownAngle = armAngle;
      }
    }
    
    // Count reps with improved logic
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    bool timeCheckPassed = (currentTime - lastRepTimestamp) > minMillisBetweenReps;
    
    if (prevStage == "down" && stage == "up" && timeCheckPassed) {
      // Check if there was enough range of motion in the previous down phase
      if (highestDownAngle - lowestUpAngle >= minAngleChangeForRep) {
        counter++;
        lastRepTimestamp = currentTime;
      }
      
      // Reset tracking for the next rep
      highestDownAngle = 0.0;
    } else if (prevStage == "up" && stage == "down") {
      // Reset the lowest up angle when transitioning to down
      lowestUpAngle = 180.0;
    }
    
    // Error detection: loose upper arm - check how far elbow is from body
    bool elbowFlaring = _calculateElbowMovement(elbow!, shoulder!, wrist!);
    
    // Store the flaring status for debugging
    elbowStatus = elbowFlaring ? "Too Far Out" : "Good";
    
    // Store elbow angle for debugging
    elbowAngle = elbowFlaring ? 1 : 0; // Just using this to indicate flaring
    
    // Error detection: peak contraction (range of motion)
    if (stage == "up" && armAngle < peakContractionAngle) {
      // Save peaked contraction every rep
      peakContractionAngle = armAngle;
      
      // Update form status based on current angle
      if (armAngle <= peakContractionThreshold) {
        formStatus = "Good";
      } else if (armAngle <= peakContractionThreshold + 15) {
        formStatus = "Curl Higher";
      } else {
        formStatus = "Half Rep";
      }
    } else if (stage == "down") {
      // Evaluate if the peak is higher than threshold
      if (peakContractionAngle != 1000) {
        if (peakContractionAngle >= peakContractionThreshold + 15) {
          formStatus = "Half Rep";
        } else if (peakContractionAngle >= peakContractionThreshold) {
          formStatus = "Curl Higher";
        } else {
          formStatus = "Good";
        }
      }
      
      // Reset tracking
      peakContractionAngle = 1000;
    }
  }
  
  /// Detect elbow movement/flaring
  bool _calculateElbowMovement(List<double> elbow, List<double> shoulder, List<double> wrist) {
    // Get the vector from shoulder to elbow
    double shoulderToElbowX = elbow[0] - shoulder[0];
    double shoulderToElbowY = elbow[1] - shoulder[1];
    
    // Calculate the horizontal deviation of the elbow
    // Normalize the shoulder-to-elbow vector
    double length = math.sqrt(shoulderToElbowX * shoulderToElbowX + shoulderToElbowY * shoulderToElbowY);
    if (length < 0.01) return false; // Avoid division by zero
    
    // Calculate how far the elbow deviates from being directly below the shoulder
    double horizontalDeviation = (shoulderToElbowX).abs() / length;
    
    // Return true if deviation is significant
    return horizontalDeviation > 0.5; // High threshold to only catch severe cases
  }
}

/// Main analyzer class for bicep curl exercise
class BicepCurlAnalyzer {
  // Create analyzers for both arms
  final ArmAnalysis leftArmAnalysis = ArmAnalysis(side: "left");
  final ArmAnalysis rightArmAnalysis = ArmAnalysis(side: "right");
  
  // For displaying which arm is being actively tracked
  String activeArm = "both";
  
  // Required landmarks for bicep curl analysis
  final List<PoseLandmarkType> REQUIRED_LANDMARKS = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
  ];
  
  /// Process a new pose frame and update arm analyses
  void analyzePose(Pose pose) {
    try {
      // Create landmark map for easier access
      Map<PoseLandmarkType, PoseLandmark> landmarkMap = PoseUtils.createLandmarkMap(pose);
      
      // Process both arms
      leftArmAnalysis.analyzePose(landmarkMap);
      rightArmAnalysis.analyzePose(landmarkMap);
      
      // Determine which arm is more visible or active
      if (leftArmAnalysis.isVisible && rightArmAnalysis.isVisible) {
        // If both arms are visible, use the one that appears larger in the camera
        // (likely the one closest to the camera)
        if (leftArmAnalysis.shoulder != null && rightArmAnalysis.shoulder != null) {
          // Calculate apparent arm length to determine which is closer
          double leftArmLength = PoseUtils.calculateDistance(
            leftArmAnalysis.shoulder!, leftArmAnalysis.elbow!
          );
          
          double rightArmLength = PoseUtils.calculateDistance(
            rightArmAnalysis.shoulder!, rightArmAnalysis.elbow!
          );
          
          activeArm = leftArmLength > rightArmLength ? "left" : "right";
        }
      } else if (leftArmAnalysis.isVisible) {
        activeArm = "left";
      } else if (rightArmAnalysis.isVisible) {
        activeArm = "right";
      } else {
        activeArm = "none";
      }
    } catch (e) {
      print('Error processing bicep curl pose: $e');
    }
  }
  
  /// Get the currently active arm's analysis
  ArmAnalysis get activeArmAnalysis {
    return activeArm == "left" ? leftArmAnalysis : rightArmAnalysis;
  }
  
  /// Get feedback text based on active arm's analysis
  String getFormFeedback() {
    // If no arm is visible
    if (activeArm == "none") {
      return "Position yourself so your arms are visible";
    }
    
    // Get the active arm's analysis
    final analysis = activeArmAnalysis;
    
    // Generate feedback based on current stage and errors
    if (analysis.stage == "up") {
      if (analysis.elbowStatus == "Too Far Out") {
        return "Keep your elbow close to your body";
      } else if (analysis.formStatus == "Half Rep") {
        return "Curl all the way up for full contraction";
      } else if (analysis.formStatus == "Curl Higher") {
        return "Curl higher to get full bicep contraction";
      } else {
        return "Good form! Now lower the weight with control";
      }
    } else { // down stage
      if (analysis.elbowStatus == "Too Far Out") {
        return "Keep your elbow close to your body";
      } else if (analysis.formStatus == "Extend Fully") {
        return "Extend your arm fully at the bottom";
      } else {
        return "Good! Now curl the weight up smoothly";
      }
    }
  }
  
  /// Get position instructions for bicep curl
  String getPositionInstructions() {
    return "Stand sideways to the camera with arm visible and whole body in frame";
  }
}
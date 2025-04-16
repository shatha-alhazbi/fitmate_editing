// integration_test/exercise_form_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmate/main.dart' as app;
import 'package:fitmate/screens/exercise_form/analyzers/squat_analyzer.dart';
import 'package:fitmate/screens/exercise_form/analyzers/bicep_curl_analyzer.dart';
import 'package:fitmate/screens/exercise_form/analyzers/plank_analyzer.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'helpers/test_helpers.dart';
import 'helpers/camera_pose_mock.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Exercise Form Analysis Unit Tests', () {
    late MockPoseDetector mockPoseDetector;
    
    setUp(() {
      mockPoseDetector = MockPoseDetector();
    });
    
    test('Squat Analyzer detects correct form', () {
      final analyzer = SquatAnalyzer();
      
      // Create a pose with good squat form
      final goodPose = createGoodSquatPose();
      
      // Analyze the pose
      analyzer.analyzePose(goodPose);
      
      // Check that the analyzer detected good form
      expect(analyzer.footPlacement, 'Good');
      expect(analyzer.kneePlacement, 'Good');
    });
    
    test('Squat Analyzer detects knees caving in', () {
      final analyzer = SquatAnalyzer();
      
      // Create a pose with knees caving in
      final badPose = createBadSquatPose();
      
      // Analyze the pose
      analyzer.analyzePose(badPose);
      
      // Check that the analyzer detected the issue
      expect(analyzer.kneePlacement, 'Too narrow');
    });
    
    test('Bicep Curl Analyzer detects good form', () {
      final analyzer = BicepCurlAnalyzer();
      
      // Create a pose with good bicep curl form
      final goodPose = createGoodBicepCurlPose();
      
      // Analyze the pose
      analyzer.analyzePose(goodPose);
      
      // Verify good form detection
      expect(analyzer.activeArmAnalysis.elbowStatus, 'Good');
      expect(analyzer.activeArmAnalysis.formStatus, 'Good');
    });
    
    test('Bicep Curl Analyzer detects elbow flaring', () {
      final analyzer = BicepCurlAnalyzer();
      
      // Create a pose with poor bicep curl form (elbow flaring)
      final badPose = createBadBicepCurlPose();
      
      // Analyze the pose
      analyzer.analyzePose(badPose);
      
      // Verify problem detection
      expect(analyzer.activeArmAnalysis.elbowStatus, 'Too Far Out');
    });
    
    test('Plank Analyzer detects good form', () {
      final analyzer = PlankAnalyzer();
      
      // Create a pose with good plank form
      final goodPose = createGoodPlankPose();
      
      // Analyze the pose
      analyzer.analyzePose(goodPose);
      
      // Verify good form detection
      expect(analyzer.backStatus, 'Good');
      expect(analyzer.formStatus, 'Good');
    });
    
    test('Plank Analyzer detects hips too high', () {
      final analyzer = PlankAnalyzer();
      
      // Create a pose with hips too high
      final badPose = createBadPlankPoseHipsHigh();
      
      // Analyze the pose
      analyzer.analyzePose(badPose);
      
      // Verify problem detection
      expect(analyzer.backStatus, 'Too High');
      expect(analyzer.formStatus, 'Needs Correction');
    });
    
    test('Plank Analyzer detects hips too low', () {
      final analyzer = PlankAnalyzer();
      
      // Create a pose with hips too low
      final badPose = createBadPlankPoseHipsLow();
      
      // Analyze the pose
      analyzer.analyzePose(badPose);
      
      // Verify problem detection
      expect(analyzer.backStatus, 'Too Low');
      expect(analyzer.formStatus, 'Needs Correction');
    });
  });

  // Helper methods to create specific poses for testing
  Pose createGoodSquatPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a good squat pose
    // Shoulders aligned with hips
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.4, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.6, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Hips aligned properly
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0.4, y: 0.6, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: 0.6, y: 0.6, z: 0.0, likelihood: 0.9,
    );
    
    // Knees aligned with feet (good form)
    landmarks[PoseLandmarkType.leftKnee] = PoseLandmark(
      type: PoseLandmarkType.leftKnee,
      x: 0.4, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightKnee] = PoseLandmark(
      type: PoseLandmarkType.rightKnee,
      x: 0.6, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    
    // Feet at proper stance width
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: 0.4, y: 0.9, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: 0.6, y: 0.9, z: 0.0, likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  Pose createBadSquatPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a bad squat pose (knees caving in)
    // Shoulders aligned with hips
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.4, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.6, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Hips aligned properly
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0.4, y: 0.6, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: 0.6, y: 0.6, z: 0.0, likelihood: 0.9,
    );
    
    // Knees caving in (bad form)
    landmarks[PoseLandmarkType.leftKnee] = PoseLandmark(
      type: PoseLandmarkType.leftKnee,
      x: 0.45, y: 0.75, z: 0.0, likelihood: 0.9, // Moved inward
    );
    landmarks[PoseLandmarkType.rightKnee] = PoseLandmark(
      type: PoseLandmarkType.rightKnee,
      x: 0.55, y: 0.75, z: 0.0, likelihood: 0.9, // Moved inward
    );
    
    // Feet at proper stance width
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: 0.4, y: 0.9, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: 0.6, y: 0.9, z: 0.0, likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  Pose createGoodBicepCurlPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a good bicep curl
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.4, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Elbow close to body (good form)
    landmarks[PoseLandmarkType.leftElbow] = PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0.41, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    
    // Wrist position for curl
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0.45, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    
    // Right side landmarks (can be less accurate)
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.6, y: 0.3, z: 0.0, likelihood: 0.6,
    );
    landmarks[PoseLandmarkType.rightElbow] = PoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: 0.62, y: 0.5, z: 0.0, likelihood: 0.6,
    );
    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: 0.65, y: 0.6, z: 0.0, likelihood: 0.6,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  Pose createBadBicepCurlPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a bad bicep curl (elbow flaring out)
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.4, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Elbow far from body (poor form)
    landmarks[PoseLandmarkType.leftElbow] = PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0.3, y: 0.5, z: 0.0, likelihood: 0.9, // Moved outward
    );
    
    // Wrist position for curl
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0.35, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    
    // Right side landmarks
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.6, y: 0.3, z: 0.0, likelihood: 0.6,
    );
    landmarks[PoseLandmarkType.rightElbow] = PoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: 0.62, y: 0.5, z: 0.0, likelihood: 0.6,
    );
    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: 0.65, y: 0.6, z: 0.0, likelihood: 0.6,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  Pose createGoodPlankPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a good plank (straight line from shoulders to ankles)
    // Head position
    landmarks[PoseLandmarkType.nose] = PoseLandmark(
      type: PoseLandmarkType.nose,
      x: 0.3, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Shoulders
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.35, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.25, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    
    // Elbows
    landmarks[PoseLandmarkType.leftElbow] = PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0.4, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightElbow] = PoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: 0.2, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    
    // Wrists
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0.45, y: 0.65, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: 0.15, y: 0.65, z: 0.0, likelihood: 0.9,
    );
    
    // Hips (aligned with shoulders for good form)
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0.55, y: 0.55, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: 0.45, y: 0.55, z: 0.0, likelihood: 0.9,
    );
    
    // Ankles
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: 0.75, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: 0.65, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  Pose createBadPlankPoseHipsHigh() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a plank with hips too high
    // Most landmarks same as good plank
    // ...
    
    // Head position
    landmarks[PoseLandmarkType.nose] = PoseLandmark(
      type: PoseLandmarkType.nose,
      x: 0.3, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Shoulders
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.35, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.25, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    
    // Elbows
    landmarks[PoseLandmarkType.leftElbow] = PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0.4, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightElbow] = PoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: 0.2, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    
    // Wrists
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0.45, y: 0.65, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: 0.15, y: 0.65, z: 0.0, likelihood: 0.9,
    );
    
    // Hips too high
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0.55, y: 0.45, z: 0.0, likelihood: 0.9, // Y value decreased (higher position)
    );
    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: 0.45, y: 0.45, z: 0.0, likelihood: 0.9, // Y value decreased (higher position)
    );
    
    // Ankles
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: 0.75, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: 0.65, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  Pose createBadPlankPoseHipsLow() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Create landmarks for a plank with hips too low
    // Most landmarks same as good plank
    // ...
    
    // Head position
    landmarks[PoseLandmarkType.nose] = PoseLandmark(
      type: PoseLandmarkType.nose,
      x: 0.3, y: 0.3, z: 0.0, likelihood: 0.9,
    );
    
    // Shoulders
    landmarks[PoseLandmarkType.leftShoulder] = PoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.35, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightShoulder] = PoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.25, y: 0.35, z: 0.0, likelihood: 0.9,
    );
    
    // Elbows
    landmarks[PoseLandmarkType.leftElbow] = PoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0.4, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightElbow] = PoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: 0.2, y: 0.5, z: 0.0, likelihood: 0.9,
    );
    
    // Wrists
    landmarks[PoseLandmarkType.leftWrist] = PoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0.45, y: 0.65, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightWrist] = PoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: 0.15, y: 0.65, z: 0.0, likelihood: 0.9,
    );
    
    // Hips too low
    landmarks[PoseLandmarkType.leftHip] = PoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0.55, y: 0.65, z: 0.0, likelihood: 0.9, // Y value increased (lower position)
    );
    landmarks[PoseLandmarkType.rightHip] = PoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: 0.45, y: 0.65, z: 0.0, likelihood: 0.9, // Y value increased (lower position)
    );
    
    // Ankles
    landmarks[PoseLandmarkType.leftAnkle] = PoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: 0.75, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    landmarks[PoseLandmarkType.rightAnkle] = PoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: 0.65, y: 0.75, z: 0.0, likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
}
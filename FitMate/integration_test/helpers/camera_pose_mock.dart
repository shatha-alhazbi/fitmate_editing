// integration_test/helpers/camera_pose_mocks.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:mockito/mockito.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes for camera
class MockCameraController extends Mock implements CameraController {
  @override
  Future<void> initialize() async {
    return;
  }
  
  @override
  Future<void> startImageStream(Function(CameraImage) onAvailable) async {
    // Simulate a camera image
    final Uint8List bytes = Uint8List(10); // Dummy bytes
    
    // Create a mock camera image
    final CameraImage mockImage = CameraImage(
      width: 1280,
      height: 720,
      format: ImageFormat.yuv420,
      planes: [
        CameraImagePlane(
          bytes: bytes,
          bytesPerPixel: 1,
          bytesPerRow: 1280,
          height: 720,
          width: 1280,
        ),
        CameraImagePlane(
          bytes: bytes,
          bytesPerPixel: 1,
          bytesPerRow: 640,
          height: 360,
          width: 640,
        ),
        CameraImagePlane(
          bytes: bytes,
          bytesPerPixel: 1,
          bytesPerRow: 640,
          height: 360,
          width: 640,
        ),
      ],
    );
    
    // Simulate camera delivering frames
    Future.delayed(Duration(milliseconds: 100), () {
      onAvailable(mockImage);
    });
    
    return;
  }
  
  @override
  Future<void> stopImageStream() async {
    return;
  }
}

class MockCameraDescription extends Mock implements CameraDescription {
  @override
  CameraLensDirection get lensDirection => CameraLensDirection.back;
  
  @override
  int get sensorOrientation => 0;
}

// Mock classes for pose detection
class MockPoseDetector extends Mock implements PoseDetector {
  @override
  Future<List<Pose>> processImage(InputImage inputImage) async {
    return [createMockPose()];
  }
  
  Pose createMockPose() {
    // Create a mock pose with reasonable joint positions
    // This would be customized based on which exercise you're testing
    
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Add key landmarks for different exercises
    // Example for squat form:
    landmarks[PoseLandmarkType.nose] = _createPoseLandmark(
      type: PoseLandmarkType.nose,
      x: 0.5,
      y: 0.2,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.leftShoulder] = _createPoseLandmark(
      type: PoseLandmarkType.leftShoulder,
      x: 0.4,
      y: 0.3,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.rightShoulder] = _createPoseLandmark(
      type: PoseLandmarkType.rightShoulder,
      x: 0.6,
      y: 0.3,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.leftElbow] = _createPoseLandmark(
      type: PoseLandmarkType.leftElbow,
      x: 0.35,
      y: 0.4,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.rightElbow] = _createPoseLandmark(
      type: PoseLandmarkType.rightElbow,
      x: 0.65,
      y: 0.4,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.leftWrist] = _createPoseLandmark(
      type: PoseLandmarkType.leftWrist,
      x: 0.3,
      y: 0.5,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.rightWrist] = _createPoseLandmark(
      type: PoseLandmarkType.rightWrist,
      x: 0.7,
      y: 0.5,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.leftHip] = _createPoseLandmark(
      type: PoseLandmarkType.leftHip,
      x: 0.4,
      y: 0.6,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.rightHip] = _createPoseLandmark(
      type: PoseLandmarkType.rightHip,
      x: 0.6,
      y: 0.6,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.leftKnee] = _createPoseLandmark(
      type: PoseLandmarkType.leftKnee,
      x: 0.4,
      y: 0.75,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.rightKnee] = _createPoseLandmark(
      type: PoseLandmarkType.rightKnee,
      x: 0.6,
      y: 0.75,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.leftAnkle] = _createPoseLandmark(
      type: PoseLandmarkType.leftAnkle,
      x: 0.4,
      y: 0.9,
      likelihood: 0.9,
    );
    
    landmarks[PoseLandmarkType.rightAnkle] = _createPoseLandmark(
      type: PoseLandmarkType.rightAnkle,
      x: 0.6,
      y: 0.9,
      likelihood: 0.9,
    );
    
    return Pose(landmarks: landmarks);
  }
  
  // Helper method to create a PoseLandmark
  PoseLandmark _createPoseLandmark({
    required PoseLandmarkType type,
    required double x,
    required double y,
    required double likelihood,
  }) {
    return PoseLandmark(
      type: type,
      x: x,
      y: y,
      z: 0.0, // Z coordinate not important for 2D tests
      likelihood: likelihood,
    );
  }
  
  // Create a mock pose for a good squat
  Pose createGoodSquatPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Set up a pose where:
    // - Knees are aligned with feet
    // - Depth is appropriate
    // - Back is straight
    
    // (Add landmarks with proper positions)
    
    return Pose(landmarks: landmarks);
  }
  
  // Create a mock pose for a bad squat (knees caving in)
  Pose createBadSquatPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Set up a pose where knees cave inward
    
    // (Add landmarks with positions showing poor form)
    
    return Pose(landmarks: landmarks);
  }
  
  // Create a mock pose for a good bicep curl
  Pose createGoodBicepCurlPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Set up a pose with good bicep curl form
    
    // (Add landmarks with proper positions)
    
    return Pose(landmarks: landmarks);
  }
  
  // Create a mock pose for a bad bicep curl (elbow moving away from body)
  Pose createBadBicepCurlPose() {
    final Map<PoseLandmarkType, PoseLandmark> landmarks = {};
    
    // Set up a pose with poor bicep curl form
    
    // (Add landmarks with positions showing poor form)
    
    return Pose(landmarks: landmarks);
  }
}

// Mock helper for camera image
class CameraImagePlane implements Plane {
  @override
  final Uint8List bytes;
  @override
  final int bytesPerPixel;
  @override
  final int bytesPerRow;
  @override
  final int height;
  @override
  final int width;

  CameraImagePlane({
    required this.bytes,
    required this.bytesPerPixel,
    required this.bytesPerRow,
    required this.height,
    required this.width,
  });
}
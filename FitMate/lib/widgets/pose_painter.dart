
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final bool isFrontCamera;
  
  PosePainter({
    required this.pose,
    required this.imageSize,
    this.isFrontCamera = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Define paint styles for landmarks and connections
    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.green;
    
    final landmarkPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;
    
    // Draw connections between landmarks
    _drawConnections(canvas, size, connectionPaint);
    
    // Draw landmarks
    _drawLandmarks(canvas, size, landmarkPaint);
  }
  
  void _drawConnections(Canvas canvas, Size size, Paint paint) {
    // Define the main connections similar to MediaPipe POSE_CONNECTIONS
    final connections = [
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, Colors.red],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, Colors.orange],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, Colors.orange],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, Colors.purple],
      
      // Left arm
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, Colors.green],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, Colors.green],
      
      // Right arm
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, Colors.green],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, Colors.green],
      
      // Left leg
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, Colors.blue],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, Colors.blue],
      [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex, Colors.blue],
      
      // Right leg
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, Colors.blue],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, Colors.blue],
      [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex, Colors.blue],
    ];
    
    // Draw each connection
    for (final connection in connections) {
      final startType = connection[0] as PoseLandmarkType;
      final endType = connection[1] as PoseLandmarkType;
      final color = connection[2] as Color;
      
      final startLandmark = pose.landmarks[startType];
      final endLandmark = pose.landmarks[endType];
      
      if (startLandmark != null && endLandmark != null) {
        canvas.drawLine(
          _landmarkPosition(startLandmark, size),
          _landmarkPosition(endLandmark, size),
          paint..color = color,
        );
      }
    }
  }
  
  void _drawLandmarks(Canvas canvas, Size size, Paint paint) {
    // Key landmarks to highlight with larger circles
    final keyLandmarks = {
      PoseLandmarkType.leftShoulder: [Colors.red, 8.0],
      PoseLandmarkType.rightShoulder: [Colors.red, 8.0],
      PoseLandmarkType.leftHip: [Colors.purple, 8.0],
      PoseLandmarkType.rightHip: [Colors.purple, 8.0],
      PoseLandmarkType.leftKnee: [Colors.blue, 8.0],
      PoseLandmarkType.rightKnee: [Colors.blue, 8.0],
      PoseLandmarkType.leftAnkle: [Colors.blue, 8.0],
      PoseLandmarkType.rightAnkle: [Colors.blue, 8.0],
      PoseLandmarkType.leftFootIndex: [Colors.blue, 6.0],
      PoseLandmarkType.rightFootIndex: [Colors.blue, 6.0],
    };
    
    // Draw all landmarks
    pose.landmarks.forEach((type, landmark) {
      // Use special styling for key landmarks
      if (keyLandmarks.containsKey(type)) {
        final style = keyLandmarks[type]!;
        final color = style[0] as Color;
        final radius = style[1] as double;
        
        canvas.drawCircle(
          _landmarkPosition(landmark, size),
          radius,
          paint..color = color,
        );
      } else {
        // Draw smaller circles for other landmarks
        canvas.drawCircle(
          _landmarkPosition(landmark, size),
          4.0,
          paint..color = Colors.white,
        );
      }
    });
  }
  
  Offset _landmarkPosition(PoseLandmark landmark, Size size) {
    // For front camera, we need to mirror the x coordinate
    double x = landmark.x;
    if (isFrontCamera) {
      // Mirror the x coordinate
      x = imageSize.width - x;
    }
    
    // Convert to screen coordinates
    return Offset(
      x * size.width / imageSize.width,
      landmark.y * size.height / imageSize.height,
    );
  }
  
  @override
  bool shouldRepaint(PosePainter oldDelegate) => true;
}


import 'dart:math' as math;
import 'package:google_ml_kit/google_ml_kit.dart';

/// Utility class for pose-related calculations
class PoseUtils {
  /// Calculate angle between three points (in degrees)
  static double calculateAngle(List<double> a, List<double> b, List<double> c) {
    try {
      final ab = [a[0] - b[0], a[1] - b[1]];
      final cb = [c[0] - b[0], c[1] - b[1]];
      
      // Dot product
      final dot = ab[0] * cb[0] + ab[1] * cb[1];
      
      // Magnitudes
      final magAB = math.sqrt(ab[0] * ab[0] + ab[1] * ab[1]);
      final magCB = math.sqrt(cb[0] * cb[0] + cb[1] * cb[1]);
      
      // Avoid division by zero
      if (magAB == 0 || magCB == 0) return 180.0;
      
      // Angle in radians, then converted to degrees
      double angle = math.acos(dot / (magAB * magCB));
      
      // Convert to degrees
      angle = angle * 180 / math.pi;
      
      return angle;
    } catch (e) {
      print('Error calculating angle: $e');
      return 180.0;
    }
  }
  
  /// Calculate distance between two points
  static double calculateDistance(List<double> pointA, List<double> pointB) {
    final x1 = pointA[0];
    final y1 = pointA[1];
    final x2 = pointB[0];
    final y2 = pointB[1];
    
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2));
  }
  
  /// Check if all specified landmarks are visible with sufficient confidence
  static bool areLandmarksVisible(
    Map<PoseLandmarkType, PoseLandmark> landmarks,
    List<PoseLandmarkType> requiredLandmarks,
    double visibilityThreshold
  ) {
    for (final landmarkType in requiredLandmarks) {
      final landmark = landmarks[landmarkType];
      if (landmark == null || landmark.likelihood < visibilityThreshold) {
        return false;
      }
    }
    return true;
  }
  
  /// Get coordinates of a landmark as a list [x, y]
  static List<double>? getLandmarkPosition(PoseLandmark? landmark) {
    if (landmark == null) return null;
    return [landmark.x, landmark.y];
  }
  
  /// Create a map of landmark types to landmarks from a pose
  static Map<PoseLandmarkType, PoseLandmark> createLandmarkMap(Pose pose) {
    final Map<PoseLandmarkType, PoseLandmark> landmarkMap = {};
    for (final landmark in pose.landmarks.entries) {
      landmarkMap[landmark.key] = landmark.value;
    }
    return landmarkMap;
  }
}
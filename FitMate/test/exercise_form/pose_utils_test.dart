import 'package:flutter_test/flutter_test.dart';
import 'package:fitmate/screens/exercise_form/utils/pose_utils.dart';

void main() {
  group('Angle calculation tests', () {
    test('calculateAngle returns correct angle for straight line', () {
      // Three points in a straight line should return 180 degrees
      final pointA = [0.0, 0.0];
      final pointB = [1.0, 0.0];
      final pointC = [2.0, 0.0];
      
      final angle = PoseUtils.calculateAngle(pointA, pointB, pointC);
      
      expect(angle, closeTo(180.0, 0.1));
    });
    
    test('calculateAngle returns correct angle for right angle', () {
      final pointA = [0.0, 0.0];
      final pointB = [1.0, 0.0];
      final pointC = [1.0, 1.0];
      
      final angle = PoseUtils.calculateAngle(pointA, pointB, pointC);
      
      expect(angle, closeTo(90.0, 0.1));
    });
    
    test('calculateAngle returns correct angle for acute angle', () {
  final pointA = [0.0, 0.0];
  final pointB = [1.0, 0.0];
  final pointC = [2.0, 1.0];
  
  final angle = PoseUtils.calculateAngle(pointA, pointB, pointC);
  
  // The angle at point B between vectors BA and BC is 135 degrees
  expect(angle, closeTo(135.0, 0.1));
});
  });

  group('Distance calculation tests', () {
    test('calculateDistance returns correct value', () {
      final pointA = [1.0, 2.0];
      final pointB = [4.0, 6.0];
      
      // Distance formula: sqrt((x2-x1)² + (y2-y1)²)
      // = sqrt((4-1)² + (6-2)²) = sqrt(9 + 16) = sqrt(25) = 5
      
      final distance = PoseUtils.calculateDistance(pointA, pointB);
      
      expect(distance, equals(5.0));
    });
    
    test('calculateDistance returns zero for same points', () {
      final pointA = [1.0, 2.0];
      final pointB = [1.0, 2.0];
      
      final distance = PoseUtils.calculateDistance(pointA, pointB);
      
      expect(distance, equals(0.0));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fitmate/screens/exercise_form/analyzers/squat_analyzer.dart';

class MockPose extends Mock implements Pose {}
class MockPoseLandmark extends Mock implements PoseLandmark {}

void main() {
  late SquatAnalyzer analyzer;
  
  setUp(() {
    analyzer = SquatAnalyzer();
  });
  
  test('initial state is correct', () {
    expect(analyzer.counter, equals(0));
    expect(analyzer.currentStage, equals("up"));
    expect(analyzer.footPlacement, equals("UNK"));
    expect(analyzer.kneePlacement, equals("UNK"));
    expect(analyzer.facingDirection, equals("UNK"));
  });
  
  group('facing direction detection', () {
    test('detects when user is facing the camera', () {
      //Create a mock pose
      final mockPose = MockPose();
      
      final mockNose = MockPoseLandmark();
      final mockLeftShoulder = MockPoseLandmark();
      final mockRightShoulder = MockPoseLandmark();
      
    
      when(() => mockNose.x).thenReturn(0.5);
      when(() => mockNose.y).thenReturn(0.3);
      when(() => mockNose.likelihood).thenReturn(0.9);
      
      when(() => mockLeftShoulder.x).thenReturn(0.4);
      when(() => mockLeftShoulder.y).thenReturn(0.4);
      when(() => mockLeftShoulder.likelihood).thenReturn(0.9);
      
      when(() => mockRightShoulder.x).thenReturn(0.6);
      when(() => mockRightShoulder.y).thenReturn(0.4);
      when(() => mockRightShoulder.likelihood).thenReturn(0.9);
      
      final landmarks = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.nose: mockNose,
        PoseLandmarkType.leftShoulder: mockLeftShoulder,
        PoseLandmarkType.rightShoulder: mockRightShoulder,
      };
      
      when(() => mockPose.landmarks).thenReturn(landmarks);
      
      analyzer.analyzePose(mockPose);
      
      expect(analyzer.facingDirection, equals("Facing Camera"));
    });

  });
}
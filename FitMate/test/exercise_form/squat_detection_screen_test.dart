import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camera/camera.dart';
import 'package:fitmate/screens/exercise_form/analyzers/squat_analyzer.dart';
import 'package:fitmate/services/voice_feedback_service.dart';

// Mock classes
class MockCameraController extends Mock implements CameraController {}
class MockSquatAnalyzer extends Mock implements SquatAnalyzer {}
class MockVoiceFeedbackService extends Mock implements VoiceFeedbackService {}


class TestableSquatDetectionScreen extends StatefulWidget {
  final CameraController cameraController;
  final SquatAnalyzer analyzer;
  final VoiceFeedbackService voiceFeedback;
  
  const TestableSquatDetectionScreen({
    Key? key,
    required this.cameraController,
    required this.analyzer,
    required this.voiceFeedback,
  }) : super(key: key);
  
  @override
  _TestableSquatDetectionScreenState createState() => _TestableSquatDetectionScreenState();
}

class _TestableSquatDetectionScreenState extends State<TestableSquatDetectionScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Status indicators
            if (widget.analyzer.kneePlacement != "UNK")
              Text('Knees: ${widget.analyzer.kneePlacement}'),
            if (widget.analyzer.footPlacement != "UNK")
              Text('Feet: ${widget.analyzer.footPlacement}'),
            if (widget.analyzer.facingDirection == "Sideways")
              Text('Please face the camera directly for proper squat analysis'),
          ],
        ),
      ),
    );
  }
}

void main() {
  late MockCameraController mockCameraController;
  late MockSquatAnalyzer mockAnalyzer;
  late MockVoiceFeedbackService mockVoiceFeedback;
  
  setUp(() {
    mockCameraController = MockCameraController();
    mockAnalyzer = MockSquatAnalyzer();
    mockVoiceFeedback = MockVoiceFeedbackService();
    
    // Setup common mock behaviors
    when(() => mockVoiceFeedback.initialize()).thenAnswer((_) async => null);
    when(() => mockVoiceFeedback.speak(any())).thenAnswer((_) async => null);
  });
  
  testWidgets('Shows warning when user is sideways', (WidgetTester tester) async {
    // Setup analyzer state
    when(() => mockAnalyzer.facingDirection).thenReturn("Sideways");
    when(() => mockAnalyzer.kneePlacement).thenReturn("Good");
    when(() => mockAnalyzer.footPlacement).thenReturn("Good");
    
    // Build widget
    await tester.pumpWidget(
      TestableSquatDetectionScreen(
        cameraController: mockCameraController,
        analyzer: mockAnalyzer,
        voiceFeedback: mockVoiceFeedback,
      ),
    );
    
    // Verify warning message is displayed
    expect(find.text('Please face the camera directly for proper squat analysis'), findsOneWidget);
  });
  
  testWidgets('Displays correct form status', (WidgetTester tester) async {
    // Setup analyzer state
    when(() => mockAnalyzer.facingDirection).thenReturn("Facing Camera");
    when(() => mockAnalyzer.kneePlacement).thenReturn("Good");
    when(() => mockAnalyzer.footPlacement).thenReturn("Too narrow");
    
    // Build widget
    await tester.pumpWidget(
      TestableSquatDetectionScreen(
        cameraController: mockCameraController,
        analyzer: mockAnalyzer,
        voiceFeedback: mockVoiceFeedback,
      ),
    );
    
    // Verify status indicators
    expect(find.text('Knees: Good'), findsOneWidget);
    expect(find.text('Feet: Too narrow'), findsOneWidget);
  });
}
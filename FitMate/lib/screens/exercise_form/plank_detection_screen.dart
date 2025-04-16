import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/services/voice_feedback_service.dart';
import 'analyzers/plank_analyzer.dart';
import 'widgets/exercise_ui_components.dart';
import 'package:fitmate/widgets/pose_painter.dart';
import 'package:flutter/services.dart';
import 'base_exercise_detection_screen.dart';

class PlankDetectionScreen extends BaseExerciseDetectionScreen {
  const PlankDetectionScreen({Key? key}) 
      : super(key: key, exerciseType: 'Plank');
 
  @override
  _PlankDetectionScreenState createState() => _PlankDetectionScreenState();
}

class _PlankDetectionScreenState extends State<PlankDetectionScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isProcessing = false;
  Pose? _currentPose;
  late PlankAnalyzer _analyzer;
  late VoiceFeedbackService voiceFeedback;
  String lastFormFeedback = '';

  
  // UI enhancement vars
  bool showCountdown = true;
  int countdownValue = 3;
  bool isRecording = false;
  
  // Animation controller for breathing guide
  late AnimationController _breathingController;
  
  @override
  void initState() {
    super.initState();
    _analyzer = PlankAnalyzer();
    _initializeDetector();
    _initializeCamera();
    voiceFeedback = VoiceFeedbackService();
    // Initialize voice feedback service
    _initializeServices();
    // Initialize breathing animation controller
    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat(reverse: true);
    
    // Start countdown
    _startCountdown();
  }

  Future<void> _initializeServices() async {
    try {
      await voiceFeedback.initialize();
      print("Voice feedback service initialized");
    } catch (e) {
      print("Error initializing voice feedback: $e");
    }
  }
  
void _startCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (countdownValue > 1) {
            countdownValue--;
            _startCountdown(); // Continue countdown recursively
          } else {
            // When we reach 1, set showCountdown to false
            showCountdown = false;
          }
        });
      }
    });
  }
  
  void _initializeDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    // Select front camera
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    // Initialize with lower resolution for better performance
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await _cameraController!.initialize();
      
      // Start image stream once camera is initialized
      _cameraController!.startImageStream(_processCameraImage);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      final camera = _cameraController!.description;
      
      final inputImage = _convertCameraImageToInputImage(image, camera);
      if (inputImage == null) return;
      
      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        final pose = poses.first;
        
        // Process the pose using the plank analyzer
        _analyzer.analyzePose(pose);

        // Get current feedback text
    String currentFeedback = _analyzer.getFormFeedback();
    
    // Check if feedback has changed
    if (currentFeedback != lastFormFeedback) {
      print("Feedback changed to: $currentFeedback");
      lastFormFeedback = currentFeedback;
      
      // Determine if this feedback should be spoken
      bool shouldSpeak = shouldSpeakFeedback(currentFeedback);
      
      if (shouldSpeak) {
        print("Speaking feedback: $currentFeedback");
        voiceFeedback.speak(currentFeedback);
      }
    }
        
        if (mounted) {
          setState(() {
            _currentPose = pose;
          });
        }
      }
    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      _isProcessing = false;
    }
  }

    // Determine which feedback messages should be spoken
  bool shouldSpeakFeedback(String feedback) {
    // List of important feedback phrases to speak out loud
    List<String> importantPhrases = [ 
      "Lower your hips","lift your hips"
    ];
    
    // Check if the feedback contains any of the important phrases
    for (String phrase in importantPhrases) {
      if (feedback.toLowerCase().contains(phrase.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }
  
  InputImage? _convertCameraImageToInputImage(CameraImage image, CameraDescription camera) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Create InputImage
      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: _getInputImageRotation(camera.sensorOrientation),
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      
      return InputImage.fromBytes(
        bytes: bytes, 
        metadata: inputImageData,
      );
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }
  
  InputImageRotation _getInputImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
  
  void _toggleRecording() {
    setState(() {
      isRecording = !isRecording;
      if (!isRecording) {
        // Reset plank timer
        _analyzer.resetDuration();
      }
    });
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
  }
    
  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    _breathingController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              ExerciseUIComponents.primaryColor
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.exerciseType} Form Analysis',
          style: GoogleFonts.bebasNeue(
            fontSize: 24,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Preview with proper aspect ratio
          Container(
            width: double.infinity,
            height: double.infinity,
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
          
        
          
          // Pose overlay when pose is detected
          if (_currentPose != null && !showCountdown)
            CustomPaint(
              painter: PosePainter(
                pose: _currentPose!,
                imageSize: Size(
                  _cameraController!.value.previewSize!.height,
                  _cameraController!.value.previewSize!.width,
                ),
                isFrontCamera: true,
               
              ),
              size: Size.infinite,
            ),
          
          // Countdown overlay
          if (showCountdown)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Ready!',
                      style: GoogleFonts.bebasNeue(
                        color: ExerciseUIComponents.primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: ExerciseUIComponents.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          countdownValue.toString(),
                          style: GoogleFonts.bebasNeue(
                            color: Colors.black,
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Position yourself in a side plank position',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
          if (!showCountdown) ...[
            // Top status bar with enhanced timer display
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ExerciseUIComponents.buildStatusRow(
                statusBoxes: [
                  // Animated timer display
                  ExerciseUIComponents.buildTimerDisplay(
                    seconds: _analyzer.currentDuration,
                  ),
                  
                  // Back position status with enhanced visuals
                  ExerciseUIComponents.buildStatusBox(
                    label: 'BACK',
                    value: _analyzer.backStatus,
                    color: ExerciseUIComponents.getStatusColor(_analyzer.backStatus),
                  ),
                ],
              ),
            ),
            
            // Bottom feedback with enhanced design
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Form feedback with icon
                  ExerciseUIComponents.buildFeedbackBox(
                    feedbackText: _analyzer.getFormFeedback(),
                  ),
                ],
              ),
            ),
          
           
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:fitmate/widgets/pose_painter.dart';

/// Base class for all exercise detection screens
abstract class BaseExerciseDetectionScreen extends StatefulWidget {
  final String exerciseType;
  
  const BaseExerciseDetectionScreen({
    Key? key,
    required this.exerciseType,
  }) : super(key: key);
}

/// Base state class that handles camera and pose detection
abstract class BaseExerciseDetectionState<T extends BaseExerciseDetectionScreen> extends State<T> {
  CameraController? cameraController;
  PoseDetector? poseDetector;
  bool isProcessing = false;
  Pose? currentPose;
  
  // Camera config
  CameraLensDirection preferredCameraLensDirection = CameraLensDirection.front;
  ResolutionPreset cameraResolution = ResolutionPreset.medium;
  
  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _initializeCamera();
  }
  
  void _initializeDetector() {
    poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );
  }
  
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    
    // Select preferred camera
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == preferredCameraLensDirection,
      orElse: () => cameras.first,
    );
    
    // Initialize with specified resolution for better performance
    cameraController = CameraController(
      camera,
      cameraResolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await cameraController!.initialize();
      
      // Start image stream once camera is initialized
      cameraController!.startImageStream(_processCameraImage);
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
    if (isProcessing) return;
    
    isProcessing = true;
    
    try {
      final camera = cameraController!.description;
      
      final inputImage = _convertCameraImageToInputImage(image, camera);
      if (inputImage == null) return;
      
      final poses = await poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        final pose = poses.first;
        
        // Process the pose using exercise-specific logic
        await processPose(pose);
        
        if (mounted) {
          setState(() {
            currentPose = pose;
          });
        }
      }
    } catch (e) {
      print('Error processing camera image: $e');
    } finally {
      isProcessing = false;
    }
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
  
  /// Abstract method to be implemented by specific exercise detectors
  Future<void> processPose(Pose pose);
  
  /// Standard build method with loading indicator
  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseType} Form Analysis'),
      ),
      body: buildExerciseUI(),
    );
  }
  
  /// Abstract method to be implemented by specific exercise UIs
  Widget buildExerciseUI();
  
  @override
  void dispose() {
    cameraController?.dispose();
    poseDetector?.close();
    super.dispose();
  }
}
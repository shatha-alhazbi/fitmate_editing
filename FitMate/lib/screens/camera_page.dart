import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  final Function(File imageFile)? onImageCaptured;
  
  const CameraPage({super.key, this.onImageCaptured});
  
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  XFile? capturedImage;
  
  // Adjust these values to match your model's input requirements
  static const int MODEL_INPUT_WIDTH = 224;  // Example: common model input size
  static const int MODEL_INPUT_HEIGHT = 224; // Change these to your actual model requirements
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  void _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }
  
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      
      // Capture image with dimensions that match model requirements
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: MODEL_INPUT_WIDTH.toDouble(),
        maxHeight: MODEL_INPUT_HEIGHT.toDouble(),
      );
      
      if (photo != null) {
        setState(() {
          capturedImage = photo;
        });
        
        // If we have a callback for handling the image, call it
        if (widget.onImageCaptured != null) {
          widget.onImageCaptured!(File(photo.path));
        }
        
        // Optional: Return to previous screen with the image
        Navigator.pop(context, photo);
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: Colors.grey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox(
              width: size.width,
              height: size.height,
              child: CameraPreview(_controller),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
        backgroundColor: Colors.grey,
      ),
    );
  }
}
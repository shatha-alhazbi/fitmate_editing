import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/services/food_recognition_services.dart';
import 'package:fitmate/services/food_logging_service.dart';
import 'package:fitmate/models/food.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodRecognitionScreen extends StatefulWidget {
  final File? imageFile;
  final Food? recognizedFood;

  const FoodRecognitionScreen({
    Key? key,
    this.imageFile,
    this.recognizedFood,
  }) : super(key: key);

  @override
  _FoodRecognitionScreenState createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  Food? _recognizedFood;
  double _portionSize = 1.0;
  String? _errorMessage;
  bool _cameraPermissionChecked = false;
  bool _cameraPermissionGranted = false;

  // Text controllers for form fields
  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _portionController = TextEditingController(text: "1");

  // Focus nodes
  final FocusNode _dishNameFocus = FocusNode();
  final FocusNode _portionFocus = FocusNode();
  final FocusNode _caloriesFocus = FocusNode();
  final FocusNode _fatFocus = FocusNode();
  final FocusNode _carbsFocus = FocusNode();
  final FocusNode _proteinFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _imageFile = widget.imageFile;
    _recognizedFood = widget.recognizedFood;
    _portionController.addListener(_onPortionChanged);
    
    // Start the camera automatically after checking permissions
    _initCameraAfterDelay();
  }
  
  @override
  void dispose() {
    _dishNameController.dispose();
    _caloriesController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _portionController.dispose();
    
    _dishNameFocus.dispose();
    _portionFocus.dispose();
    _caloriesFocus.dispose();
    _fatFocus.dispose();
    _carbsFocus.dispose();
    _proteinFocus.dispose();
    
    super.dispose();
  }

  void _onPortionChanged() {
    try {
      final newPortion = double.parse(_portionController.text);
      if (newPortion > 0) {
        setState(() {
          _portionSize = newPortion;
        });
        _updateNutritionValues();
      }
    } catch (e) {
      // Invalid input, ignore
      print("Error parsing portion size: $e");
    }
  }
  
  void _updateNutritionValues() {
    if (_recognizedFood == null) return;
    
    setState(() {
      _caloriesController.text = (_recognizedFood!.calories * _portionSize).toStringAsFixed(1);
      _proteinController.text = (_recognizedFood!.protein * _portionSize).toStringAsFixed(1);
      _carbsController.text = (_recognizedFood!.carbs * _portionSize).toStringAsFixed(1);
      _fatController.text = (_recognizedFood!.fats * _portionSize).toStringAsFixed(1);
    });
  }
  
  Future<void> _initCameraAfterDelay() async {
    // Short delay to allow the UI to build and permissions to be checked
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted && _cameraPermissionGranted && _imageFile == null && _recognizedFood == null) {
      _takePhoto();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraPermissionChecked = true;
      _cameraPermissionGranted = status.isGranted;
    });

    if (!status.isGranted && status.isDenied) {
      _showPermissionExplanationDialog();
    } else if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  Future<void> _takePhoto() async {
    if (!_cameraPermissionGranted) {
      await _requestCameraPermission();
      if (!_cameraPermissionGranted) return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo == null) {
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _imageFile = File(photo.path);
        _recognizedFood = null;
      });

      final result =
          await Provider.of<Food_recognition_service>(context, listen: false)
              .recognizeFood(_imageFile!);

      setState(() {
        _isProcessing = false;
        if (result['success']) {
          // Check if the result contains a confidence score
          if (result.containsKey('confidence') && result['confidence'] < 0.5) {
            // Low confidence - probably not food
            _errorMessage = "This doesn't appear to be food. Please try again or log manually.";
            _showRecognitionFailedDialog();
          } else {
            _recognizedFood = result['food'];
            
            // Set text controllers with recognized food data
            _dishNameController.text = _recognizedFood!.name;
            _caloriesController.text = _recognizedFood!.calories.toStringAsFixed(1);
            _fatController.text = _recognizedFood!.fats.toStringAsFixed(1);
            _carbsController.text = _recognizedFood!.carbs.toStringAsFixed(1);
            _proteinController.text = _recognizedFood!.protein.toStringAsFixed(1);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Identified: ${_recognizedFood!.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          _errorMessage = result['message'] ?? "Couldn't recognize the food. Please try again or log manually.";
          _showRecognitionFailedDialog();
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Error: ${e.toString()}";
      });
    }
  }

  Future<void> _logFood() async {
    if (_recognizedFood == null) return;

    setState(() => _isProcessing = true);

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in."), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Get values from text controllers
      final dishName = _dishNameController.text;
      final calories = double.tryParse(_caloriesController.text) ?? 0.0;
      final fat = double.tryParse(_fatController.text) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text) ?? 0.0;
      final protein = double.tryParse(_proteinController.text) ?? 0.0;

      // Prepare food data to save to Firebase
      Map<String, dynamic> foodData = {
        'dishName': dishName,
        'calories': calories,
        'fat': fat,
        'carbs': carbs,
        'protein': protein,
        'baseCalories': calories / _portionSize,
        'baseFat': fat / _portionSize,
        'baseCarbs': carbs / _portionSize,
        'baseProtein': protein / _portionSize,
        'portionSize': _portionSize,
        'date': DateTime.now(),
        'source': 'recognition',
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .add(foodData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to previous screen (NutritionScreen)
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log food: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'FOOD RECOGNITION',
          style: GoogleFonts.bebasNeue(
            color: Colors.black,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_recognizedFood != null)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _takePhoto,
              tooltip: 'Take New Photo',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_cameraPermissionChecked) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_cameraPermissionGranted) {
      return _buildPermissionRequestUI();
    }

    if (_isProcessing) {
      return _buildLoadingUI();
    }

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              
              // Header with instruction/status
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2EB50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD2EB50),
                    width: 1,
                  ),
                ),
                child: Text(
                  _recognizedFood != null 
                      ? 'Food identified! Adjust details if needed.'
                      : _imageFile != null 
                          ? 'Recognition failed. Try again or log manually.'
                          : 'Getting ready to capture food image...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Image preview
              if (_imageFile != null) 
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  ),
                ),
              
              if (_recognizedFood != null) ...[
                // Dish name
                TextField(
                  controller: _dishNameController,
                  focusNode: _dishNameFocus,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).requestFocus(_portionFocus),
                  decoration: InputDecoration(
                    labelText: 'Dish Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant_menu),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Portion size with better styling
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'PORTION SIZE',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 18,
                            letterSpacing: 1,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.restaurant, color: const Color(0xFFD2EB50)),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _portionController,
                              focusNode: _portionFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_caloriesFocus),
                              decoration: InputDecoration(
                                labelText: 'Number of portions',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: '1',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (_portionSize > 0.25) {
                                      _portionController.text = (_portionSize - 0.25).toStringAsFixed(2);
                                    }
                                  },
                                  color: const Color(0xFFD2EB50),
                                ),
                                Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    _portionSize.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    _portionController.text = (_portionSize + 0.25).toStringAsFixed(2);
                                  },
                                  color: const Color(0xFFD2EB50),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Nutrition information section with icons
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'NUTRITION INFO',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 18,
                            letterSpacing: 1,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _caloriesController,
                              focusNode: _caloriesFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_fatFocus),
                              decoration: InputDecoration(
                                labelText: 'Calories',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.egg_outlined, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _fatController,
                              focusNode: _fatFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_carbsFocus),
                              decoration: InputDecoration(
                                labelText: 'Fat (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.grain, color: Colors.brown[300]),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _carbsController,
                              focusNode: _carbsFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_proteinFocus),
                              decoration: InputDecoration(
                                labelText: 'Carbohydrates (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: Colors.red[300]),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _proteinController,
                              focusNode: _proteinFocus,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                // close keyboard after the last field
                                FocusScope.of(context).unfocus();
                              },
                              decoration: InputDecoration(
                                labelText: 'Protein (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Log Food button
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _logFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2EB50),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'LOG FOOD',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24, 
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                
                // Action buttons row
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Retake Photo button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _takePhoto,
                          icon: Icon(Icons.camera_alt, color: Colors.black54),
                          label: Text(
                            'Retake Photo',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ),
                      
                      // Divider
                      Container(
                        height: 20,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      
                      // Log Manually button
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            // Navigate to manual food logging
                            Navigator.pushReplacementNamed(context, '/manual_food_log');
                          },
                          icon: Icon(Icons.edit, color: Colors.black54),
                          label: Text(
                            'Log Manually',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // If no food recognized yet but we have an image, show action buttons
              if (_imageFile != null && _recognizedFood == null && !_isProcessing)
                Column(
                  children: [
                    // Retry button
                    Container(
                      margin: EdgeInsets.only(top: 20, bottom: 10),
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: Icon(Icons.camera_alt),
                        label: Text(
                          'RETAKE PHOTO',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22, 
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    
                    // Log manually button
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/manual_food_log');
                        },
                        icon: Icon(Icons.edit_note),
                        label: Text(
                          'LOG FOOD MANUALLY',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 22, 
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BC34A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    String loadingText = 'Opening camera...';
    
    if (_isProcessing) {
      if (_imageFile != null) {
        // If we're saving to Firebase
        if (_recognizedFood != null) {
          loadingText = 'Saving food data...';
        } else {
          loadingText = 'Analyzing your food...';
        }
      }
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFD2EB50)),
          ),
          const SizedBox(height: 20),
          Text(
            loadingText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequestUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Color(0xFFD2EB50)),
            const SizedBox(height: 20),
            Text(
              'Camera Permission Required',
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                letterSpacing: 1,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'FitMate needs camera access to identify food items',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2EB50),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() => _cameraPermissionGranted = status.isGranted);
    
    if (status.isGranted && mounted) {
      // Open camera immediately after permission is granted
      _takePhoto();
    } else if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  void _showRecognitionFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recognition Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_errorMessage ?? 'We couldn\'t identify the food.'),
            SizedBox(height: 16),
            Text(
              'Would you like to try again or log manually?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _takePhoto();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/manual_food_log');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2EB50),
            ),
            child: const Text('Log Manually'),
          ),
        ],
      ),
    );
  }

  void _showPermissionExplanationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'FitMate needs camera access to identify food items. Please grant permission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please enable camera access in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
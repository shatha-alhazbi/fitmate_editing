import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/screens/exercise_form/bicep_curl_detection_screen.dart';
import 'package:fitmate/screens/exercise_form/squat_detection_screen.dart';
import 'package:fitmate/screens/exercise_form/plank_detection_screen.dart';

class FormInstructionsPage extends StatefulWidget {
  final String title;
  final String image;

  const FormInstructionsPage({Key? key, required this.title, required this.image}) : super(key: key);

  @override
  _FormInstructionsPageState createState() => _FormInstructionsPageState();
}

class _FormInstructionsPageState extends State<FormInstructionsPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late TabController _tabController;
  final Color primaryColor = const Color(0xFFD2EB50);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Get instructions based on exercise type
  Map<String, String> _getInstructions() {
    switch (widget.title.toLowerCase()) {
      case 'squat':
        return {
          'instructions': '1. Stand straight with feet hip-width apart.\n'
                  '2. Engage your core muscles.\n'
                  '3. Lower down, as if sitting in an invisible chair.\n'
                  '4. Lift back up to standing position.',
          'tips': 'Keep your knees aligned with your toes. Maintain a neutral spine position.',
          'common_errors': 'Knees caving inward, heels lifting off ground, rounded back, not going deep enough.',
          'camera_position': 'Face the camera directly. Make sure your entire body from head to feet is visible in the frame.'
        };
      case 'plank':
        return {
          'instructions': '1. Start in a forearm plank position with elbows directly under shoulders.\n'
                  '2. Keep your body in a straight line from head to heels.\n'
                  '3. Engage your core and glutes to maintain stability.\n'
                  '4. Hold the position for the desired duration.',
          'tips': 'Breathe steadily. Avoid letting your hips sag or pike up. Keep your gaze slightly forward, not down.',
          'common_errors': 'Sagging hips, elevated hips, neck strain, holding breath, misaligned shoulders.',
          'camera_position': 'Position your device to capture a side view of your body. Make sure your entire body from head to feet is visible in the frame.'
        };
      case 'lunge':
        return {
          'instructions': '1. Stand straight with feet hip-width apart.\n'
                  '2. Step forward with one leg and lower your body.\n'
                  '3. Both knees should form 90° angles at the bottom.\n'
                  '4. Push back up and return to starting position.',
          'tips': 'Keep your torso upright. Make sure your front knee doesn\'t extend past your toes.',
          'benefits': 'Targets quads, hamstrings, glutes, and calves. Improves balance and stability.',
          'common_errors': 'Front knee extending past toes, torso leaning too far forward, back heel raising.',
          'camera_position': 'Position yourself at a 45-degree angle to the camera so both your side profile and front can be seen.'
        };
      case 'bicep curl':
        return {
          'instructions': '1. Stand with feet shoulder-width apart, holding weights at your sides.\n'
                  '2. Keep elbows close to your body.\n'
                  '3. Curl the weights up toward your shoulders.\n'
                  '4. Lower back down with control.',
          'tips': 'Maintain straight wrists. Keep your upper arms stationary throughout the movement.',
          'common_errors': 'Swinging the body, moving elbows away from torso, incomplete range of motion.',
          'camera_position': 'Stand sideways to the camera. Keep your elbow and full arm visible throughout the exercise.'
        };
      default:
        return {
          'instructions': '1. Follow proper form for this exercise.\n'
                  '2. Maintain correct posture throughout.\n'
                  '3. Focus on controlled movement.\n'
                  '4. Complete the required repetitions.',
          'tips': 'Start with lighter weights if needed. Prioritize form over speed or weight.',
          'benefits': 'Improves strength, mobility and overall fitness.',
          'common_errors': 'Poor form, rushing through repetitions, using too much weight.',
          'camera_position': 'Position yourself so your full body is visible to the camera for proper form detection.'
        };
    }
  }

  // Determine the appropriate camera detection screen to navigate to
  Widget _getDetectionScreen() {
    switch (widget.title.toLowerCase()) {
      case 'squat':
        return SquatDetectionScreen();
      case 'bicep curl':
        return BicepCurlDetectionScreen();
      case 'plank':
        return PlankDetectionScreen();
      default:
        return SquatDetectionScreen();
    }
  }
  
  // Determine if form detection is available for this exercise
  bool _isDetectionAvailable() {
    // List of exercises that have form detection implemented
    final List<String> availableExercises = ['squat','bicep curl','plank'];
    return availableExercises.contains(widget.title.toLowerCase());
  }
  
  // Show camera position instruction dialog
  void _showCameraPositionDialog() {
    final instructions = _getInstructions();
    final cameraPositionText = instructions['camera_position'] ?? 
        'Position yourself so your full body is visible to the camera for proper form detection.';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: primaryColor,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Camera Positioning',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: Colors.black87,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
  
              // Instructions text
              Text(
                cameraPositionText,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'CANCEL',
                style: GoogleFonts.dmSans(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to exercise screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _getDetectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK, I\'M READY',
                style: GoogleFonts.dmSans(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Get appropriate icon for camera positioning based on exercise
  IconData _getCameraPositionIcon() {
    switch (widget.title.toLowerCase()) {
      case 'squat':
        return Icons.person_pin_circle; // Front view
      case 'plank':
        return Icons.person; // Side view
      case 'bicep curl':
        return Icons.accessibility_new; // Side view for arm
      default:
        return Icons.camera_front; // Generic camera icon
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final instructions = _getInstructions();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.bebasNeue(
            color: Colors.black,
            fontSize: 24,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Large image below app bar
          Container(
            width: double.infinity,
            height: 200, // Larger height for the image
            decoration: BoxDecoration(
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              widget.image,
              fit: BoxFit.contain,
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: primaryColor,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: "INSTRUCTIONS"),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Instructions Tab
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('How to do it'),
                        _buildInstructionSteps(instructions['instructions'] ?? ''),
                        
                        const SizedBox(height: 20),
                        _buildSectionTitle('Tips'),
                        _buildTipBox(instructions['tips'] ?? ''),
                        
                        const SizedBox(height: 20),
                        _buildSectionTitle('Common Errors'),
                        _buildErrorsList(instructions['common_errors'] ?? ''),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Start button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: _isDetectionAvailable() ? () {
                // Show camera position dialog instead of navigating directly
                _showCameraPositionDialog();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDetectionAvailable() ? primaryColor : Colors.grey,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 4,
              ),
              child: Text(
                _isDetectionAvailable() ? 'START FORM CHECK' : 'FORM DETECTION COMING SOON',
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.black87,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
  
  // UI Components for the instructions page
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
  
  Widget _buildInstructionSteps(String instructions) {
    final steps = instructions.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            step,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildTipBox(String tips) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primaryColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: primaryColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tips,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorsList(String errors) {
    final errorList = errors.split('. ');
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errorList.map((error) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
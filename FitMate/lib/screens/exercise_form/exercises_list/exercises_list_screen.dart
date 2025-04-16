import 'package:fitmate/screens/exercise_form/exercises_list/exercise_instructions_screen.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormListPage extends StatefulWidget {
  @override
  _FormListPageState createState() => _FormListPageState();
}

class _FormListPageState extends State<FormListPage> {
  final List<Map<String, dynamic>> workouts = [
    {
      "title": "Squat", 
      "image": "assets/data/images/workouts/image 2.png",
      "image2": "assets/data/images/workouts/image 22.png",
      "target": "Legs, Glutes",
      "available": true
    },
    {
      "title": "Plank", 
      "image": "assets/data/images/workouts/image 4.png",
      "image2": "assets/data/images/workouts/image 4.png",
      "target": "Core, Arms",
      "available": true
    },
    {
      "title": "Lunge", 
      "image": "assets/data/images/workouts/image 3.png",
      "image2": "assets/data/images/workouts/image 33.png",
      "target": "Legs, Glutes",
      "available": false
    },
    {
      "title": "Bicep Curl", 
      "image": "assets/data/images/workouts/image 5.png",
      "image2": "assets/data/images/workouts/image 55.png",
      "target": "Arms",
      "available": true
    },
  ];

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          'Form Check',
          style: GoogleFonts.bebasNeue(
            color: Colors.black,
            fontSize: 28,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated intro section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 249, 255, 218).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Select an exercise below to analyze your form using AI-powered feedback',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          // Exercises grid/list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return GestureDetector(
                    onTap: () {
                      if (workout["available"] == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormInstructionsPage(
                              title: workout["title"]!,
                              image: workout["image2"]!,
                            ),
                          ),
                        );
                      } else {
                        // Show coming soon message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Form detection for ${workout["title"]} coming soon!',
                              style: GoogleFonts.dmSans(),
                            ),
                            backgroundColor: Colors.black87,
                          ),
                        );
                      }
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              const Color(0xFFD2EB50).withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Status badge (Coming Soon or Available)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: workout["available"] 
                                      ? const Color(0xFFD2EB50) 
                                      : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  workout["available"] ? 'Available' : 'Coming Soon',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Exercise image
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Image.asset(
                                  workout["image"]!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            
                            // Exercise details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    workout["title"]!,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  
                    
                                  // Target muscles
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.fitness_center, // Replaced Icons.target with Icons.fitness_center
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        workout["target"],
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
}


import 'package:flutter/material.dart';

class SimpleInstructionsPage extends StatelessWidget {
  final String title;
  final String image;
  
  const SimpleInstructionsPage({required this.title, required this.image});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 100),
            Text(title, style: TextStyle(fontSize: 24)),
            Text("Simple instructions page for debugging"),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:fitmate/models/food.dart';

class Food_recognition_service with ChangeNotifier {
  final String _serverUrl = 'https://tunnel.fitnessmates.net'; // Your backend URL
  
  // Confidence threshold - adjust this value based on testing
  final double _confidenceThreshold = 0.6; // Requiring 60% confidence

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/recognize_food/'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> result = jsonDecode(responseData);

        if (result.containsKey('error')) {
          return {'success': false, 'message': result['error']};
        }

        // Get confidence score from the response
        final double confidence = result.containsKey('confidence') 
            ? (result['confidence'] is double 
                ? result['confidence'] 
                : double.tryParse(result['confidence'].toString()) ?? 0.0)
            : 0.0;
            
        // Include confidence in the return value regardless of threshold check
        if (confidence < _confidenceThreshold) {
          // Low confidence - probably not food
          return {
            'success': false,
            'confidence': confidence,
            'message': 'Food not recognized'
          };
        }

        final foodName = result['food_name'];
        final nutritionalInfo = result['nutritional_info'];

        final recognizedFood = Food(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: foodName.replaceAll('_', ' ').toUpperCase(),
          calories: nutritionalInfo['Calories'] is int
              ? nutritionalInfo['Calories']
              : 0,
          protein: nutritionalInfo['Protein'] is num
              ? nutritionalInfo['Protein'].toDouble()
              : 0.0,
          carbs: nutritionalInfo['Carbs'] is num
              ? nutritionalInfo['Carbs'].toDouble()
              : 0.0,
          fats: nutritionalInfo['Fats'] is num
              ? nutritionalInfo['Fats'].toDouble()
              : 0.0,
        );

        return {
          'success': true,
          'food': recognizedFood,
          'confidence': confidence,
          'message': 'Food recognized successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error processing image: ${e.toString()}'
      };
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/models/food.dart';
import 'package:flutter/material.dart';

class FoodLoggingService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logFood(Food food) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final date = DateTime.now();
      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Create food data with all required fields
      final foodData = food.toJson()
        ..addAll({
          'timestamp': FieldValue.serverTimestamp(),
          'loggedAt': DateTime.now().toIso8601String(),
        });

      // Add to user's food log
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('foodLog')
          .doc(formattedDate)
          .collection('items')
          .add(foodData);

      // Update daily totals
      await _updateDailyNutritionTotals(user.uid, formattedDate, food);
    } catch (e) {
      debugPrint('Error logging food: $e');
      rethrow;
    }
  }

  Future<void> _updateDailyNutritionTotals(
      String userId, String date, Food food) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyNutrition')
          .doc(date);

      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          transaction.update(docRef, {
            'totalCalories': (data['totalCalories'] ?? 0) + food.calories,
            'totalProtein': (data['totalProtein'] ?? 0) + food.protein,
            'totalCarbs': (data['totalCarbs'] ?? 0) + food.carbs,
            'totalFat': (data['totalFat'] ?? 0) + food.fats,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'totalCalories': food.calories,
            'totalProtein': food.protein,
            'totalCarbs': food.carbs,
            'totalFat': food.fats,
            'date': date,
            'userId': userId,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating daily nutrition totals: $e');
      rethrow;
    }
  }

  Future<List<Food>> getDailyFoodLog(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('foodLog')
          .doc(formattedDate)
          .collection('items')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Food.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('Error getting daily food log: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDailyNutritionSummary(DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyNutrition')
          .doc(formattedDate)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      } else {
        return {
          'date': formattedDate,
          'totalCalories': 0,
          'totalProtein': 0,
          'totalCarbs': 0,
          'totalFat': 0
        };
      }
    } catch (e) {
      debugPrint('Error getting daily nutrition summary: $e');
      return {
        'error': 'Failed to load nutrition data',
        'totalCalories': 0,
        'totalProtein': 0,
        'totalCarbs': 0,
        'totalFat': 0
      };
    }
  }

  Future<bool> deleteLoggedFood(String foodId, DateTime date) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get food data before deleting
      final foodDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('foodLog')
          .doc(formattedDate)
          .collection('items')
          .doc(foodId)
          .get();

      if (!foodDoc.exists) return false;

      final food = Food.fromJson({...foodDoc.data()!, 'id': foodId});

      // Delete the food document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('foodLog')
          .doc(formattedDate)
          .collection('items')
          .doc(foodId)
          .delete();

      // Update daily totals
      await _subtractFromDailyNutritionTotals(user.uid, formattedDate, food);

      return true;
    } catch (e) {
      debugPrint('Error deleting logged food: $e');
      return false;
    }
  }

  Future<void> _subtractFromDailyNutritionTotals(
      String userId, String date, Food food) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyNutrition')
          .doc(date);

      return _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          transaction.update(docRef, {
            'totalCalories': (data['totalCalories'] ?? 0) - food.calories,
            'totalProtein': (data['totalProtein'] ?? 0) - food.protein,
            'totalCarbs': (data['totalCarbs'] ?? 0) - food.carbs,
            'totalFat': (data['totalFat'] ?? 0) - food.fats,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating daily nutrition totals after deletion: $e');
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  String? imageUrl;
  DateTime? timestamp;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.imageUrl,
    this.timestamp,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown Food',
      calories: (json['calories'] is int) ? json['calories'] : 0,
      protein: (json['protein'] is num) ? json['protein'].toDouble() : 0.0,
      carbs: (json['carbs'] is num) ? json['carbs'].toDouble() : 0.0,
      fats: (json['fats'] is num) ? json['fats'].toDouble() : 0.0,
      imageUrl: json['imageUrl'],
      timestamp: json['timestamp']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'imageUrl': imageUrl,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
    };
  }

  Food copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fats,
    String? imageUrl,
    DateTime? timestamp,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

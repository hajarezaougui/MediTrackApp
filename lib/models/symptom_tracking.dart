import 'package:flutter/material.dart';

class SymptomTracking {
  final int? id;
  final DateTime date;
  final double? temperature;
  final int? painLevel; // 1-10
  final String? bloodPressureSystolic;
  final String? bloodPressureDiastolic;
  final String? bloodSugar;
  final String? mood; // 'Très bien', 'Bien', 'Neutre', 'Mal', 'Très mal'
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SymptomTracking({
    this.id,
    required this.date,
    this.temperature,
    this.painLevel,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.bloodSugar,
    this.mood,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'painLevel': painLevel,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'bloodSugar': bloodSugar,
      'mood': mood,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SymptomTracking.fromMap(Map<String, dynamic> map) {
    return SymptomTracking(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()),
      date: DateTime.parse(map['date']),
      temperature: map['temperature'] != null
          ? (map['temperature'] is double
              ? map['temperature']
              : double.tryParse(map['temperature'].toString()))
          : null,
      painLevel: map['painLevel'] is int
          ? map['painLevel']
          : int.tryParse(map['painLevel']?.toString() ?? ''),
      bloodPressureSystolic: map['bloodPressureSystolic'],
      bloodPressureDiastolic: map['bloodPressureDiastolic'],
      bloodSugar: map['bloodSugar'],
      mood: map['mood'],
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Couleur selon le niveau de douleur
  static Color getPainColor(int? level) {
    if (level == null) return Colors.grey;
    if (level <= 3) return Color(0xFF5CB85C); // Vert
    if (level <= 6) return Color(0xFFF0AD4E); // Orange
    return Color(0xFFD9534F); // Rouge
  }

  // Icône selon l'humeur
  static IconData getMoodIcon(String? mood) {
    switch (mood) {
      case 'Très bien':
        return Icons.sentiment_very_satisfied;
      case 'Bien':
        return Icons.sentiment_satisfied;
      case 'Neutre':
        return Icons.sentiment_neutral;
      case 'Mal':
        return Icons.sentiment_dissatisfied;
      case 'Très mal':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  // Couleur selon l'humeur
  static Color getMoodColor(String? mood) {
    switch (mood) {
      case 'Très bien':
        return Color(0xFF5CB85C);
      case 'Bien':
        return Color(0xFF7ED321);
      case 'Neutre':
        return Color(0xFFF0AD4E);
      case 'Mal':
        return Color(0xFFED7D31);
      case 'Très mal':
        return Color(0xFFD9534F);
      default:
        return Color(0xFF7F8C8D);
    }
  }

  // Tension artérielle formatée
  String get formattedBloodPressure {
    if (bloodPressureSystolic == null || bloodPressureDiastolic == null) {
      return 'Non mesurée';
    }
    return '$bloodPressureSystolic/$bloodPressureDiastolic mmHg';
  }

  // Glycémie formatée
  String get formattedBloodSugar {
    if (bloodSugar == null) return 'Non mesurée';
    return '$bloodSugar mg/dL';
  }

  // Température formatée
  String get formattedTemperature {
    if (temperature == null) return 'Non mesurée';
    return '${temperature!.toStringAsFixed(1)}°C';
  }
}

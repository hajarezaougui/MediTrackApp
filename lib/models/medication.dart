import 'package:flutter/material.dart';

class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String form; // comprimé, liquide, injection, crème
  final String frequency; // Quotidien, Hebdomadaire, Personnalisé
  final String times; // JSON array d'horaires
  final String duration; // Durée du traitement
  final String notes;
  final bool remindersEnabled;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.form,
    required this.frequency,
    required this.times,
    required this.duration,
    required this.notes,
    required this.remindersEnabled,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'form': form,
      'frequency': frequency,
      'times': times,
      'duration': duration,
      'notes': notes,
      'remindersEnabled': remindersEnabled ? 1 : 0,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      form: map['form'],
      frequency: map['frequency'],
      times: map['times'],
      duration: map['duration'],
      notes: map['notes'],
      remindersEnabled: map['remindersEnabled'] == 1,
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Couleur en fonction de la forme
  Color get color {
    switch (form.toLowerCase()) {
      case 'comprimé':
      case 'comprime':
        return const Color(0xFF4A90E2);
      case 'liquide':
        return const Color(0xFF5CB85C);
      case 'injection':
        return const Color(0xFFF0AD4E);
      case 'crème':
      case 'creme':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF4A90E2);
    }
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? form,
    String? frequency,
    String? times,
    String? duration,
    String? notes,
    bool? remindersEnabled,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

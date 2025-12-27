import 'package:flutter/material.dart';

class MedicalDocument {
  final int? id;
  final String title;
  final String type; // 'analyse', 'ordonnance', 'radio', 'compte_rendu', 'autre'
  final String filePath;
  final String? doctorName;
  final DateTime documentDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalDocument({
    this.id,
    required this.title,
    required this.type,
    required this.filePath,
    this.doctorName,
    required this.documentDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'filePath': filePath,
      'doctorName': doctorName,
      'documentDate': documentDate.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicalDocument.fromMap(Map<String, dynamic> map) {
    return MedicalDocument(
      id: map['id'],
      title: map['title'],
      type: map['type'],
      filePath: map['filePath'],
      doctorName: map['doctorName'],
      documentDate: DateTime.parse(map['documentDate']),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Icône selon le type
  IconData get icon {
    switch (type) {
      case 'analyse':
        return Icons.science;
      case 'ordonnance':
        return Icons.description;
      case 'radio':
        return Icons.broken_image;
      case 'compte_rendu':
        return Icons.assignment;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Couleur selon le type
  Color get color {
    switch (type) {
      case 'analyse':
        return Color(0xFF5BC0DE);
      case 'ordonnance':
        return Color(0xFF4A90E2);
      case 'radio':
        return Color(0xFFF0AD4E);
      case 'compte_rendu':
        return Color(0xFF5CB85C);
      default:
        return Color(0xFF7F8C8D);
    }
  }

  // Extension du fichier
  String get fileExtension {
    return filePath.split('.').last.toLowerCase();
  }

  // Est-ce un fichier image?
  bool get isImage {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension);
  }

  // Est-ce un PDF?
  bool get isPdf {
    return fileExtension == 'pdf';
  }
}

// Extension pour le type d'icônes
extension on MedicalDocument {
  static const IconData insert_drive_file = IconData(0xe24d, fontFamily: 'MaterialIcons');
}

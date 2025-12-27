class MedicalRecord {
  final int? id;
  final String age;
  final String height;
  final String weight;
  final String allergies;
  final String chronicDiseases;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicalRecord({
    this.id,
    required this.age,
    required this.height,
    required this.weight,
    required this.allergies,
    required this.chronicDiseases,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'age': age,
      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'],
      age: map['age'],
      height: map['height'],
      weight: map['weight'],
      allergies: map['allergies'],
      chronicDiseases: map['chronicDiseases'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  MedicalRecord copyWith({
    int? id,
    String? age,
    String? height,
    String? weight,
    String? allergies,
    String? chronicDiseases,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      allergies: allergies ?? this.allergies,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

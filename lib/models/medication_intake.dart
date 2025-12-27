class MedicationIntake {
  final int? id;
  final int medicationId;
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final String status; // 'taken', 'missed', 'delayed'
  final DateTime date;
  final DateTime createdAt;

  MedicationIntake({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actualTime': actualTime?.toIso8601String(),
      'status': status,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MedicationIntake.fromMap(Map<String, dynamic> map) {
    return MedicationIntake(
      id: map['id'],
      medicationId: map['medicationId'],
      scheduledTime: DateTime.parse(map['scheduledTime']),
      actualTime: map['actualTime'] != null ? DateTime.parse(map['actualTime']) : null,
      status: map['status'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Vérifier si la prise est en retard
  bool get isDelayed {
    if (status == 'missed') return true;
    if (actualTime == null) return false;
    return actualTime!.isAfter(scheduledTime.add(const Duration(minutes: 15)));
  }

  // Calculer le retard en minutes
  int get delayInMinutes {
    if (actualTime == null) return 0;
    return actualTime!.difference(scheduledTime).inMinutes;
  }
}

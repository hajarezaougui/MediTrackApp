import 'package:flutter/material.dart';
import 'package:test_app/models/medication.dart';
import 'package:test_app/models/medication_intake.dart';
import 'package:test_app/services/database_service.dart';


class NextMedicationCard extends StatefulWidget {
  final MedicationIntake medicationIntake;
  final VoidCallback onMedicationTaken;

  const NextMedicationCard({
    super.key,
    required this.medicationIntake,
    required this.onMedicationTaken,
  });

  @override
  State<NextMedicationCard> createState() => _NextMedicationCardState();
}

class _NextMedicationCardState extends State<NextMedicationCard> {
  late Future<Medication?> _medicationFuture;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  void _loadMedication() {
    _medicationFuture = DatabaseService.instance.getMedicationById(
      widget.medicationIntake.medicationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Medication?>(
      future: _medicationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final medication = snapshot.data;
        if (medication == null) {
          return const SizedBox();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: medication.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getMedicationIcon(medication.form),
                          color: medication.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prochain médicament',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            Text(
                              medication.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              medication.dosage,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      
                      // Heure
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(widget.medicationIntake.scheduledTime),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _markAsMissed(),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Ignorer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markAsTaken(),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Pris'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _markAsTaken() async {
    final updatedIntake = MedicationIntake(
      id: widget.medicationIntake.id,
      medicationId: widget.medicationIntake.medicationId,
      scheduledTime: widget.medicationIntake.scheduledTime,
      actualTime: DateTime.now(),
      status: 'taken',
      date: widget.medicationIntake.date,
      createdAt: widget.medicationIntake.createdAt,
    );

    await DatabaseService.instance.updateMedicationIntake(updatedIntake);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Médicament marqué comme pris')),
    );
    
    widget.onMedicationTaken();
  }

  void _markAsMissed() async {
    final updatedIntake = MedicationIntake(
      id: widget.medicationIntake.id,
      medicationId: widget.medicationIntake.medicationId,
      scheduledTime: widget.medicationIntake.scheduledTime,
      actualTime: null,
      status: 'missed',
      date: widget.medicationIntake.date,
      createdAt: widget.medicationIntake.createdAt,
    );

    await DatabaseService.instance.updateMedicationIntake(updatedIntake);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rappel ignoré')),
    );
    
    widget.onMedicationTaken();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getMedicationIcon(String form) {
    switch (form.toLowerCase()) {
      case 'comprimé':
      case 'comprime':
        return Icons.medication;
      case 'liquide':
        return Icons.water_drop;
      case 'injection':
        return Icons.vaccines;
      case 'crème':
      case 'creme':
        return Icons.healing;
      case 'gelule':
        return Icons.circle;
      case 'sirop':
        return Icons.local_drink;
      case 'pommade':
        return Icons.clean_hands;
      default:
        return Icons.medical_services;
    }
  }
}

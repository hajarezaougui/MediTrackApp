import 'package:flutter/material.dart';
import 'package:test_app/models/medication.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;
  final VoidCallback onToggleReminder;
  final VoidCallback onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.onTap,
    required this.onToggleReminder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  // Icône du médicament
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: medication.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMedicationIcon(medication.form),
                      color: medication.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nom et dosage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          medication.dosage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Indicateur de rappel
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: medication.remindersEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          medication.remindersEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          size: 16,
                          color: medication.remindersEnabled
                              ? Colors.green
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          medication.remindersEnabled ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            color: medication.remindersEnabled
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Fréquence et forme
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medication.frequency,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medication.form,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Horaires
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimes(medication.times),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Durée
              if (medication.duration.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      medication.duration,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              
              // Actions rapides
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bouton Rappels
                  IconButton(
                    icon: Icon(
                      medication.remindersEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: medication.remindersEnabled
                          ? Colors.green
                          : Colors.grey,
                    ),
                    onPressed: onToggleReminder,
                    tooltip: medication.remindersEnabled
                        ? 'Désactiver les rappels'
                        : 'Activer les rappels',
                  ),
                  
                  // Bouton Supprimer
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatTimes(String times) {
    try {
      // Format: "['08:00', '12:00', '20:00']"
      return times
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll("'", '')
          .replaceAll(',', ', ');
    } catch (e) {
      return times;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:test_app/models/medication.dart';
import 'package:test_app/services/database_service.dart';
import 'package:test_app/services/notification_service.dart';
import 'package:test_app/views/screens/add_medication_screen.dart';
import 'package:test_app/views/widgets/medication_card.dart';


class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  late Future<List<Medication>> _medicationsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  void _loadMedications() {
    setState(() {
      _medicationsFuture = DatabaseService.instance.getAllMedications();
    });
  }

  List<Medication> _filterMedications(List<Medication> medications) {
    if (_searchQuery.isEmpty) return medications;
    
    return medications.where((medication) {
      return medication.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             medication.dosage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médicaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _MedicationSearchDelegate(
                  onSearch: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Medication>>(
        future: _medicationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }
          
          final medications = _filterMedications(snapshot.data ?? []);
          
          if (medications.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MedicationCard(
                  medication: medication,
                  onTap: () => _showMedicationDetails(medication),
                  onToggleReminder: () => _toggleReminder(medication),
                  onDelete: () => _deleteMedication(medication),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun médicament',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre premier médicament pour commencer',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addMedication,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un médicament'),
            ),
          ],
        ),
      ),
    );
  }

  void _addMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicationScreen(),
      ),
    );
    
    if (result == true) {
      _loadMedications();
    }
  }

  void _showMedicationDetails(Medication medication) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: medication.color.withOpacity(0.1),
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
                                medication.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                medication.dosage,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Détails
                    _DetailItem(
                      icon: Icons.category,
                      label: 'Forme',
                      value: medication.form,
                    ),
                    const SizedBox(height: 16),
                    _DetailItem(
                      icon: Icons.repeat,
                      label: 'Fréquence',
                      value: medication.frequency,
                    ),
                    const SizedBox(height: 16),
                    _DetailItem(
                      icon: Icons.schedule,
                      label: 'Horaires',
                      value: _formatTimes(medication.times),
                    ),
                    const SizedBox(height: 16),
                    _DetailItem(
                      icon: Icons.calendar_today,
                      label: 'Durée',
                      value: medication.duration,
                    ),
                    const SizedBox(height: 16),
                    _DetailItem(
                      icon: Icons.notifications,
                      label: 'Rappels',
                      value: medication.remindersEnabled ? 'Activés' : 'Désactivés',
                    ),
                    if (medication.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DetailItem(
                        icon: Icons.note,
                        label: 'Notes',
                        value: medication.notes,
                      ),
                    ],
                    const SizedBox(height: 24),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editMedication(medication);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleReminder(medication);
                            },
                            icon: Icon(
                              medication.remindersEnabled
                                  ? Icons.notifications_off
                                  : Icons.notifications,
                            ),
                            label: Text(
                              medication.remindersEnabled
                                  ? 'Désactiver rappels'
                                  : 'Activer rappels',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleReminder(Medication medication) async {
    final updatedMedication = Medication(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      form: medication.form,
      frequency: medication.frequency,
      times: medication.times,
      duration: medication.duration,
      notes: medication.notes,
      remindersEnabled: !medication.remindersEnabled,
      startDate: medication.startDate,
      endDate: medication.endDate,
      createdAt: medication.createdAt,
      updatedAt: DateTime.now(),
    );

    await DatabaseService.instance.updateMedication(updatedMedication);
    
    if (updatedMedication.remindersEnabled) {
      await NotificationService.instance.scheduleMedicationReminders(updatedMedication);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rappels activés')),
      );
    } else {
      await NotificationService.instance.cancelMedicationReminders(updatedMedication.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rappels désactivés')),
      );
    }
    
    _loadMedications();
  }

  void _deleteMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le médicament'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${medication.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteMedication(medication.id!);
      await NotificationService.instance.cancelMedicationReminders(medication.id!);
      _loadMedications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Médicament supprimé')),
      );
    }
  }

  void _editMedication(Medication medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(medication: medication),
      ),
    );
    
    if (result == true) {
      _loadMedications();
    }
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
      default:
        return Icons.medical_services;
    }
  }

  String _formatTimes(String times) {
    // Format: "['08:00', '12:00', '20:00']"
    try {
      return times.replaceAll('[', '').replaceAll(']', '').replaceAll("'", '');
    } catch (e) {
      return times;
    }
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicationSearchDelegate extends SearchDelegate {
  final Function(String) onSearch;

  _MedicationSearchDelegate({required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox();
  }
}

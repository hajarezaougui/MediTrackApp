import 'package:flutter/material.dart';
import 'package:test_app/models/medication.dart';
import 'package:test_app/services/database_service.dart';
import 'package:test_app/services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddMedicationScreen({
    super.key,
    this.medication,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Valeurs du formulaire
  String _selectedForm = 'Comprimé';
  String _selectedFrequency = 'Quotidien';
  final List<TimeOfDay> _selectedTimes = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _remindersEnabled = true;

  // Options
  final List<String> _forms = [
    'Comprimé',
    'Liquide',
    'Injection',
    'Crème',
    'Gelule',
    'Sirop',
    'Pommade',
  ];

  final List<String> _frequencies = [
    'Quotidien',
    'Hebdomadaire',
    'Personnalisé',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.medication != null) {
      _fillFormWithMedication();
    } else {
      // Valeurs par défaut
      _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
    }
  }

  void _fillFormWithMedication() {
    final medication = widget.medication!;
    
    _nameController.text = medication.name;
    _dosageController.text = medication.dosage;
    _durationController.text = medication.duration;
    _notesController.text = medication.notes;
    
    _selectedForm = medication.form;
    _selectedFrequency = medication.frequency;
    _remindersEnabled = medication.remindersEnabled;
    _startDate = medication.startDate;
    _endDate = medication.endDate;
    
    // Parser les horaires
    _selectedTimes.addAll(_parseTimes(medication.times));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null ? 'Nouveau médicament' : 'Modifier médicament',
        ),
        actions: [
          if (widget.medication != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom du médicament
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du médicament *',
                  hintText: 'Ex: Paracétamol',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom du médicament';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage *',
                  hintText: 'Ex: 500 mg',
                  prefixIcon: Icon(Icons.scale),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Forme
              DropdownButtonFormField<String>(
                value: _selectedForm,
                decoration: const InputDecoration(
                  labelText: 'Forme *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _forms.map((form) {
                  return DropdownMenuItem(
                    value: form,
                    child: Text(form),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedForm = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Fréquence
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: const InputDecoration(
                  labelText: 'Fréquence *',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: _frequencies.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Horaires
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 8),
                          Text(
                            'Horaires de prise',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addTime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedTimes.isEmpty)
                        const Text('Aucun horaire défini')
                      else
                        ..._selectedTimes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final time = entry.value;
                          return ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text(time.format(context)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removeTime(index),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Durée du traitement
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Durée du traitement',
                  hintText: 'Ex: 7 jours, 2 semaines',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),
              
              // Dates
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Date de début'),
                      subtitle: Text(_formatDate(_startDate)),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('Date de fin'),
                      subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Non définie'),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Rappels
              SwitchListTile(
                title: const Text('Activer les rappels'),
                subtitle: const Text('Recevoir des notifications aux heures définies'),
                value: _remindersEnabled,
                onChanged: (value) {
                  setState(() {
                    _remindersEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Informations supplémentaires...',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Bouton de validation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveMedication,
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.medication == null ? 'Ajouter' : 'Modifier',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTimes.add(picked);
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTimes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez définir au moins un horaire')),
        );
        return;
      }

      final now = DateTime.now();
      final medication = Medication(
        id: widget.medication?.id,
        name: _nameController.text,
        dosage: _dosageController.text,
        form: _selectedForm,
        frequency: _selectedFrequency,
        times: _formatTimesForStorage(),
        duration: _durationController.text,
        notes: _notesController.text,
        remindersEnabled: _remindersEnabled,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.medication?.createdAt ?? now,
        updatedAt: now,
      );

      try {
        if (widget.medication == null) {
          // Ajouter
          final id = await DatabaseService.instance.insertMedication(medication);
          //medication.id = id;
          
          if (_remindersEnabled) {
            await NotificationService.instance.scheduleMedicationReminders(medication);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médicament ajouté avec succès')),
          );
        } else {
          // Modifier
          await DatabaseService.instance.updateMedication(medication);
          
          // Annuler les anciennes notifications
          await NotificationService.instance.cancelMedicationReminders(medication.id!);
          
          if (_remindersEnabled) {
            await NotificationService.instance.scheduleMedicationReminders(medication);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médicament modifié avec succès')),
          );
        }
        
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le médicament'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${_nameController.text}" ?',
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
      await DatabaseService.instance.deleteMedication(widget.medication!.id!);
      await NotificationService.instance.cancelMedicationReminders(widget.medication!.id!);
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimesForStorage() {
    final times = _selectedTimes.map((time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }).toList();
    return times.toString();
  }

  List<TimeOfDay> _parseTimes(String timesJson) {
    final times = <TimeOfDay>[];
    
    try {
      final cleanJson = timesJson.replaceAll("'", '"');
      final timeStrings = cleanJson.replaceAll('[', '').replaceAll(']', '').split(',');
      
      for (final timeStr in timeStrings) {
        final trimmed = timeStr.trim();
        if (trimmed.isNotEmpty) {
          final parts = trimmed.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            times.add(TimeOfDay(hour: hour, minute: minute));
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing times: $e');
      times.add(const TimeOfDay(hour: 8, minute: 0));
    }
    
    return times;
  }
}

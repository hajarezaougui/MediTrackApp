import 'package:flutter/material.dart';
import 'package:test_app/models/medical_record.dart';
import 'package:test_app/services/database_service.dart';


class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadMedicalRecord();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalRecord() async {
    final record = await DatabaseService.instance.getMedicalRecord();
    
    if (record != null) {
      setState(() {
        _ageController.text = record.age;
        _heightController.text = record.height;
        _weightController.text = record.weight;
        _allergiesController.text = record.allergies;
        _chronicDiseasesController.text = record.chronicDiseases;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon dossier médical'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
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
              // En-tête
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dossier médical personnel',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Informations de santé confidentielles',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Informations personnelles
              Text(
                'Informations personnelles',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Âge',
                        hintText: '30 ans',
                        prefixIcon: Icon(Icons.cake),
                      ),
                      readOnly: !_isEditing,
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Veuillez entrer votre âge';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Taille',
                        hintText: '175 cm',
                        prefixIcon: Icon(Icons.height),
                      ),
                      readOnly: !_isEditing,
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Veuillez entrer votre taille';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Poids',
                        hintText: '70 kg',
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                      readOnly: !_isEditing,
                      validator: (value) {
                        if (_isEditing && (value == null || value.isEmpty)) {
                          return 'Veuillez entrer votre poids';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Allergies
              Text(
                'Allergies',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  hintText: 'Liste des allergies connues...',
                  prefixIcon: Icon(Icons.warning),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 24),
              
              // Maladies chroniques
              Text(
                'Maladies chroniques',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _chronicDiseasesController,
                decoration: const InputDecoration(
                  hintText: 'Liste des maladies chroniques...',
                  prefixIcon: Icon(Icons.medical_services),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 32),
              
              // Actions
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                          _loadMedicalRecord();
                        },
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveMedicalRecord,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (!_isEditing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Appuyez sur le bouton Modifier pour mettre à jour vos informations',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveMedicalRecord() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      
      // Récupérer l'enregistrement existant
      final existingRecord = await DatabaseService.instance.getMedicalRecord();
      
      final record = MedicalRecord(
        id: existingRecord?.id ?? 1,
        age: _ageController.text,
        height: _heightController.text,
        weight: _weightController.text,
        allergies: _allergiesController.text,
        chronicDiseases: _chronicDiseasesController.text,
        createdAt: existingRecord?.createdAt ?? now,
        updatedAt: now,
      );

      try {
        await DatabaseService.instance.updateMedicalRecord(record);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier médical mis à jour avec succès')),
        );
        
        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

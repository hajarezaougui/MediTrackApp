import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_app/models/symptom_tracking.dart';
import 'package:test_app/services/database_service.dart';

class AddSymptomScreen extends StatefulWidget {
  final SymptomTracking? symptom;

  const AddSymptomScreen({
    super.key,
    this.symptom,
  });

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Valeurs du formulaire
  DateTime _selectedDate = DateTime.now();
  double? _temperature;
  int? _painLevel;
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  String? _selectedMood;
  final _notesController = TextEditingController();

  // Options d'humeur
  final List<String> _moods = [
    'Très bien',
    'Bien',
    'Neutre',
    'Mal',
    'Très mal',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.symptom != null) {
      _fillFormWithSymptom();
    }
  }

  void _fillFormWithSymptom() {
    final symptom = widget.symptom!;
    
    _selectedDate = symptom.date;
    _temperature = symptom.temperature;
    _painLevel = symptom.painLevel;
    _systolicController.text = symptom.bloodPressureSystolic ?? '';
    _diastolicController.text = symptom.bloodPressureDiastolic ?? '';
    _bloodSugarController.text = symptom.bloodSugar ?? '';
    _selectedMood = symptom.mood;
    _notesController.text = symptom.notes;
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _bloodSugarController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.symptom == null ? 'Nouvelle entrée' : 'Modifier l\'entrée',
        ),
        actions: [
          if (widget.symptom != null)
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
              // Date
              ListTile(
                title: const Text('Date *'),
                subtitle: Text(_formatDate(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              
              // Température
              _buildSliderField(
                icon: Icons.thermostat,
                label: 'Température (°C)',
                value: _temperature,
                min: 35.0,
                max: 42.0,
                divisions: 70,
                onChanged: (value) {
                  setState(() {
                    _temperature = value;
                  });
                },
                formatValue: (value) => '${value.toStringAsFixed(1)}°C',
              ),
              const SizedBox(height: 16),
              
              // Niveau de douleur
              _buildSliderField(
                icon: Icons.healing,
                label: 'Niveau de douleur',
                value: _painLevel?.toDouble() ?? 0.0,  // si null, on met 0.0 par défaut
                min: 0,
                max: 10,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _painLevel = value!.toInt();  // value est un double non nullable, safe ici
                  });
                },
                formatValue: (value) => '${value.toInt()}/10',
                color: _painLevel != null 
                    ? SymptomTracking.getPainColor(_painLevel!)
                    : null,
              ),

              const SizedBox(height: 16),
              
              // Tension artérielle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite),
                          const SizedBox(width: 8),
                          Text(
                            'Tension artérielle',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _systolicController,
                              decoration: const InputDecoration(
                                labelText: 'Systolique',
                                hintText: '120',
                                suffixText: 'mmHg',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('/', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _diastolicController,
                              decoration: const InputDecoration(
                                labelText: 'Diastolique',
                                hintText: '80',
                                suffixText: 'mmHg',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Glycémie
              TextFormField(
                controller: _bloodSugarController,
                decoration: const InputDecoration(
                  labelText: 'Glycémie',
                  hintText: '100',
                  prefixIcon: Icon(Icons.water_drop),
                  suffixText: 'mg/dL',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 16),
              
              // Humeur
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mood),
                          const SizedBox(width: 8),
                          Text(
                            'Humeur',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _moods.map((mood) {
                          final isSelected = _selectedMood == mood;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMood = isSelected ? null : mood;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? SymptomTracking.getMoodColor(mood).withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: SymptomTracking.getMoodColor(mood),
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    SymptomTracking.getMoodIcon(mood),
                                    color: SymptomTracking.getMoodColor(mood),
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mood,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Symptômes supplémentaires, observations...',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              
              // Bouton de validation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSymptom,
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.symptom == null ? 'Enregistrer' : 'Modifier',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderField({
    required IconData icon,
    required String label,
    required double? value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double?> onChanged,
    required String Function(double) formatValue,
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (value != null)
                  Text(
                    formatValue(value),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color?.withOpacity(0.3),
                thumbColor: color,
              ),
              child: Slider(
                value: value ?? min,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                label: value != null ? formatValue(value!) : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatValue(min)),
                Text(formatValue(max)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSymptom() async {
    if (_formKey.currentState!.validate()) {
      // Vérifier qu'au moins une valeur est renseignée
      if (_temperature == null && 
          _painLevel == null && 
          _systolicController.text.isEmpty && 
          _diastolicController.text.isEmpty && 
          _bloodSugarController.text.isEmpty && 
          _selectedMood == null && 
          _notesController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez renseigner au moins une valeur')),
        );
        return;
      }

      final now = DateTime.now();
      final symptom = SymptomTracking(
        id: widget.symptom?.id,
        date: _selectedDate,
        temperature: _temperature,
        painLevel: _painLevel,
        bloodPressureSystolic: _systolicController.text.isEmpty ? null : _systolicController.text,
        bloodPressureDiastolic: _diastolicController.text.isEmpty ? null : _diastolicController.text,
        bloodSugar: _bloodSugarController.text.isEmpty ? null : _bloodSugarController.text,
        mood: _selectedMood,
        notes: _notesController.text,
        createdAt: widget.symptom?.createdAt ?? now,
        updatedAt: now,
      );

      try {
        if (widget.symptom == null) {
          // Ajouter
          await DatabaseService.instance.insertSymptomTracking(symptom);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suivi enregistré avec succès')),
          );
        } else {
          // Modifier
          await DatabaseService.instance.updateSymptomTracking(symptom);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Suivi modifié avec succès')),
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
        title: const Text('Supprimer l\'entrée'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer cette entrée du ${_formatDate(widget.symptom!.date)} ?',
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
      await DatabaseService.instance.deleteSymptomTracking(widget.symptom!.id!);
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

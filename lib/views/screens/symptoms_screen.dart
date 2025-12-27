import 'package:flutter/material.dart';
import 'package:test_app/models/symptom_tracking.dart';
import 'package:test_app/services/database_service.dart';
import 'package:test_app/views/screens/add_symptom_screen.dart';
import 'package:test_app/views/widgets/symptom_charts.dart';


class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({super.key});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  late Future<List<SymptomTracking>> _symptomsFuture;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  void _loadSymptoms() {
    setState(() {
      _symptomsFuture = DatabaseService.instance.getSymptomTrackingsByDateRange(
        _selectedDateRange.start,
        _selectedDateRange.end,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des symptômes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec période sélectionnée
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Période analysée',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        '${_formatDate(_selectedDateRange.start)} - ${_formatDate(_selectedDateRange.end)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDateRange,
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: FutureBuilder<List<SymptomTracking>>(
              future: _symptomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }
                
                final symptoms = snapshot.data ?? [];
                
                if (symptoms.isEmpty) {
                  return _buildEmptyState();
                }
                
                return _buildSymptomContent(symptoms);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSymptom,
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
              Icons.analytics_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée de suivi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à suivre vos symptômes quotidiennement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addSymptom,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une entrée'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomContent(List<SymptomTracking> symptoms) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Graphiques
          SymptomCharts(symptoms: symptoms),
          const SizedBox(height: 24),
          
          // Liste des entrées
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique détaillé',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: symptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = symptoms[index];
                    return _SymptomCard(
                      symptom: symptom,
                      onTap: () => _editSymptom(symptom),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addSymptom() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddSymptomScreen(),
      ),
    );
    
    if (result == true) {
      _loadSymptoms();
    }
  }

  void _editSymptom(SymptomTracking symptom) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSymptomScreen(symptom: symptom),
      ),
    );
    
    if (result == true) {
      _loadSymptoms();
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (result != null) {
      setState(() {
        _selectedDateRange = result;
      });
      _loadSymptoms();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SymptomCard extends StatelessWidget {
  final SymptomTracking symptom;
  final VoidCallback onTap;

  const _SymptomCard({
    required this.symptom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _formatDate(symptom.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (symptom.mood != null)
                    Icon(
                      SymptomTracking.getMoodIcon(symptom.mood),
                      color: SymptomTracking.getMoodColor(symptom.mood),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Température
              if (symptom.temperature != null)
                _SymptomItem(
                  icon: Icons.thermostat,
                  label: 'Température',
                  value: '${symptom.temperature}°C',
                  color: _getTemperatureColor(symptom.temperature!),
                ),
              
              // Douleur
              if (symptom.painLevel != null)
                _SymptomItem(
                  icon: Icons.healing,
                  label: 'Niveau de douleur',
                  value: '${symptom.painLevel}/10',
                  color: SymptomTracking.getPainColor(symptom.painLevel!),
                ),
              
              // Tension artérielle
              if (symptom.bloodPressureSystolic != null &&
                  symptom.bloodPressureDiastolic != null)
                _SymptomItem(
                  icon: Icons.favorite,
                  label: 'Tension artérielle',
                  value: symptom.formattedBloodPressure,
                  color: Theme.of(context).colorScheme.primary,
                ),
              
              // Glycémie
              if (symptom.bloodSugar != null)
                _SymptomItem(
                  icon: Icons.water_drop,
                  label: 'Glycémie',
                  value: symptom.formattedBloodSugar,
                  color: Colors.blue,
                ),
              
              // Humeur
              if (symptom.mood != null)
                _SymptomItem(
                  icon: SymptomTracking.getMoodIcon(symptom.mood),
                  label: 'Humeur',
                  value: symptom.mood!,
                  color: SymptomTracking.getMoodColor(symptom.mood),
                ),
              
              // Notes
              if (symptom.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    symptom.notes,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 36.0) return Colors.blue;
    if (temp > 37.5) return Colors.red;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SymptomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SymptomItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:test_app/models/symptom_tracking.dart';

class SymptomCharts extends StatelessWidget {
  final List<SymptomTracking> symptoms;

  const SymptomCharts({
    super.key,
    required this.symptoms,
  });

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Évolution des symptômes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 16),
        
        // Température
        if (_hasTemperatureData())
          _TemperatureChart(symptoms: symptoms),
        
        // Douleur
        if (_hasPainData())
          _PainChart(symptoms: symptoms),
        
        // Tension artérielle
        if (_hasBloodPressureData())
          _BloodPressureChart(symptoms: symptoms),
        
        // Glycémie
        if (_hasBloodSugarData())
          _BloodSugarChart(symptoms: symptoms),
        
        // Humeur
        if (_hasMoodData())
          _MoodChart(symptoms: symptoms),
      ],
    );
  }

  bool _hasTemperatureData() {
    return symptoms.any((s) => s.temperature != null);
  }

  bool _hasPainData() {
    return symptoms.any((s) => s.painLevel != null);
  }

  bool _hasBloodPressureData() {
    return symptoms.any((s) => s.bloodPressureSystolic != null && s.bloodPressureDiastolic != null);
  }

  bool _hasBloodSugarData() {
    return symptoms.any((s) => s.bloodSugar != null);
  }

  bool _hasMoodData() {
    return symptoms.any((s) => s.mood != null);
  }
}

class _TemperatureChart extends StatelessWidget {
  final List<SymptomTracking> symptoms;

  const _TemperatureChart({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final temperatureData = symptoms
        .where((s) => s.temperature != null)
        .map((s) => FlSpot(
              s.date.millisecondsSinceEpoch.toDouble(),
              s.temperature!,
            ))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Température',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: temperatureData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 35,
                  maxY: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PainChart extends StatelessWidget {
  final List<SymptomTracking> symptoms;

  const _PainChart({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final painData = symptoms
        .where((s) => s.painLevel != null)
        .map((s) => FlSpot(
              s.date.millisecondsSinceEpoch.toDouble(),
              s.painLevel!.toDouble(),
            ))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.healing, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Niveau de douleur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: painData,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureChart extends StatelessWidget {
  final List<SymptomTracking> symptoms;

  const _BloodPressureChart({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final systolicData = symptoms
        .where((s) => s.bloodPressureSystolic != null)
        .map((s) => FlSpot(
              s.date.millisecondsSinceEpoch.toDouble(),
              double.parse(s.bloodPressureSystolic!),
            ))
        .toList();

    final diastolicData = symptoms
        .where((s) => s.bloodPressureDiastolic != null)
        .map((s) => FlSpot(
              s.date.millisecondsSinceEpoch.toDouble(),
              double.parse(s.bloodPressureDiastolic!),
            ))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Tension artérielle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: systolicData,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                    ),
                    LineChartBarData(
                      spots: diastolicData,
                      isCurved: true,
                      color: Colors.pink,
                      barWidth: 3,
                    ),
                  ],
                  minY: 60,
                  maxY: 180,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.red, label: 'Systolique'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.pink, label: 'Diastolique'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodSugarChart extends StatelessWidget {
  final List<SymptomTracking> symptoms;

  const _BloodSugarChart({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final bloodSugarData = symptoms
        .where((s) => s.bloodSugar != null)
        .map((s) => FlSpot(
              s.date.millisecondsSinceEpoch.toDouble(),
              double.parse(s.bloodSugar!),
            ))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Glycémie',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Text('${date.day}/${date.month}');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: bloodSugarData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChart extends StatelessWidget {
  final List<SymptomTracking> symptoms;

  const _MoodChart({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final moodCounts = <String, int>{};
    for (final symptom in symptoms.where((s) => s.mood != null)) {
      moodCounts[symptom.mood!] = (moodCounts[symptom.mood!] ?? 0) + 1;
    }

    final moodColors = {
      'Très bien': Colors.green,
      'Bien': Colors.lightGreen,
      'Neutre': Colors.orange,
      'Mal': Colors.orangeAccent,
      'Très mal': Colors.red,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mood, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Humeur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final moods = moodCounts.keys.toList();
                          if (value.toInt() < moods.length) {
                            return Text(moods[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: List.generate(
                    moodCounts.length,
                    (index) {
                      final mood = moodCounts.keys.elementAt(index);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: moodCounts[mood]!.toDouble(),
                            color: moodColors[mood] ?? Colors.grey,
                            width: 20,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

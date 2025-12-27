import 'package:flutter/material.dart';

class TodaySummaryCard extends StatelessWidget {
  final int takenCount;
  final int totalCount;
  final double adherenceRate;

  const TodaySummaryCard({
    super.key,
    required this.takenCount,
    required this.totalCount,
    required this.adherenceRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aujourd\'hui',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.medical_services,
                    label: 'Prises',
                    value: '$takenCount/$totalCount',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.percent,
                    label: 'Adhérence',
                    value: '${adherenceRate.toStringAsFixed(0)}%',
                    color: _getAdherenceColor(adherenceRate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? takenCount / totalCount : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getAdherenceColor(adherenceRate),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Message selon le taux d'adhérence
            Text(
              _getAdherenceMessage(adherenceRate),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAdherenceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  String _getAdherenceMessage(double rate) {
    if (rate >= 90) {
      return 'Excellent! Continuez comme ça.';
    } else if (rate >= 70) {
      return 'Bien, mais vous pouvez faire mieux.';
    } else if (rate > 0) {
      return 'Essayez de ne pas oublier vos médicaments.';
    } else {
      return 'Commencez votre traitement dès aujourd\'hui.';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

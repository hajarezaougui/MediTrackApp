import 'package:flutter/material.dart';
import 'package:test_app/models/medication_intake.dart';
import 'package:test_app/services/database_service.dart';
import 'package:test_app/views/screens/documents_screen.dart';
import 'package:test_app/views/screens/medical_record_screen.dart';
import 'package:test_app/views/screens/medications_screen.dart';
import 'package:test_app/views/screens/symptoms_screen.dart';
import 'package:test_app/views/widgets/next_medication_card.dart';
import 'package:test_app/views/widgets/today_summary_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  MedicationIntake? _nextMedication;
  int _todayTakenCount = 0;
  int _todayTotalCount = 0;
  double _adherenceRate = 0.0;

  final List<Widget> _screens = [
    const HomeContent(),
    const MedicationsScreen(),
    const SymptomsScreen(),
    const DocumentsScreen(),
    const MedicalRecordScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    await _loadNextMedication();
    await _loadTodayStats();
    await _loadAdherenceRate();
  }

  Future<void> _loadNextMedication() async {
    final nextMed = await DatabaseService.instance.getNextMedication();
    setState(() {
      _nextMedication = nextMed;
    });
  }

  Future<void> _loadTodayStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final stats = await DatabaseService.instance.getMedicationAdherenceStats(
      today,
      tomorrow,
    );
    
    setState(() {
      _todayTakenCount = stats['taken'] as int;
      _todayTotalCount = stats['total'] as int;
    });
  }

  Future<void> _loadAdherenceRate() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final stats = await DatabaseService.instance.getMedicationAdherenceStats(
      sevenDaysAgo,
      now,
    );
    
    setState(() {
      _adherenceRate = stats['adherenceRate'] as double;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0 
        ? _buildHomeContent()
        : _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services),
            label: 'Médicaments',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Suivi',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('MediTrack'),
          floating: true,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Bonjour! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prochain médicament
                if (_nextMedication != null) ...[
                  NextMedicationCard(
                    medicationIntake: _nextMedication!,
                    onMedicationTaken: _loadHomeData,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Résumé du jour
                TodaySummaryCard(
                  takenCount: _todayTakenCount,
                  totalCount: _todayTotalCount,
                  adherenceRate: _adherenceRate,
                ),
                const SizedBox(height: 24),
                
                // Actions rapides
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _QuickActionCard(
          icon: Icons.add,
          title: 'Ajouter un médicament',
          subtitle: 'Nouveau traitement',
          color: Theme.of(context).colorScheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MedicationsScreen(),
              ),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.note_add,
          title: 'Noter symptômes',
          subtitle: 'Suivi quotidien',
          color: Theme.of(context).colorScheme.secondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SymptomsScreen(),
              ),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.camera_alt,
          title: 'Scanner document',
          subtitle: 'Nouveau document',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DocumentsScreen(),
              ),
            );
          },
        ),
        _QuickActionCard(
          icon: Icons.calendar_today,
          title: 'Voir historique',
          subtitle: 'Prises de médicaments',
          color: Colors.purple,
          onTap: () {
            // TODO: Naviguer vers l'historique
          },
        ),
      ],
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Chargement...'));
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

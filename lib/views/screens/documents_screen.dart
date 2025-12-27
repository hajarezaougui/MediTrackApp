import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_app/models/medical_document.dart';
import 'package:test_app/services/database_service.dart';
import 'package:test_app/views/screens/add_document_screen.dart';
import 'package:test_app/views/widgets/document_card.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<MedicalDocument>> _documentsFuture;
  String _selectedType = 'Tous';

  final List<String> _documentTypes = [
    'Tous',
    'analyse',
    'ordonnance',
    'radio',
    'compte_rendu',
    'autre',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() {
    setState(() {
      if (_selectedType == 'Tous') {
        _documentsFuture = DatabaseService.instance.getAllMedicalDocuments();
      } else {
        _documentsFuture =
            DatabaseService.instance.getMedicalDocumentsByType(_selectedType);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents médicaux'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedType = value;
              });
              _loadDocuments();
            },
            itemBuilder: (context) {
              return _documentTypes.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MedicalDocument>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              if (_selectedType != 'Tous')
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      Text(
                        'Filtré par: ${_getTypeDisplayName(_selectedType)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedType = 'Tous';
                          });
                          _loadDocuments();
                        },
                        child: const Text('Tout voir'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DocumentCard(
                        document: document,
                        onTap: () => _viewDocument(document),
                        onDelete: () => _deleteDocument(document),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
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
              Icons.folder_open_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez vos documents médicaux (analyses, ordonnances, radios...)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un document'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Ajouter un document',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Ajouter manuellement'),
                onTap: () {
                  Navigator.pop(context);
                  _addDocument();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Vérifier les permissions
    final status = await _checkPermissions();
    if (!status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission refusée')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        // Copier l'image dans le dossier de l'application
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(directory.path, fileName);

        // saveTo retourne void, donc on ne l'assigne pas
        await image.saveTo(filePath);

        // Naviguer vers l'écran d'ajout avec le fichier
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddDocumentScreen(filePath: filePath),
          ),
        );

        if (result == true) {
          _loadDocuments();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<bool> _checkPermissions() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    if (await Permission.photos.request().isGranted) {
      return true;
    }

    return false;
  }

  void _addDocument() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddDocumentScreen(),
      ),
    );

    if (result == true) {
      _loadDocuments();
    }
  }

  void _viewDocument(MedicalDocument document) {
    // TODO: Implémenter l'affichage du document
    // Pour l'instant, on affiche juste les détails
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
                            color: document.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            document.icon,
                            color: document.color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                _getTypeDisplayName(document.type),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
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
                      icon: Icons.calendar_today,
                      label: 'Date du document',
                      value: _formatDate(document.documentDate),
                    ),
                    const SizedBox(height: 16),

                    if (document.doctorName != null) ...[
                      _DetailItem(
                        icon: Icons.person,
                        label: 'Médecin',
                        value: document.doctorName!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (document.notes.isNotEmpty) ...[
                      _DetailItem(
                        icon: Icons.note,
                        label: 'Notes',
                        value: document.notes,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _DetailItem(
                      icon: Icons.insert_drive_file,
                      label: 'Fichier',
                      value: path.basename(document.filePath),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editDocument(document);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Ouvrir le document
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Ouvrir'),
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

  void _editDocument(MedicalDocument document) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentScreen(document: document),
      ),
    );

    if (result == true) {
      _loadDocuments();
    }
  }

  void _deleteDocument(MedicalDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${document.title}" ?',
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
      await DatabaseService.instance.deleteMedicalDocument(document.id!);
      _loadDocuments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé')),
      );
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'analyse':
        return 'Analyse';
      case 'ordonnance':
        return 'Ordonnance';
      case 'radio':
        return 'Radio';
      case 'compte_rendu':
        return 'Compte rendu';
      case 'autre':
        return 'Autre';
      case 'Tous':
        return 'Tous les documents';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

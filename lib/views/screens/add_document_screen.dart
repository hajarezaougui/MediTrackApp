import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_app/models/medical_document.dart';
import 'package:test_app/services/database_service.dart';

class AddDocumentScreen extends StatefulWidget {
  final MedicalDocument? document;
  final String? filePath;

  const AddDocumentScreen({
    super.key,
    this.document,
    this.filePath,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Valeurs du formulaire
  String _selectedType = 'autre';
  DateTime _documentDate = DateTime.now();
  String? _currentFilePath;
  bool _isLoading = false;

  // Types de documents
  final List<Map<String, String>> _documentTypes = [
    {'value': 'analyse', 'label': 'Analyse'},
    {'value': 'ordonnance', 'label': 'Ordonnance'},
    {'value': 'radio', 'label': 'Radio'},
    {'value': 'compte_rendu', 'label': 'Compte rendu'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.filePath;
    
    if (widget.document != null) {
      _fillFormWithDocument();
    }
  }

  void _fillFormWithDocument() {
    final document = widget.document!;
    
    _titleController.text = document.title;
    _doctorController.text = document.doctorName ?? '';
    _notesController.text = document.notes;
    _selectedType = document.type;
    _documentDate = document.documentDate;
    _currentFilePath = document.filePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document == null ? 'Nouveau document' : 'Modifier document',
        ),
        actions: [
          if (widget.document != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aperçu du fichier
                  if (_currentFilePath != null) ...[
                    Card(
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getFileIcon(),
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              path.basename(_currentFilePath!),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Titre
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre *',
                      hintText: 'Ex: Bilan sanguin',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un titre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Type de document
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de document *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _documentTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date du document
                  ListTile(
                    title: const Text('Date du document *'),
                    subtitle: Text(_formatDate(_documentDate)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 16),
                  
                  // Médecin
                  TextFormField(
                    controller: _doctorController,
                    decoration: const InputDecoration(
                      labelText: 'Médecin (optionnel)',
                      hintText: 'Dr Martin',
                      prefixIcon: Icon(Icons.person),
                    ),
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
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Changer de fichier
                  if (widget.document == null)
                    OutlinedButton.icon(
                      onPressed: _changeFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Changer de fichier'),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveDocument,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.document == null ? 'Enregistrer' : 'Modifier',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Indicateur de chargement
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _documentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _documentDate = picked;
      });
    }
  }

  void _changeFile() async {
    // Vérifier les permissions
    final status = await _checkPermissions();
    if (!status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission refusée')),
      );
      return;
    }

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
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _isLoading = true;
        });
        
        // Copier l'image dans le dossier de l'application
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = path.join(directory.path, fileName);
        
        await image.saveTo(filePath); // Correction ici : on n'assigne pas, saveTo retourne void
        
        setState(() {
          _isLoading = false;
          _currentFilePath = filePath;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _saveDocument() async {
    if (_formKey.currentState!.validate()) {
      if (_currentFilePath == null && widget.document == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un fichier')),
        );
        return;
      }

      final now = DateTime.now();
      final document = MedicalDocument(
        id: widget.document?.id,
        title: _titleController.text,
        type: _selectedType,
        filePath: _currentFilePath ?? widget.document!.filePath,
        doctorName: _doctorController.text.isEmpty ? null : _doctorController.text,
        documentDate: _documentDate,
        notes: _notesController.text,
        createdAt: widget.document?.createdAt ?? now,
        updatedAt: now,
      );

      try {
        if (widget.document == null) {
          // Ajouter
          await DatabaseService.instance.insertMedicalDocument(document);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document enregistré avec succès')),
          );
        } else {
          // Modifier
          await DatabaseService.instance.updateMedicalDocument(document);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document modifié avec succès')),
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
        title: const Text('Supprimer le document'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${_titleController.text}" ?',
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
      await DatabaseService.instance.deleteMedicalDocument(widget.document!.id!);
      Navigator.pop(context, true);
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getFileIcon() {
    if (_currentFilePath == null) return Icons.insert_drive_file;
    
    final extension = path.extension(_currentFilePath!).toLowerCase();
    
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }
}

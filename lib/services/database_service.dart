import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:test_app/models/medical_document.dart';
import 'package:test_app/models/medical_record.dart';
import 'package:test_app/models/medication.dart';
import 'package:test_app/models/medication_intake.dart';
import 'package:test_app/models/symptom_tracking.dart';

class DatabaseService {
  // Singleton instance
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meditrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Table pour le dossier médical
    await db.execute('''
      CREATE TABLE medical_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        age TEXT NOT NULL,
        height TEXT NOT NULL,
        weight TEXT NOT NULL,
        allergies TEXT NOT NULL,
        chronicDiseases TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Table pour les médicaments
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        form TEXT NOT NULL,
        frequency TEXT NOT NULL,
        times TEXT NOT NULL,
        duration TEXT NOT NULL,
        notes TEXT NOT NULL,
        remindersEnabled INTEGER NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Table pour l'historique des prises
    await db.execute('''
      CREATE TABLE medication_intakes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        scheduledTime TEXT NOT NULL,
        actualTime TEXT,
        status TEXT NOT NULL,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (medicationId) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');

    // Table pour les documents médicaux
    await db.execute('''
      CREATE TABLE medical_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        filePath TEXT NOT NULL,
        doctorName TEXT,
        documentDate TEXT NOT NULL,
        notes TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Table pour le suivi des symptômes
    await db.execute('''
      CREATE TABLE symptom_trackings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        temperature REAL,
        painLevel INTEGER,
        bloodPressureSystolic TEXT,
        bloodPressureDiastolic TEXT,
        bloodSugar TEXT,
        mood TEXT,
        notes TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Créer un dossier médical vide par défaut
    final now = DateTime.now();
    await db.insert('medical_records', {
      'age': '',
      'height': '',
      'weight': '',
      'allergies': '',
      'chronicDiseases': '',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  // Fermer la base de données
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // ==================== DOSSIER MÉDICAL ====================

  Future<MedicalRecord?> getMedicalRecord() async {
    final db = await database;
    final result = await db.query('medical_records', limit: 1);
    if (result.isEmpty) return null;
    return MedicalRecord.fromMap(result.first);
  }

  Future<int> updateMedicalRecord(MedicalRecord record) async {
    final db = await database;
    return await db.update(
      'medical_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // ==================== MÉDICAMENTS ====================

  Future<int> insertMedication(Medication medication) async {
    final db = await database;
    return await db.insert('medications', medication.toMap());
  }

  Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final result = await db.query('medications', orderBy: 'name ASC');
    return result.map((map) => Medication.fromMap(map)).toList();
  }

  Future<Medication?> getMedicationById(int id) async {
    final db = await database;
    final result = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Medication.fromMap(result.first);
  }

  Future<int> updateMedication(Medication medication) async {
    final db = await database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> deleteMedication(int id) async {
    final db = await database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PRISES DE MÉDICAMENTS ====================

  Future<int> insertMedicationIntake(MedicationIntake intake) async {
    final db = await database;
    return await db.insert('medication_intakes', intake.toMap());
  }

  Future<List<MedicationIntake>> getMedicationIntakesByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T').first;
    final result = await db.query(
      'medication_intakes',
      where: "date(date) = date('$dateStr')",
      orderBy: 'scheduledTime ASC',
    );
    return result.map((map) => MedicationIntake.fromMap(map)).toList();
  }

  Future<List<MedicationIntake>> getMedicationIntakesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'medication_intakes',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC, scheduledTime ASC',
    );
    return result.map((map) => MedicationIntake.fromMap(map)).toList();
  }

  Future<MedicationIntake?> getMedicationIntake(
    int medicationId,
    DateTime scheduledTime,
  ) async {
    final db = await database;
    final result = await db.query(
      'medication_intakes',
      where: 'medicationId = ? AND scheduledTime = ?',
      whereArgs: [medicationId, scheduledTime.toIso8601String()],
    );
    if (result.isEmpty) return null;
    return MedicationIntake.fromMap(result.first);
  }

  Future<int> updateMedicationIntake(MedicationIntake intake) async {
    final db = await database;
    return await db.update(
      'medication_intakes',
      intake.toMap(),
      where: 'id = ?',
      whereArgs: [intake.id],
    );
  }

  // ==================== DOCUMENTS MÉDICAUX ====================

  Future<int> insertMedicalDocument(MedicalDocument document) async {
    final db = await database;
    return await db.insert('medical_documents', document.toMap());
  }

  Future<List<MedicalDocument>> getAllMedicalDocuments() async {
    final db = await database;
    final result = await db.query(
      'medical_documents',
      orderBy: 'documentDate DESC',
    );
    return result.map((map) => MedicalDocument.fromMap(map)).toList();
  }

  Future<List<MedicalDocument>> getMedicalDocumentsByType(String type) async {
    final db = await database;
    final result = await db.query(
      'medical_documents',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'documentDate DESC',
    );
    return result.map((map) => MedicalDocument.fromMap(map)).toList();
  }

  Future<MedicalDocument?> getMedicalDocumentById(int id) async {
    final db = await database;
    final result = await db.query(
      'medical_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return MedicalDocument.fromMap(result.first);
  }

  Future<int> updateMedicalDocument(MedicalDocument document) async {
    final db = await database;
    return await db.update(
      'medical_documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<int> deleteMedicalDocument(int id) async {
    final db = await database;
    return await db.delete(
      'medical_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SUIVI DES SYMPTÔMES ====================

  Future<int> insertSymptomTracking(SymptomTracking tracking) async {
    final db = await database;
    return await db.insert('symptom_trackings', tracking.toMap());
  }

  Future<List<SymptomTracking>> getAllSymptomTrackings() async {
    final db = await database;
    final result = await db.query(
      'symptom_trackings',
      orderBy: 'date DESC',
    );
    return result.map((map) => SymptomTracking.fromMap(map)).toList();
  }

  Future<List<SymptomTracking>> getSymptomTrackingsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'symptom_trackings',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );
    return result.map((map) => SymptomTracking.fromMap(map)).toList();
  }

  Future<SymptomTracking?> getSymptomTrackingByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T').first;
    final result = await db.query(
      'symptom_trackings',
      where: "date(date) = date('$dateStr')",
    );
    if (result.isEmpty) return null;
    return SymptomTracking.fromMap(result.first);
  }

  Future<int> updateSymptomTracking(SymptomTracking tracking) async {
    final db = await database;
    return await db.update(
      'symptom_trackings',
      tracking.toMap(),
      where: 'id = ?',
      whereArgs: [tracking.id],
    );
  }

  Future<int> deleteSymptomTracking(int id) async {
    final db = await database;
    return await db.delete(
      'symptom_trackings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== STATISTIQUES ====================

  // Obtenir le taux d'adhésence aux médicaments
  Future<Map<String, dynamic>> getMedicationAdherenceStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    
    // Total des prises prévues
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM medication_intakes
      WHERE date BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    // Prises effectuées
    final takenResult = await db.rawQuery('''
      SELECT COUNT(*) as taken
      FROM medication_intakes
      WHERE date BETWEEN ? AND ?
      AND status = 'taken'
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    final total = totalResult.first['total'] as int? ?? 0;
    final taken = takenResult.first['taken'] as int? ?? 0;
    
    return {
      'total': total,
      'taken': taken,
      'missed': total - taken,
      'adherenceRate': total > 0 ? (taken / total * 100).toDouble() : 0.0,
    };
  }

  // Obtenir les rappels du jour
  Future<List<MedicationIntake>> getTodayReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return await getMedicationIntakesByDateRange(today, tomorrow);
  }

  // Obtenir le prochain médicament à prendre
  Future<MedicationIntake?> getNextMedication() async {
    final db = await database;
    final now = DateTime.now();
    
    final result = await db.rawQuery('''
      SELECT * FROM medication_intakes
      WHERE scheduledTime > ?
      AND status = 'pending'
      ORDER BY scheduledTime ASC
      LIMIT 1
    ''', [now.toIso8601String()]);
    
    if (result.isEmpty) return null;
    return MedicationIntake.fromMap(result.first);
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'ocr_parser.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'car_scanner.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cars (
            plate TEXT PRIMARY KEY,
            model TEXT,
            unit TEXT,
            location TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS metadata (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }
      },
  );
}

  Future<void> replaceAllEntries(List<CarEntry> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cars');
      for (final entry in entries) {
        final cleanModel = (entry.model ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
        await txn.insert(
          'cars',
          {
            'plate': entry.carRow.plate,
            'model': cleanModel,
            'unit': entry.carRow.unit,
            'location': entry.carRow.location,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
        'metadata',
        {'key': 'last_updated', 'value': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<CarEntry?> findByPlate(String scannedText) async {
    final db = await database;
    final target = normalizeForComparison(scannedText);

    final results = await db.query('cars');

    for (final row in results) {
      final storedPlate = row['plate'] as String;
      if (normalizeForComparison(storedPlate) == target) {
        return CarEntry(
          model: row['model'] as String?,
          carRow: CarRow(
            plate: storedPlate,
            unit: row['unit'] as String,
            location: row['location'] as String,
          ),
        );
      }
    }

    return null;
  }



  Future<DateTime?> getLastUpdated() async {
    final db = await database;
    final results = await db.query(
      'metadata',
      where: 'key = ?',
      whereArgs: ['last_updated'],
    );

    if (results.isEmpty) return null;
    return DateTime.tryParse(results.first['value'] as String);
  }

  Future<List<CarEntry>> getAllEntries() async {
    final db = await database;
    final results = await db.query('cars', orderBy: 'model COLLATE NOCASE, plate COLLATE NOCASE');

    return results.map((row) {
      return CarEntry(
        model: row['model'] as String?,
        carRow: CarRow(
          plate: row['plate'] as String,
          unit: row['unit'] as String,
          location: row['location'] as String,
        ),
      );
    }).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cars');
      await txn.delete('metadata');
    });
  }



}


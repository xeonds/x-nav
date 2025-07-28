import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static final DB _instance = DB._internal();
  Database? _database;

  factory DB() {
    return _instance;
  }

  DB._internal();

  Database? get database {
    return _database;
  }

  static Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'neodb.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE route (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE,
            gpx TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE,
            data BLOB
          )
        ''');
        await db.execute('''
          CREATE TABLE summary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE,
            timestamp INTEGER,
            start_time INTEGER,
            sport TEXT,
            max_temperature FLOAT,
            avg_temperature FLOAT,
            total_ascent FLOAT,
            total_descent FLOAT,
            total_distance FLOAT,
            total_elapsed_time INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE ride_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE best_score (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT UNIQUE,
            value TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // if (oldVersion < 2) {
        //   await db.execute('''
        //     CREATE TABLE IF NOT EXISTS cache (
        //       key TEXT PRIMARY KEY,
        //       value TEXT
        //     )
        //   ''');
        // }
      },
    );
  }
}

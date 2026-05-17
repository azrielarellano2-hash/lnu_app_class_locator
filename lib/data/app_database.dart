import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'campus_room_seeds.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'lnu_smartpath.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            student_id TEXT,
            full_name TEXT,
            college TEXT,
            course TEXT,
            section TEXT
          );
        ''');
        await db.insert('profile', {'id': 1});

        await db.execute('''
          CREATE TABLE schedule_slots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            enrollment_code TEXT,
            subject_name TEXT NOT NULL,
            room_code TEXT NOT NULL,
            day_of_week INTEGER NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            instructor_name TEXT,
            subject_title TEXT,
            section TEXT,
            day_pattern TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            due_date TEXT NOT NULL,
            due_time TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0,
            reminder_type TEXT NOT NULL DEFAULT 'assignment'
          );
        ''');

        await db.execute('''
          CREATE TABLE campus_rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL UNIQUE,
            building TEXT NOT NULL,
            floor TEXT,
            description TEXT,
            latitude REAL,
            longitude REAL
          );
        ''');

        await _seedRooms(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _seedRooms(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE schedule_slots ADD COLUMN instructor_name TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE schedule_slots ADD COLUMN subject_title TEXT');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE profile ADD COLUMN section TEXT');
          await db.execute('ALTER TABLE schedule_slots ADD COLUMN enrollment_code TEXT');
          await db.execute('ALTER TABLE schedule_slots ADD COLUMN section TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE schedule_slots ADD COLUMN day_pattern TEXT');
        }
      },
    );
  }

  Future<void> _seedRooms(Database db) async {
    for (final r in extendedCampusRoomSeedRows()) {
      await db.insert('campus_rooms', r, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}

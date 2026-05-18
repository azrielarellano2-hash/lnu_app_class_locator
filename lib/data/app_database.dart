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
      version: 7,
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

        await _createExtendedTables(db);
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
        if (oldVersion < 7) {
          await _createExtendedTables(db);
        }
      },
    );
  }

  Future<void> _createExtendedTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teachers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        position TEXT,
        department TEXT,
        college TEXT,
        email TEXT,
        contact_number TEXT,
        profile_photo_path TEXT,
        bio TEXT,
        years_of_service INTEGER,
        office_hours TEXT,
        office_room TEXT,
        subjects_taught TEXT,
        social_links TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule_items (
        id TEXT PRIMARY KEY,
        subject_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        due_time TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT,
        color_tag TEXT,
        attachment_paths TEXT,
        repeat_rule TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id TEXT PRIMARY KEY,
        id_number TEXT,
        name TEXT,
        college TEXT,
        course TEXT,
        year TEXT,
        section TEXT,
        profile_photo_path TEXT,
        bio TEXT,
        semester TEXT,
        academic_year TEXT,
        form_number TEXT
      );
    ''');
    await db.insert('students', {'id': 'default'}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _seedRooms(Database db) async {
    for (final r in extendedCampusRoomSeedRows()) {
      await db.insert('campus_rooms', r, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite（shiftnote.db）の生成とスキーマ管理。
class AppDatabase {
  static const _fileName = 'shiftnote.db';
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        email         TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt          TEXT NOT NULL,
        display_name  TEXT NOT NULL CHECK(length(display_name) BETWEEN 1 AND 20),
        bio           TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE shifts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        start_at      TEXT NOT NULL,
        end_at        TEXT NOT NULL CHECK(end_at > start_at),
        break_minutes INTEGER NOT NULL DEFAULT 0 CHECK(break_minutes BETWEEN 0 AND 480),
        status        INTEGER NOT NULL DEFAULT 0 CHECK(status BETWEEN 0 AND 1),
        memo          TEXT,
        created_at    TEXT NOT NULL,
        updated_at    TEXT NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_shifts_user_start ON shifts (user_id, start_at)');
  }
}

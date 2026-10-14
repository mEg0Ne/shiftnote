import '../core/app_exception.dart';
import '../core/formatters.dart';
import '../models/user.dart';
import 'app_database.dart';

class UserRepository {
  final AppDatabase _db;
  UserRepository(this._db);

  /// 登録。メール重複は UNIQUE 制約違反（DatabaseException）として上位で変換される。
  Future<User> create({
    required String email,
    required String displayName,
    required String passwordHash,
    required String salt,
  }) async {
    final db = await _db.database;
    final now = nowIso();
    final id = await db.insert('users', {
      'email': email,
      'password_hash': passwordHash,
      'salt': salt,
      'display_name': displayName,
      'created_at': now,
      'updated_at': now,
    });
    final user = await findById(id);
    if (user == null) throw AppException.database();
    return user;
  }

  Future<UserCredential?> findCredentialByEmail(String email) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isEmpty ? null : _toCredential(rows.first);
  }

  Future<UserCredential?> findCredentialById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _toCredential(rows.first);
  }

  Future<User?> findById(int id) async {
    final db = await _db.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<void> updateProfile(int id, {required String displayName, String? bio}) async {
    final db = await _db.database;
    final n = await db.update(
      'users',
      {
        'display_name': displayName,
        'bio': (bio == null || bio.trim().isEmpty) ? null : bio.trim(),
        'updated_at': nowIso(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (n == 0) throw AppException.notFound('ユーザーが見つかりませんでした');
  }

  Future<void> updatePassword(int id, String passwordHash, String salt) async {
    final db = await _db.database;
    final n = await db.update(
      'users',
      {'password_hash': passwordHash, 'salt': salt, 'updated_at': nowIso()},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (n == 0) throw AppException.notFound('ユーザーが見つかりませんでした');
  }

  UserCredential _toCredential(Map<String, Object?> m) =>
      UserCredential(User.fromMap(m), m['password_hash'] as String, m['salt'] as String);
}

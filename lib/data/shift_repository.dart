import '../core/app_exception.dart';
import '../core/formatters.dart';
import '../models/shift.dart';
import 'app_database.dart';

class ShiftRepository {
  final AppDatabase _db;
  ShiftRepository(this._db);

  Future<int> insert(Shift s) async {
    final db = await _db.database;
    return db.insert('shifts', s.toMap());
  }

  /// 複数件を1トランザクションで登録。1件でも失敗したら全件ロールバックする。
  Future<void> insertAll(List<Shift> list) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final s in list) {
        await txn.insert('shifts', s.toMap());
      }
    });
  }

  Future<void> update(Shift s) async {
    final db = await _db.database;
    final n = await db.update('shifts', s.toMap(),
        where: 'id = ? AND user_id = ?', whereArgs: [s.id, s.userId]);
    if (n == 0) throw AppException.notFound('このシフトは見つかりませんでした');
  }

  Future<void> updateStatus(int userId, int id, ShiftStatus status) async {
    final db = await _db.database;
    final n = await db.update(
      'shifts',
      {'status': status.code, 'updated_at': nowIso()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (n == 0) throw AppException.notFound('このシフトは見つかりませんでした');
  }

  Future<void> delete(int userId, int id) async {
    final db = await _db.database;
    final n = await db.delete('shifts', where: 'id = ? AND user_id = ?', whereArgs: [id, userId]);
    if (n == 0) throw AppException.notFound('このシフトは見つかりませんでした');
  }

  Future<Shift?> findById(int userId, int id) async {
    final db = await _db.database;
    final rows = await db.query('shifts',
        where: 'id = ? AND user_id = ?', whereArgs: [id, userId], limit: 1);
    return rows.isEmpty ? null : Shift.fromMap(rows.first);
  }

  /// 開始日時が [from] 以上 [to] 未満のシフトを開始順で取得。
  Future<List<Shift>> findBetween(int userId, DateTime from, DateTime to) async {
    final db = await _db.database;
    final rows = await db.query(
      'shifts',
      where: 'user_id = ? AND start_at >= ? AND start_at < ?',
      whereArgs: [userId, toIsoMinute(from), toIsoMinute(to)],
      orderBy: 'start_at ASC',
    );
    return rows.map(Shift.fromMap).toList();
  }

  /// 同一ユーザーの既存シフトと時間が重なるか。編集時は自分自身を除外する。
  Future<bool> hasOverlap(int userId, DateTime start, DateTime end, {int? excludeId}) async {
    final db = await _db.database;
    final args = <Object?>[userId, toIsoMinute(end), toIsoMinute(start)];
    var where = 'user_id = ? AND start_at < ? AND end_at > ?';
    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM shifts WHERE $where', args);
    return ((rows.first['c'] as int?) ?? 0) > 0;
  }
}

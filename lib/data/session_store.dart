import 'package:shared_preferences/shared_preferences.dart';

/// ログイン状態（ユーザーID）を端末に保持する。
class SessionStore {
  static const _key = 'user_id';

  Future<int?> load() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_key);
  }

  Future<void> save(int userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, userId);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

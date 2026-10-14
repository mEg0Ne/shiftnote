import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../core/password_hasher.dart';
import '../core/result.dart';
import '../data/session_store.dart';
import '../data/user_repository.dart';
import '../models/user.dart';

/// 認証・ログイン状態・プロフィールを管理する。
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._users, this._session);

  final UserRepository _users;
  final SessionStore _session;

  static const int _maxFailures = 5;
  static const Duration _lockDuration = Duration(seconds: 30);

  User? _user;
  bool _initialized = false;
  String? _notice;
  int _failures = 0;
  DateTime? _lockedUntil;

  User? get currentUser => _user;
  bool get initialized => _initialized;

  /// ログイン画面に1度だけ表示するお知らせ（強制ログアウト時など）
  String? takeNotice() {
    final n = _notice;
    _notice = null;
    return n;
  }

  bool get isLocked => _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get lockRemainingSeconds =>
      isLocked ? _lockedUntil!.difference(DateTime.now()).inSeconds + 1 : 0;

  /// 起動時：保存済みのユーザーIDが有効ならログイン状態を復元する。
  Future<void> restore() async {
    final r = await guard(() async {
      final id = await _session.load();
      if (id == null) return null;
      final user = await _users.findById(id);
      if (user == null) await _session.clear();
      return user;
    });
    _user = r.isSuccess ? r.value : null;
    _initialized = true;
    notifyListeners();
  }

  /// 成功なら null、失敗なら AppException を返す。
  Future<AppException?> login(String email, String password) async {
    if (isLocked) return AppException.locked(lockRemainingSeconds);
    final r = await guard(() async {
      final c = await _users.findCredentialByEmail(email.trim().toLowerCase());
      if (c == null || !PasswordHasher.verify(password, c.salt, c.passwordHash)) {
        throw AppException.authFailed();
      }
      await _session.save(c.user.id);
      return c.user;
    });
    if (!r.isSuccess) {
      if (r.error!.type == AppErrorType.authFailed) {
        _failures++;
        if (_failures >= _maxFailures) {
          _failures = 0;
          _lockedUntil = DateTime.now().add(_lockDuration);
        }
        notifyListeners();
      }
      return r.error;
    }
    _failures = 0;
    _user = r.value;
    notifyListeners();
    return null;
  }

  Future<AppException?> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final r = await guard(() async {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash(password, salt);
      final user = await _users.create(
        email: email.trim().toLowerCase(),
        displayName: displayName.trim(),
        passwordHash: hash,
        salt: salt,
      );
      await _session.save(user.id);
      return user;
    });
    if (!r.isSuccess) {
      if (r.error!.type == AppErrorType.duplicate) {
        return AppException.duplicate('このメールアドレスは既に登録されています');
      }
      if (r.error!.type == AppErrorType.database) {
        return AppException.database('登録に失敗しました。時間をおいて再度お試しください');
      }
      return r.error;
    }
    _user = r.value;
    notifyListeners();
    return null;
  }

  Future<void> logout({String? notice}) async {
    await guard(() => _session.clear());
    _user = null;
    _notice = notice;
    notifyListeners();
  }

  /// DBの最新状態を取得する。ユーザーが存在しなければ強制ログアウト。
  Future<AppException?> refreshUser() async {
    final u = _user;
    if (u == null) return AppException.authFailed();
    final r = await guard(() => _users.findById(u.id));
    if (!r.isSuccess) return r.error;
    if (r.value == null) {
      await logout(notice: '再度ログインしてください');
      return AppException.notFound('ユーザーが見つかりませんでした');
    }
    _user = r.value;
    notifyListeners();
    return null;
  }

  Future<AppException?> updateProfile({required String displayName, String? bio}) async {
    final u = _user;
    if (u == null) return AppException.authFailed();
    final r = await guard(() => _users.updateProfile(u.id, displayName: displayName.trim(), bio: bio));
    if (!r.isSuccess) return r.error;
    final cleanedBio = (bio == null || bio.trim().isEmpty) ? null : bio.trim();
    _user = User(
      id: u.id,
      email: u.email,
      displayName: displayName.trim(),
      bio: cleanedBio,
      createdAt: u.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return null;
  }

  Future<AppException?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final u = _user;
    if (u == null) return AppException.authFailed();
    final r = await guard(() async {
      final c = await _users.findCredentialById(u.id);
      if (c == null) throw AppException.notFound('ユーザーが見つかりませんでした');
      if (!PasswordHasher.verify(currentPassword, c.salt, c.passwordHash)) {
        throw AppException.validation('現在のパスワードが正しくありません');
      }
      final salt = PasswordHasher.generateSalt();
      await _users.updatePassword(u.id, PasswordHasher.hash(newPassword, salt), salt);
    });
    return r.isSuccess ? null : r.error;
  }
}

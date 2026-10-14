import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// パスワードをソルト付きSHA-256でハッシュ化する。平文は保存しない。
class PasswordHasher {
  PasswordHasher._();

  /// 16バイトのランダム値を16進文字列（32文字）で返す。
  static String generateSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// SHA-256（64文字の16進文字列）
  static String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  static bool verify(String password, String salt, String expectedHash) =>
      hash(password, salt) == expectedHash;
}

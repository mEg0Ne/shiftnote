import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'app_exception.dart';

/// 成功値または AppException を持つ結果型。
class Result<T> {
  final T? _value;
  final AppException? error;
  const Result._(this._value, this.error);

  factory Result.success(T value) => Result._(value, null);
  factory Result.failure(AppException error) => Result._(null, error);

  bool get isSuccess => error == null;
  T get value => _value as T;
}

/// 例外を捕捉して Result に変換する。画面側は try-catch を書かずに済む。
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } on AppException catch (e) {
    return Result.failure(e);
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) {
      return Result.failure(AppException.duplicate());
    }
    debugPrint('DatabaseException: $e');
    return Result.failure(AppException.database());
  } catch (e, st) {
    debugPrint('Unexpected error: $e\n$st');
    return Result.failure(AppException.unknown());
  }
}

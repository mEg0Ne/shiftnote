/// アプリ共通の例外。画面にはそのまま表示できる日本語メッセージを持つ。
enum AppErrorType {
  validation,
  duplicate,
  authFailed,
  locked,
  notFound,
  database,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message;
  const AppException(this.type, this.message);

  factory AppException.validation(String message) =>
      AppException(AppErrorType.validation, message);

  factory AppException.duplicate([String message = 'すでに登録されています']) =>
      AppException(AppErrorType.duplicate, message);

  factory AppException.authFailed() => const AppException(
      AppErrorType.authFailed, 'メールアドレスまたはパスワードが正しくありません');

  factory AppException.locked(int seconds) => AppException(
      AppErrorType.locked, 'ログインに複数回失敗しました。あと$seconds秒お待ちください');

  factory AppException.notFound([String message = '対象のデータが見つかりませんでした']) =>
      AppException(AppErrorType.notFound, message);

  factory AppException.overlap() => const AppException(
      AppErrorType.validation, '他のシフトと時間が重なっています');

  factory AppException.database([String message = '保存に失敗しました。もう一度お試しください']) =>
      AppException(AppErrorType.database, message);

  factory AppException.unknown() =>
      const AppException(AppErrorType.unknown, '問題が発生しました。時間をおいて再度お試しください');

  @override
  String toString() => 'AppException($type): $message';
}

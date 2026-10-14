/// 入力検証。TextFormField の validator からそのまま使える。
class Validators {
  Validators._();

  static String? required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$labelを入力してください' : null;

  static String? maxLength(String? v, int max, String label) =>
      (v != null && v.trim().length > max) ? '$labelは$max文字以内で入力してください' : null;

  static String? displayName(String? v) {
    final r = required(v, '表示名');
    if (r != null) return r;
    return maxLength(v, 20, '表示名');
  }

  static final RegExp _emailRe =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  static String? email(String? v) {
    final r = required(v, 'メールアドレス');
    if (r != null) return r;
    final t = v!.trim();
    if (t.length > 254 || !_emailRe.hasMatch(t)) {
      return 'メールアドレスの形式が正しくありません';
    }
    return null;
  }

  /// 8文字以上64文字以内、英字と数字を各1文字以上。
  static String? password(String? v) {
    final r = required(v, 'パスワード');
    if (r != null) return r;
    if (v!.length < 8) return 'パスワードは8文字以上で入力してください';
    if (v.length > 64) return 'パスワードは64文字以内で入力してください';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
      return 'パスワードは英字と数字を両方含めてください';
    }
    return null;
  }

  static String? confirm(String? v, String other) {
    final r = required(v, '確認用パスワード');
    if (r != null) return r;
    return v == other ? null : 'パスワードが一致しません';
  }

  static String? integerRange(String? v, int min, int max, String label) {
    final r = required(v, label);
    if (r != null) return r;
    final n = int.tryParse(v!.trim());
    if (n == null) return '$labelは整数で入力してください';
    if (n < min || n > max) return '$labelは$min〜$max の範囲で入力してください';
    return null;
  }
}

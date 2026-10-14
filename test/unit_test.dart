import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftnote/core/app_exception.dart';
import 'package:shiftnote/core/formatters.dart';
import 'package:shiftnote/core/password_hasher.dart';
import 'package:shiftnote/core/validators.dart';
import 'package:shiftnote/models/shift.dart';
import 'package:shiftnote/providers/shift_provider.dart';

void main() {
  group('Validators', () {
    test('メールアドレス', () {
      expect(Validators.email('taro@example.com'), isNull);
      expect(Validators.email('taro@'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('パスワードは8文字以上かつ英数字を含む', () {
      expect(Validators.password('abcd1234'), isNull);
      expect(Validators.password('abc123'), isNotNull); // 短い
      expect(Validators.password('abcdefgh'), isNotNull); // 数字なし
      expect(Validators.password('12345678'), isNotNull); // 英字なし
    });

    test('表示名は1〜20文字', () {
      expect(Validators.displayName('太郎'), isNull);
      expect(Validators.displayName(''), isNotNull);
      expect(Validators.displayName('あ' * 21), isNotNull);
    });

    test('整数の範囲', () {
      expect(Validators.integerRange('30', 0, 480, '休憩'), isNull);
      expect(Validators.integerRange('481', 0, 480, '休憩'), isNotNull);
      expect(Validators.integerRange('abc', 0, 480, '休憩'), isNotNull);
    });
  });

  group('PasswordHasher', () {
    test('同じソルトなら同じハッシュ、違うソルトなら別のハッシュ', () {
      final salt = PasswordHasher.generateSalt();
      expect(salt.length, 32);
      final h = PasswordHasher.hash('abcd1234', salt);
      expect(h.length, 64);
      expect(PasswordHasher.verify('abcd1234', salt, h), isTrue);
      expect(PasswordHasher.verify('abcd1235', salt, h), isFalse);
      expect(PasswordHasher.hash('abcd1234', PasswordHasher.generateSalt()), isNot(h));
    });
  });

  group('Shift', () {
    test('通常の勤務の実働時間', () {
      final r = Shift.range(DateTime(2026, 10, 8), const TimeOfDay(hour: 17, minute: 0),
          const TimeOfDay(hour: 22, minute: 0));
      final s = Shift(
          userId: 1, startAt: r.$1, endAt: r.$2, breakMinutes: 30, createdAt: r.$1, updatedAt: r.$1);
      expect(s.grossMinutes, 300);
      expect(s.workedMinutes, 270);
      expect(s.isOvernight, isFalse);
    });

    test('夜勤は翌日終了として扱う', () {
      final r = Shift.range(DateTime(2026, 10, 8), const TimeOfDay(hour: 22, minute: 0),
          const TimeOfDay(hour: 5, minute: 0));
      expect(r.$2, DateTime(2026, 10, 9, 5, 0));
    });

    test('DB保存用の日時文字列', () {
      expect(toIsoMinute(DateTime(2026, 10, 8, 9, 5)), '2026-10-08T09:05');
      expect(toIsoSecond(DateTime(2026, 10, 8, 9, 5, 7)), '2026-10-08T09:05:07');
    });

    test('時間の表示', () {
      expect(formatDuration(270), '4時間30分');
      expect(formatDuration(120), '2時間');
      expect(formatDuration(45), '45分');
    });
  });

  group('ShiftProvider.assertValid', () {
    test('開始と終了が同じ時刻はエラー', () {
      expect(
          () => ShiftProvider.assertValid(
              const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 9, minute: 0), 0),
          throwsA(isA<AppException>()));
    });

    test('休憩が拘束時間以上ならエラー', () {
      expect(
          () => ShiftProvider.assertValid(
              const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 10, minute: 0), 60),
          throwsA(isA<AppException>()));
    });

    test('正しい入力はエラーにならない', () {
      ShiftProvider.assertValid(
          const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 18, minute: 0), 60);
    });
  });
}

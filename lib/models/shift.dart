import 'package:flutter/material.dart';

import '../core/formatters.dart';

enum ShiftStatus {
  planned(0, '予定'),
  done(1, '出勤済み');

  final int code;
  final String label;
  const ShiftStatus(this.code, this.label);

  static ShiftStatus fromCode(int code) =>
      ShiftStatus.values.firstWhere((s) => s.code == code, orElse: () => ShiftStatus.planned);
}

class Shift {
  final int? id;
  final int userId;
  final DateTime startAt;
  final DateTime endAt;
  final int breakMinutes;
  final ShiftStatus status;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Shift({
    this.id,
    required this.userId,
    required this.startAt,
    required this.endAt,
    this.breakMinutes = 0,
    this.status = ShiftStatus.planned,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 拘束時間（分）
  int get grossMinutes => endAt.difference(startAt).inMinutes;

  /// 実働時間（分）＝ 拘束時間 − 休憩
  int get workedMinutes => grossMinutes - breakMinutes;

  bool get isOvernight => endAt.day != startAt.day || endAt.month != startAt.month;

  DateTime get date => DateTime(startAt.year, startAt.month, startAt.day);

  /// 勤務日と開始・終了時刻から開始日時・終了日時を作る。
  /// 終了が開始より前（または同時刻）なら翌日終了（夜勤）として扱う。
  static (DateTime, DateTime) range(DateTime date, TimeOfDay start, TimeOfDay end) {
    final s = DateTime(date.year, date.month, date.day, start.hour, start.minute);
    var e = DateTime(date.year, date.month, date.day, end.hour, end.minute);
    if (!e.isAfter(s)) {
      e = DateTime(date.year, date.month, date.day + 1, end.hour, end.minute);
    }
    return (s, e);
  }

  factory Shift.fromMap(Map<String, Object?> m) => Shift(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        startAt: DateTime.parse(m['start_at'] as String),
        endAt: DateTime.parse(m['end_at'] as String),
        breakMinutes: m['break_minutes'] as int,
        status: ShiftStatus.fromCode(m['status'] as int),
        memo: m['memo'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'start_at': toIsoMinute(startAt),
        'end_at': toIsoMinute(endAt),
        'break_minutes': breakMinutes,
        'status': status.code,
        'memo': (memo == null || memo!.trim().isEmpty) ? null : memo!.trim(),
        'created_at': toIsoSecond(createdAt),
        'updated_at': toIsoSecond(updatedAt),
      };

  Shift copyWith({
    DateTime? startAt,
    DateTime? endAt,
    int? breakMinutes,
    ShiftStatus? status,
    String? memo,
    DateTime? updatedAt,
  }) =>
      Shift(
        id: id,
        userId: userId,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        breakMinutes: breakMinutes ?? this.breakMinutes,
        status: status ?? this.status,
        memo: memo ?? this.memo,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 月間集計（S06）
class MonthlySummary {
  final int totalMinutes;
  final int days;
  final int doneCount;
  final int doneMinutes;
  final int plannedCount;
  final int plannedMinutes;

  /// 今年の月ごとの合計実働時間（時間）。要素数は12。
  final List<double> yearHours;

  const MonthlySummary({
    required this.totalMinutes,
    required this.days,
    required this.doneCount,
    required this.doneMinutes,
    required this.plannedCount,
    required this.plannedMinutes,
    required this.yearHours,
  });
}

/// 今年の勤務実績（S07）。出勤済みのシフトのみ集計。
class YearStats {
  final int days;
  final int minutes;
  const YearStats({required this.days, required this.minutes});
}

/// シフト保存結果（繰り返し登録でスキップした日付を持つ）
class SaveOutcome {
  final int inserted;
  final List<DateTime> skipped;
  const SaveOutcome({required this.inserted, this.skipped = const []});
}

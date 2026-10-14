import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/formatters.dart';
import '../core/result.dart';
import '../data/shift_repository.dart';
import '../models/shift.dart';

enum LoadState { idle, loading, loaded, error }

/// シフトの閲覧・登録・更新・削除・集計を管理する。
class ShiftProvider extends ChangeNotifier {
  ShiftProvider(this._repo, this._userId);

  final ShiftRepository _repo;
  final int? Function() _userId;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = _dateOnly(DateTime.now());
  final Map<String, List<Shift>> _byDay = {};
  LoadState _state = LoadState.idle;
  String? _error;

  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  LoadState get state => _state;
  String? get errorMessage => _error;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Shift> shiftsOf(DateTime day) => _byDay[dayKey(day)] ?? const [];

  List<Shift> get selectedDayShifts => shiftsOf(_selectedDay);

  void reset() {
    _byDay.clear();
    _focusedDay = DateTime.now();
    _selectedDay = _dateOnly(DateTime.now());
    _state = LoadState.idle;
    _error = null;
    notifyListeners();
  }

  void selectDay(DateTime selected, DateTime focused) {
    _selectedDay = _dateOnly(selected);
    _focusedDay = focused;
    notifyListeners();
  }

  Future<void> changeMonth(DateTime focused) async {
    _focusedDay = focused;
    await loadMonth();
  }

  /// 表示中の月のシフトを取得する。
  Future<void> loadMonth() async {
    final uid = _userId();
    if (uid == null) return;
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    final from = DateTime(_focusedDay.year, _focusedDay.month);
    final to = DateTime(_focusedDay.year, _focusedDay.month + 1);
    final r = await guard(() => _repo.findBetween(uid, from, to));
    if (r.isSuccess) {
      _byDay.clear();
      for (final s in r.value) {
        _byDay.putIfAbsent(dayKey(s.startAt), () => []).add(s);
      }
      _state = LoadState.loaded;
    } else {
      _state = LoadState.error;
      _error = r.error!.message;
    }
    notifyListeners();
  }

  int _requireUser() {
    final uid = _userId();
    if (uid == null) throw AppException.unknown();
    return uid;
  }

  /// 入力値の整合性を検証する。問題があれば AppException を投げる。
  static void assertValid(TimeOfDay start, TimeOfDay end, int breakMinutes) {
    if (start.hour == end.hour && start.minute == end.minute) {
      throw AppException.validation('終了時刻は開始時刻と異なる時刻にしてください');
    }
    if (breakMinutes < 0 || breakMinutes > 480) {
      throw AppException.validation('休憩は0〜480分の範囲で入力してください');
    }
    final r = Shift.range(DateTime(2000), start, end);
    final gross = r.$2.difference(r.$1).inMinutes;
    if (breakMinutes >= gross) {
      throw AppException.validation('休憩は実働時間より短くしてください');
    }
  }

  Future<Result<Shift?>> getShift(int id) => guard(() async {
        final uid = _requireUser();
        return _repo.findById(uid, id);
      });

  /// 新規登録。repeatWeekdays があれば勤務日から4週間分を対象に複数件登録する。
  Future<Result<SaveOutcome>> create({
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required int breakMinutes,
    String? memo,
    Set<int>? repeatWeekdays,
  }) =>
      guard(() async {
        final uid = _requireUser();
        assertValid(start, end, breakMinutes);
        final dates = <DateTime>[];
        if (repeatWeekdays == null || repeatWeekdays.isEmpty) {
          dates.add(_dateOnly(date));
        } else {
          for (var i = 0; i < 28; i++) {
            final d = DateTime(date.year, date.month, date.day + i);
            if (repeatWeekdays.contains(d.weekday)) dates.add(d);
          }
        }
        final now = DateTime.now();
        final valid = <Shift>[];
        final skipped = <DateTime>[];
        for (final d in dates) {
          final r = Shift.range(d, start, end);
          if (await _repo.hasOverlap(uid, r.$1, r.$2)) {
            skipped.add(d);
          } else {
            valid.add(Shift(
              userId: uid,
              startAt: r.$1,
              endAt: r.$2,
              breakMinutes: breakMinutes,
              memo: memo,
              createdAt: now,
              updatedAt: now,
            ));
          }
        }
        if (valid.isEmpty) {
          throw dates.length == 1
              ? AppException.overlap()
              : AppException.validation('すべての日で他のシフトと時間が重なっているため、登録できませんでした');
        }
        await _repo.insertAll(valid);
        await loadMonth();
        return SaveOutcome(inserted: valid.length, skipped: skipped);
      });

  Future<Result<void>> updateShift({
    required Shift original,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required int breakMinutes,
    String? memo,
  }) =>
      guard(() async {
        final uid = _requireUser();
        assertValid(start, end, breakMinutes);
        final r = Shift.range(date, start, end);
        if (await _repo.hasOverlap(uid, r.$1, r.$2, excludeId: original.id)) {
          throw AppException.overlap();
        }
        await _repo.update(Shift(
          id: original.id,
          userId: uid,
          startAt: r.$1,
          endAt: r.$2,
          breakMinutes: breakMinutes,
          status: original.status,
          memo: memo,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
        ));
        await loadMonth();
      });

  Future<Result<void>> setStatus(int id, ShiftStatus status) => guard(() async {
        await _repo.updateStatus(_requireUser(), id, status);
        await loadMonth();
      });

  Future<Result<void>> deleteShift(int id) => guard(() async {
        await _repo.delete(_requireUser(), id);
        await loadMonth();
      });

  /// 月間集計（S06）
  Future<Result<MonthlySummary>> loadSummary(DateTime month) => guard(() async {
        final uid = _requireUser();
        final all = await _repo.findBetween(uid, DateTime(month.year), DateTime(month.year + 1));
        final yearHours = List<double>.filled(12, 0);
        var total = 0, doneMin = 0, plannedMin = 0, doneCnt = 0, plannedCnt = 0;
        final days = <String>{};
        for (final s in all) {
          yearHours[s.startAt.month - 1] += s.workedMinutes / 60;
          if (s.startAt.month != month.month) continue;
          total += s.workedMinutes;
          days.add(dayKey(s.startAt));
          if (s.status == ShiftStatus.done) {
            doneMin += s.workedMinutes;
            doneCnt++;
          } else {
            plannedMin += s.workedMinutes;
            plannedCnt++;
          }
        }
        return MonthlySummary(
          totalMinutes: total,
          days: days.length,
          doneCount: doneCnt,
          doneMinutes: doneMin,
          plannedCount: plannedCnt,
          plannedMinutes: plannedMin,
          yearHours: yearHours,
        );
      });

  /// 今年の勤務実績（S07）。出勤済みのみ。
  Future<Result<YearStats>> loadYearStats(int year) => guard(() async {
        final uid = _requireUser();
        final all = await _repo.findBetween(uid, DateTime(year), DateTime(year + 1));
        final days = <String>{};
        var minutes = 0;
        for (final s in all.where((s) => s.status == ShiftStatus.done)) {
          days.add(dayKey(s.startAt));
          minutes += s.workedMinutes;
        }
        return YearStats(days: days.length, minutes: minutes);
      });
}

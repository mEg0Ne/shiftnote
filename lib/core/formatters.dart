import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String two(int n) => n.toString().padLeft(2, '0');

/// yyyy-MM-dd（カレンダーの日付キー）
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';

/// DB保存用：yyyy-MM-ddTHH:mm
String toIsoMinute(DateTime d) => '${dayKey(d)}T${two(d.hour)}:${two(d.minute)}';

/// DB保存用：yyyy-MM-ddTHH:mm:ss
String toIsoSecond(DateTime d) => '${toIsoMinute(d)}:${two(d.second)}';

String nowIso() => toIsoSecond(DateTime.now());

String formatDuration(int minutes) {
  if (minutes <= 0) return '0分';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m分';
  if (m == 0) return '$h時間';
  return '$h時間$m分';
}

String formatTime(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

String formatTimeOfDay(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';

final DateFormat _dateFmt = DateFormat('yyyy年M月d日（E）', 'ja_JP');
String formatDate(DateTime d) => _dateFmt.format(d);

String formatMonth(DateTime d) => '${d.year}年${d.month}月';

String formatYmd(DateTime d) => '${d.year}/${two(d.month)}/${two(d.day)}';

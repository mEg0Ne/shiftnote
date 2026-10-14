import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../widgets/common.dart';
import '../widgets/monthly_bar_chart.dart';

/// S06 月間集計画面
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  MonthlySummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await context.read<ShiftProvider>().loadSummary(_month);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.isSuccess) {
        _summary = r.value;
      } else {
        _error = r.error!.message;
      }
    });
  }

  void _moveMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('月間集計')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _moveMonth(-1), tooltip: '前の月'),
                SizedBox(
                  width: 140,
                  child: Text(formatMonth(_month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _moveMonth(1), tooltip: '次の月'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const CenteredLoading()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _buildBody(_summary!),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MonthlySummary s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('合計実働時間', style: TextStyle(color: Colors.black54)),
                Text(formatDuration(s.totalMinutes),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Divider(height: 24),
                _row('勤務日数', '${s.days}日'),
                _row('出勤済み', '${s.doneCount}件 ／ ${formatDuration(s.doneMinutes)}'),
                _row('予定', '${s.plannedCount}件 ／ ${formatDuration(s.plannedMinutes)}'),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_month.year}年 月別の勤務時間（時間）', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                MonthlyBarChart(hours: s.yearHours, highlightMonth: _month.month),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 96, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value)),
        ]),
      );
}

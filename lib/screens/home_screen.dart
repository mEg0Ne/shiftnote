import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../widgets/common.dart';
import 'shift_detail_screen.dart';
import 'shift_edit_screen.dart';

/// S03 ホーム（カレンダー）画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ShiftProvider>().loadMonth();
    });
  }

  Future<void> _openDetail(Shift s) async {
    await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ShiftDetailScreen(shiftId: s.id!)));
    if (mounted) context.read<ShiftProvider>().loadMonth();
  }

  Future<void> _openNew() async {
    final p = context.read<ShiftProvider>();
    await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ShiftEditScreen(initialDate: p.selectedDay)));
    if (mounted) p.loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShiftProvider>();
    final shifts = p.selectedDayShifts;
    return Scaffold(
      appBar: AppBar(title: const Text('シフトノート')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNew,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'シフトを追加',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar<Shift>(
            locale: 'ja_JP',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: p.focusedDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: '月'},
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            selectedDayPredicate: (d) => isSameDay(d, p.selectedDay),
            eventLoader: p.shiftsOf,
            onDaySelected: (selected, focused) => p.selectDay(selected, focused),
            onPageChanged: (focused) => p.changeMonth(focused),
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: AppColors.line, shape: BoxShape.circle),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(formatDate(p.selectedDay),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(child: _buildList(p, shifts)),
        ],
      ),
    );
  }

  Widget _buildList(ShiftProvider p, List<Shift> shifts) {
    if (p.state == LoadState.loading && shifts.isEmpty) return const CenteredLoading();
    if (p.state == LoadState.error) {
      return ErrorView(message: p.errorMessage ?? '読み込みに失敗しました', onRetry: p.loadMonth);
    }
    if (shifts.isEmpty) {
      return const Center(child: Text('この日のシフトはありません'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      itemCount: shifts.length,
      itemBuilder: (_, i) {
        final s = shifts[i];
        final done = s.status == ShiftStatus.done;
        return Card(
          child: ListTile(
            onTap: () => _openDetail(s),
            title: Text('${formatTime(s.startAt)} – ${formatTime(s.endAt)}${s.isOvernight ? '（翌日）' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('実働 ${formatDuration(s.workedMinutes)}'
                '${(s.memo ?? '').isEmpty ? '' : '\n${s.memo}'}'),
            isThreeLine: (s.memo ?? '').isNotEmpty,
            trailing: Chip(
              label: Text(s.status.label, style: TextStyle(color: done ? Colors.white : AppColors.primary, fontSize: 12)),
              backgroundColor: done ? AppColors.primary : Colors.white,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../widgets/common.dart';
import 'shift_edit_screen.dart';

/// S05 シフト詳細画面
class ShiftDetailScreen extends StatefulWidget {
  final int shiftId;
  const ShiftDetailScreen({super.key, required this.shiftId});
  @override
  State<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends State<ShiftDetailScreen> {
  Shift? _shift;
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
    final r = await context.read<ShiftProvider>().getShift(widget.shiftId);
    if (!mounted) return;
    if (!r.isSuccess) {
      setState(() {
        _loading = false;
        _error = r.error!.message;
      });
      return;
    }
    if (r.value == null) {
      showSnack(context, 'このシフトは見つかりませんでした');
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _shift = r.value;
      _loading = false;
    });
  }

  Future<void> _edit() async {
    final s = _shift;
    if (s == null) return;
    final changed = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => ShiftEditScreen(shift: s)));
    if (changed == true && mounted) _load();
  }

  Future<void> _delete() async {
    final s = _shift;
    if (s == null || _busy) return;
    final ok = await showConfirmDialog(context,
        title: 'シフトの削除', message: 'このシフトを削除します。よろしいですか？', confirmLabel: '削除');
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    final r = await context.read<ShiftProvider>().deleteShift(s.id!);
    if (!mounted) return;
    if (!r.isSuccess) {
      setState(() => _busy = false);
      showSnack(context, r.error!.message);
      return;
    }
    showSnack(context, '削除しました');
    Navigator.pop(context, true);
  }

  Future<void> _toggleStatus(bool done) async {
    final s = _shift;
    if (s == null || _busy) return;
    if (done && s.startAt.isAfter(DateTime.now())) {
      final ok = await showConfirmDialog(context,
          title: '出勤済みにしますか？', message: 'まだ勤務日になっていません。出勤済みにしますか？', confirmLabel: '出勤済みにする');
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    final r = await context
        .read<ShiftProvider>()
        .setStatus(s.id!, done ? ShiftStatus.done : ShiftStatus.planned);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!r.isSuccess) {
      showSnack(context, r.error!.message); // スイッチは変更前の状態のまま
      return;
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _shift;
    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト詳細'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), tooltip: '編集', onPressed: s == null ? null : _edit),
          IconButton(icon: const Icon(Icons.delete), tooltip: '削除', onPressed: s == null ? null : _delete),
        ],
      ),
      body: _loading
          ? const CenteredLoading()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(s!),
    );
  }

  Widget _buildBody(Shift s) {
    final done = s.status == ShiftStatus.done;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatDate(s.date), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${formatTime(s.startAt)} – ${formatTime(s.endAt)}${s.isOvernight ? '（翌日終了）' : ''}',
                    style: const TextStyle(fontSize: 22, color: AppColors.primary)),
                const Divider(height: 24),
                _row('休憩', formatDuration(s.breakMinutes)),
                _row('実働時間', formatDuration(s.workedMinutes)),
                _row('状態', s.status.label),
                if ((s.memo ?? '').isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('メモ', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(s.memo!),
                ],
              ],
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            title: const Text('出勤済み'),
            value: done,
            onChanged: _busy ? null : _toggleStatus,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _edit, child: const Text('実績を修正する')),
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

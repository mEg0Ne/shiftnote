import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/validators.dart';
import '../models/shift.dart';
import '../providers/shift_provider.dart';
import '../widgets/common.dart';

/// S04 シフト登録・編集画面（shift が null なら新規）
class ShiftEditScreen extends StatefulWidget {
  final Shift? shift;
  final DateTime? initialDate;
  const ShiftEditScreen({super.key, this.shift, this.initialDate});

  @override
  State<ShiftEditScreen> createState() => _ShiftEditScreenState();
}

class _ShiftEditScreenState extends State<ShiftEditScreen> {
  static const _weekdayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  final _break = TextEditingController(text: '0');
  final _memo = TextEditingController();
  bool _repeat = false;
  final Set<int> _weekdays = {};
  String? _startError;
  String? _endError;
  String? _weekdayError;
  String? _generalError;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEdit => widget.shift != null;

  @override
  void initState() {
    super.initState();
    final s = widget.shift;
    if (s != null) {
      _date = s.date;
      _start = TimeOfDay(hour: s.startAt.hour, minute: s.startAt.minute);
      _end = TimeOfDay(hour: s.endAt.hour, minute: s.endAt.minute);
      _break.text = s.breakMinutes.toString();
      _memo.text = s.memo ?? '';
    } else {
      final d = widget.initialDate ?? DateTime.now();
      _date = DateTime(d.year, d.month, d.day);
    }
  }

  @override
  void dispose() {
    _break.dispose();
    _memo.dispose();
    super.dispose();
  }

  int? get _grossMinutes {
    if (_start == null || _end == null) return null;
    if (_start == _end) return null;
    final r = Shift.range(_date, _start!, _end!);
    return r.$2.difference(r.$1).inMinutes;
  }

  String get _preview {
    final gross = _grossMinutes;
    if (gross == null) return '実働 -';
    final br = int.tryParse(_break.text.trim()) ?? 0;
    final worked = gross - br;
    if (worked <= 0) return '実働 -';
    final over = Shift.range(_date, _start!, _end!).$2.day != _date.day ? '（翌日終了）' : '';
    return '実働 ${formatDuration(worked)}$over';
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '勤務日を選択',
    );
    if (d != null) setState(() {
      _date = d;
      _dirty = true;
    });
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial, String help) => showTimePicker(
        context: context,
        initialTime: initial,
        helpText: help,
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );

  Future<void> _pickStart() async {
    final t = await _pickTime(_start ?? const TimeOfDay(hour: 9, minute: 0), '開始時刻を選択');
    if (t != null) setState(() {
      _start = t;
      _startError = null;
      _dirty = true;
    });
  }

  Future<void> _pickEnd() async {
    final t = await _pickTime(_end ?? const TimeOfDay(hour: 18, minute: 0), '終了時刻を選択');
    if (t != null) setState(() {
      _end = t;
      _endError = null;
      _dirty = true;
    });
  }

  String? _breakValidator(String? v) {
    final base = Validators.integerRange(v, 0, 480, '休憩');
    if (base != null) return base;
    final gross = _grossMinutes;
    if (gross != null && int.parse(v!.trim()) >= gross) return '休憩は実働時間より短くしてください';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _generalError = null;
      _startError = _start == null ? '開始時刻を選択してください' : null;
      _endError = _end == null
          ? '終了時刻を選択してください'
          : (_start != null && _start == _end ? '終了時刻は開始時刻と異なる時刻にしてください' : null);
      _weekdayError = (_repeat && _weekdays.isEmpty) ? '曜日を1つ以上選択してください' : null;
    });
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _startError != null || _endError != null || _weekdayError != null) return;

    setState(() => _saving = true);
    final p = context.read<ShiftProvider>();
    final breakMin = int.parse(_break.text.trim());
    final memo = _memo.text.trim().isEmpty ? null : _memo.text.trim();

    if (_isEdit) {
      final r = await p.updateShift(
        original: widget.shift!,
        date: _date,
        start: _start!,
        end: _end!,
        breakMinutes: breakMin,
        memo: memo,
      );
      if (!mounted) return;
      if (!r.isSuccess) {
        setState(() {
          _saving = false;
          _generalError = r.error!.message;
        });
        return;
      }
      showSnack(context, '保存しました');
      Navigator.pop(context, true);
      return;
    }

    final r = await p.create(
      date: _date,
      start: _start!,
      end: _end!,
      breakMinutes: breakMin,
      memo: memo,
      repeatWeekdays: _repeat ? _weekdays : null,
    );
    if (!mounted) return;
    if (!r.isSuccess) {
      setState(() {
        _saving = false;
        _generalError = r.error!.message;
      });
      return;
    }
    final outcome = r.value;
    if (outcome.skipped.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${outcome.inserted}件を登録しました'),
          content: Text('他のシフトと時間が重なるため、次の日はスキップしました。\n\n'
              '${outcome.skipped.map(formatYmd).join('\n')}'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
    } else {
      showSnack(context, outcome.inserted > 1 ? '${outcome.inserted}件を登録しました' : '保存しました');
    }
    Navigator.pop(context, true);
  }

  Future<void> _confirmDiscard() async {
    final ok = await showConfirmDialog(context,
        title: '入力内容を破棄しますか？', message: '入力した内容は保存されません。', confirmLabel: '破棄する');
    if (ok && mounted) Navigator.pop(context, false);
  }

  Widget _pickerField({
    required String label,
    required String? value,
    required VoidCallback onTap,
    String? error,
    IconData icon = Icons.access_time,
  }) =>
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, errorText: error, suffixIcon: Icon(icon)),
          child: Text(value ?? '選択してください'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'シフト編集' : 'シフト登録')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorText(_generalError),
                  _pickerField(
                      label: '勤務日', value: formatDate(_date), onTap: _pickDate, icon: Icons.calendar_today),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _pickerField(
                            label: '開始時刻',
                            value: _start == null ? null : formatTimeOfDay(_start!),
                            onTap: _pickStart,
                            error: _startError)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _pickerField(
                            label: '終了時刻',
                            value: _end == null ? null : formatTimeOfDay(_end!),
                            onTap: _pickEnd,
                            error: _endError)),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _break,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    decoration: const InputDecoration(labelText: '休憩（分）', counterText: ''),
                    validator: _breakValidator,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(_preview, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (!_isEdit) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('繰り返し（勤務日から4週間分）'),
                      value: _repeat,
                      onChanged: (v) => setState(() {
                        _repeat = v;
                        _dirty = true;
                        if (!v) _weekdayError = null;
                      }),
                    ),
                    if (_repeat) ...[
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (i) {
                          final wd = i + 1; // DateTime.monday = 1
                          return FilterChip(
                            label: Text(_weekdayLabels[i]),
                            selected: _weekdays.contains(wd),
                            onSelected: (sel) => setState(() {
                              sel ? _weekdays.add(wd) : _weekdays.remove(wd);
                              _weekdayError = null;
                            }),
                          );
                        }),
                      ),
                      if (_weekdayError != null) ErrorText(_weekdayError),
                    ],
                    const SizedBox(height: 8),
                  ],
                  TextFormField(
                    controller: _memo,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: 'メモ（任意）'),
                    validator: (v) => Validators.maxLength(v, 200, 'メモ'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

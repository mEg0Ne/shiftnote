import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../models/shift.dart';
import '../providers/auth_provider.dart';
import '../providers/shift_provider.dart';
import '../widgets/common.dart';
import 'password_change_screen.dart';
import 'profile_edit_screen.dart';

/// S07 マイページ画面
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  YearStats? _stats;
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
    final auth = context.read<AuthProvider>();
    final shifts = context.read<ShiftProvider>();
    // ユーザーが存在しない場合は強制ログアウトされる
    final userErr = await auth.refreshUser();
    if (!mounted) return;
    if (auth.currentUser == null) return;
    final r = await shifts.loadYearStats(DateTime.now().year);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (userErr != null) {
        _error = userErr.message;
      } else if (r.isSuccess) {
        _stats = r.value;
      } else {
        _error = r.error!.message;
      }
    });
  }

  Future<void> _logout() async {
    final ok = await showConfirmDialog(context,
        title: 'ログアウト', message: 'ログアウトします。よろしいですか？', confirmLabel: 'はい', cancelLabel: 'いいえ');
    if (!ok || !mounted) return;
    context.read<ShiftProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: user == null
          ? const SizedBox.shrink()
          : _loading
              ? const CenteredLoading()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.displayName,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(user.email, style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 12),
                                Text((user.bio ?? '').isEmpty ? '自己紹介：未設定' : user.bio!),
                                const SizedBox(height: 12),
                                Text('登録日：${formatYmd(user.createdAt)}',
                                    style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                                Text('${DateTime.now().year}年の勤務実績（出勤済み）',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(child: _stat('勤務日数', '${_stats?.days ?? 0}日')),
                                  Expanded(child: _stat('合計実働時間', formatDuration(_stats?.minutes ?? 0))),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          child: Column(children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('プロフィール編集'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.push(
                                    context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                                if (mounted) _load();
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.lock),
                              title: const Text('パスワード変更'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                  context, MaterialPageRoute(builder: (_) => const PasswordChangeScreen())),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.logout, color: AppColors.error),
                              title: const Text('ログアウト', style: TextStyle(color: AppColors.error)),
                              onTap: _logout,
                            ),
                          ]),
                        ),
                      ],
                    ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      );
}

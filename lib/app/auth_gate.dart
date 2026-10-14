import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';

/// 起動時のルート。ログイン状態に応じて S01（ログイン）か S03 以降を表示する。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _wasLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.currentUser == null) {
      if (_wasLoggedIn) {
        // ログアウトや強制ログアウト時だけ、積まれている画面を閉じてログインへ戻す
        _wasLoggedIn = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        });
      }
      return const LoginScreen();
    }
    _wasLoggedIn = true;
    return const MainShell();
  }
}

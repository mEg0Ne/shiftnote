import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';
import 'register_screen.dart';

/// S01 ログイン画面
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _error = context.read<AuthProvider>().takeNotice();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _watchLock(AuthProvider auth) {
    _lockTimer?.cancel();
    if (!auth.isLocked) return;
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !auth.isLocked) {
        t.cancel();
        if (mounted) setState(() => _error = null);
        return;
      }
      setState(() {});
    });
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    if (_busy || auth.isLocked) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await auth.login(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err?.message;
    });
    _watchLock(auth);
    // 成功時は AuthGate が S03 へ切り替える
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locked = auth.isLocked;
    final lockMessage = locked ? 'ログインを一時的に制限しています。あと${auth.lockRemainingSeconds}秒お待ちください' : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('シフトノート',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('アルバイトの日程と勤務時間を管理', textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    ErrorText(lockMessage ?? _error),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'メールアドレス'),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _password,
                      label: 'パスワード',
                      validator: (v) => Validators.required(v, 'パスワード'),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: (_busy || locked) ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('ログイン'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('新規登録'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

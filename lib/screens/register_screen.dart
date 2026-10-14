import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';

/// S02 ユーザー登録画面
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  bool get _dirty =>
      _name.text.isNotEmpty || _email.text.isNotEmpty || _password.text.isNotEmpty || _confirm.text.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await context
        .read<AuthProvider>()
        .register(displayName: _name.text, email: _email.text, password: _password.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err.message;
      });
      return;
    }
    // 登録成功：自動ログイン済み。ログイン画面まで戻ると AuthGate が S03 を表示する。
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _back() async {
    if (_dirty) {
      final ok = await showConfirmDialog(context,
          title: '入力内容を破棄しますか？', message: '入力した内容は保存されません。', confirmLabel: '破棄する');
      if (!ok) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('ユーザー登録')),
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
                      ErrorText(_error),
                      TextFormField(
                        controller: _name,
                        maxLength: 20,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: '表示名（20文字以内）', counterText: ''),
                        validator: Validators.displayName,
                      ),
                      const SizedBox(height: 16),
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
                        label: 'パスワード（8文字以上・英字と数字）',
                        validator: Validators.password,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirm,
                        label: 'パスワード（確認）',
                        validator: (v) => Validators.confirm(v, _password.text),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _busy ? null : _register,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('登録'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _busy ? null : _back, child: const Text('ログインへ戻る')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

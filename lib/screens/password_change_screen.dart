import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';

/// S09 パスワード変更画面
class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});
  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _newValidator(String? v) {
    final base = Validators.password(v);
    if (base != null) return base;
    if (v == _current.text) return '新しいパスワードは現在のパスワードと異なるものにしてください';
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await context
        .read<AuthProvider>()
        .changePassword(currentPassword: _current.text, newPassword: _new.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err.message;
      });
      return;
    }
    showSnack(context, '変更しました');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パスワード変更')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorText(_error),
                PasswordField(
                  controller: _current,
                  label: '現在のパスワード',
                  validator: (v) => Validators.required(v, '現在のパスワード'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _new,
                  label: '新しいパスワード（8文字以上・英字と数字）',
                  validator: _newValidator,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: '新しいパスワード（確認）',
                  validator: (v) => Validators.confirm(v, _new.text),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('変更'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

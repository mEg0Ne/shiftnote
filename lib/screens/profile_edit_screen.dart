import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';

/// S08 プロフィール編集画面
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final String _initialName;
  late final String _initialBio;
  String? _error;
  bool _busy = false;

  bool get _dirty => _name.text != _initialName || _bio.text != _initialBio;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().currentUser!;
    _initialName = u.displayName;
    _initialBio = u.bio ?? '';
    _name = TextEditingController(text: _initialName);
    _bio = TextEditingController(text: _initialBio);
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await context.read<AuthProvider>().updateProfile(displayName: _name.text, bio: _bio.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err.message;
      });
      return;
    }
    showSnack(context, '更新しました');
    Navigator.pop(context);
  }

  Future<void> _cancel() async {
    if (_dirty) {
      final ok = await showConfirmDialog(context,
          title: '変更を破棄しますか？', message: '変更した内容は保存されません。', confirmLabel: '破棄する');
      if (!ok) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('プロフィール編集')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorText(_error),
                  TextFormField(
                    controller: _name,
                    maxLength: 20,
                    decoration: const InputDecoration(labelText: '表示名', counterText: ''),
                    validator: Validators.displayName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bio,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '自己紹介（任意）'),
                    validator: (v) => Validators.maxLength(v, 200, '自己紹介'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _busy ? null : _cancel, child: const Text('キャンセル')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

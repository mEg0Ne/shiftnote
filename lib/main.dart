import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app_theme.dart';
import 'app/auth_gate.dart';
import 'data/app_database.dart';
import 'data/session_store.dart';
import 'data/shift_repository.dart';
import 'data/user_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/shift_provider.dart';

Future<void> main() async {
  // 想定外の例外を捕捉して、アプリが落ちないようにする
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ja_JP');
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    };
    ErrorWidget.builder = (details) => const _FallbackError();
    runApp(const ShiftNoteApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class ShiftNoteApp extends StatefulWidget {
  const ShiftNoteApp({super.key});
  @override
  State<ShiftNoteApp> createState() => _ShiftNoteAppState();
}

class _ShiftNoteAppState extends State<ShiftNoteApp> {
  late final AppDatabase _db = AppDatabase();
  late final UserRepository _userRepo = UserRepository(_db);
  late final ShiftRepository _shiftRepo = ShiftRepository(_db);
  late final SessionStore _session = SessionStore();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(_userRepo, _session)..restore(),
        ),
        ChangeNotifierProvider<ShiftProvider>(
          create: (ctx) => ShiftProvider(_shiftRepo, () => ctx.read<AuthProvider>().currentUser?.id),
        ),
      ],
      child: MaterialApp(
        title: 'シフトノート',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('ja', 'JP'),
        supportedLocales: const [Locale('ja', 'JP')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AuthGate(),
      ),
    );
  }
}

class _FallbackError extends StatelessWidget {
  const _FallbackError();
  @override
  Widget build(BuildContext context) => const Material(
        color: AppColors.background,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('問題が発生しました。画面を戻るか、アプリを再起動してください。',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
          ),
        ),
      );
}

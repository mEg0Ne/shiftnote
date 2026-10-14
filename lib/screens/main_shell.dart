import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'mypage_screen.dart';
import 'summary_screen.dart';

/// 下部ナビゲーション（ホーム／集計／マイページ）
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // タブを切り替えるたびに作り直し、集計やマイページを常に最新にする
    final pages = <Widget>[
      const HomeScreen(key: ValueKey('home')),
      const SummaryScreen(key: ValueKey('summary')),
      const MyPageScreen(key: ValueKey('mypage')),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '集計'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// 1〜12月の勤務時間を棒グラフで表示する（外部パッケージ不使用）。
class MonthlyBarChart extends StatelessWidget {
  final List<double> hours;
  final int highlightMonth;
  const MonthlyBarChart({super.key, required this.hours, required this.highlightMonth});

  @override
  Widget build(BuildContext context) {
    final maxH = hours.fold<double>(0, (m, v) => v > m ? v : m);
    const chartHeight = 140.0;
    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final v = i < hours.length ? hours[i] : 0.0;
          final h = maxH <= 0 ? 0.0 : (v / maxH) * chartHeight;
          final selected = i + 1 == highlightMonth;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(v == 0 ? '' : v.toStringAsFixed(v >= 10 ? 0 : 1), style: const TextStyle(fontSize: 9)),
                const SizedBox(height: 2),
                Container(
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: selected ? AppColors.primary : AppColors.line,
                ),
                const SizedBox(height: 4),
                Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

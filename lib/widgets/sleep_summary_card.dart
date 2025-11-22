// lib/widgets/sleep_summary_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import './data_chart.dart'; // Corrected import path
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class SleepSummaryCard extends StatelessWidget {
  final List<FlSpot> dummyData = [
    const FlSpot(0, 0),
    const FlSpot(1, 1),
    const FlSpot(2, 2),
    const FlSpot(3, 1),
    const FlSpot(4, 0),
    const FlSpot(5, 1),
    const FlSpot(6, 2),
    const FlSpot(7, 1),
  ];

  SleepSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 카드 상단 내용
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('수면 요약', style: AppTextStyles.heading3),
                const Icon(Icons.info_outline, color: AppColors.secondaryText),
              ],
            ),
            const SizedBox(height: 16),
            // DataChart 위젯 사용
            SizedBox(
              height: 200, // 그래프 높이
              child: DataChart(
                chartData: dummyData, // <-- This is where you pass the data
                chartTitle: '수면 단계', // <-- This is where you pass the title
              ),
            ),
            const SizedBox(height: 16),
            // 추가적인 요약 정보
            Text(
              '오늘은 평균보다 깊은 잠을 더 많이 잤습니다.',
              style: AppTextStyles.secondaryBodyText,
            ),
          ],
        ),
      ),
    );
  }
}

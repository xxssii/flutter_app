// lib/widgets/data_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class DataChart extends StatelessWidget {
  final List<FlSpot> chartData;
  final String chartTitle;

  const DataChart({
    super.key,
    required this.chartData,
    required this.chartTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(chartTitle, style: AppTextStyles.heading3),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      switch (value.toInt()) {
                        case 0:
                          text = '12AM';
                          break;
                        case 3:
                          text = '3AM';
                          break;
                        case 6:
                          text = '6AM';
                          break;
                        default:
                          return const SizedBox.shrink();
                      }

                      // ✅ 수정됨: axisSide 에러 해결 -> meta 파라미터 사용
                      return SideTitleWidget(
                        meta: meta, // axisSide: meta.axisSide 대신 meta: meta 사용
                        space: 8.0,
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      switch (value.toInt()) {
                        case 0:
                          text = '얕은';
                          break;
                        case 1:
                          text = '렘';
                          break;
                        case 2:
                          text = '깊은';
                          break;
                        default:
                          return const SizedBox.shrink();
                      }
                      // 여기도 SideTitleWidget으로 감싸는 것이 안전하지만,
                      // 텍스트만 리턴해도 작동한다면 그대로 두셔도 됩니다.
                      return Text(
                        text,
                        style: const TextStyle(color: AppColors.secondaryText),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: AppColors.borderColor, strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    const FlLine(color: AppColors.borderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  color: AppColors.primaryNavy,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryNavy.withOpacity(0.5),
                        AppColors.primaryNavy.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

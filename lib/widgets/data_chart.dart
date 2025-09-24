// lib/widgets/data_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart'; // AppTextStyles를 import 합니다.

class DataChart extends StatelessWidget {
  final List<FlSpot> chartData;
  final String chartTitle;

  const DataChart({Key? key, required this.chartData, required this.chartTitle})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          // AppTextStyles의 heading3 스타일을 사용하여 제목을 표시합니다.
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
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
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
                  color: AppColors.accentNavy,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentNavy.withOpacity(0.5),
                        AppColors.accentNavy.withOpacity(0.0),
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

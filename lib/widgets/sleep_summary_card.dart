// lib/widgets/data_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_app/utils/app_colors.dart';

class DataChart extends StatelessWidget {
  const DataChart({super.key});

  @override
  Widget build(BuildContext context) {
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

    return LineChart(
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
                // The const keyword is removed here
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Text(
                    text,
                    style: const TextStyle(color: AppColors.secondaryText),
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
                // The const keyword is removed here
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
              const FlLine(color: AppColors.secondaryWhite, strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              const FlLine(color: AppColors.secondaryWhite, strokeWidth: 1),
        ),

        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.secondaryWhite, width: 1),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: dummyData,
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
    );
  }
}

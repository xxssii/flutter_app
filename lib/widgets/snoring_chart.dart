// lib/widgets/snoring_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/sleep_data_state.dart';

class SnoringChartSection extends StatelessWidget {
  const SnoringChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepDataState = Provider.of<SleepDataState>(context);
    final sleepMetrics = sleepDataState.todayMetrics;

    if (sleepMetrics == null || sleepMetrics.snoringDecibelData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text('코골이 데이터가 없습니다.', style: AppTextStyles.bodyText),
      );
    }

    // 데시벨 데이터의 최대/최소 범위 계산 (Y축 범위 설정용)
    double minDecibel = 30; // 최소 데시벨 하드코딩
    double maxDecibel = 90; // 최대 데시벨 하드코딩

    // FLChart 데이터 포인트 생성
    List<FlSpot> spots = sleepMetrics.snoringDecibelData.asMap().entries.map((
      entry,
    ) {
      int index = entry.key;
      SnoringDataPoint data = entry.value;
      // x 값은 0부터 시작하는 인덱스 (22시가 0, 06시가 48)
      // y 값은 데시벨
      return FlSpot(index.toDouble(), data.decibel);
    }).toList();

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.secondaryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // 아래 padding 0으로
        child: AspectRatio(
          aspectRatio: 1.7,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 10, // 10dB 간격으로 가로선
                verticalInterval: 6, // 약 1시간 간격 (10분*6 = 60분)
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.lightGrey.withOpacity(0.5),
                    strokeWidth: 0.5,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: AppColors.lightGrey.withOpacity(0.5),
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 12, // 2시간 간격으로 레이블 표시 (10분*12 = 120분)
                    getTitlesWidget: (value, meta) {
                      String hourText;
                      // 22시부터 6시까지
                      if (value == 0)
                        hourText = '22시';
                      else if (value == 6)
                        hourText = '23시';
                      else if (value == 12)
                        hourText = '0시';
                      else if (value == 18)
                        hourText = '1시';
                      else if (value == 24)
                        hourText = '2시';
                      else if (value == 30)
                        hourText = '3시';
                      else if (value == 36)
                        hourText = '4시';
                      else if (value == 42)
                        hourText = '5시';
                      else if (value == 48)
                        hourText = '6시';
                      else
                        return const SizedBox.shrink(); // 나머지 숨김

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8.0,
                        child: Text(hourText, style: AppTextStyles.smallText),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 10, // 10dB 간격으로 레이블
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: AppTextStyles.smallText,
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.lightGrey.withOpacity(0.5),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: AppColors.lightGrey.withOpacity(0.5),
                    width: 1,
                  ),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
              minX: 0,
              maxX: 48, // 49개 데이터 포인트 (0-48)
              minY: minDecibel,
              maxY: maxDecibel,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warningOrange, // 노란색 계열 시작
                      AppColors.warningOrange.withOpacity(0.6), // 노란색 계열 끝
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warningOrange.withOpacity(0.2), // 아래 영역 색상
                        AppColors.warningOrange.withOpacity(0),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ],
              // 코골이 기준점 (예: 50dB) 표시
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 50, // 50dB 이상부터 코골이로 간주하는 기준선
                    color: AppColors.warningOrange.withOpacity(0.7),
                    strokeWidth: 1,
                    dashArray: [5, 5], // 점선
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.warningOrange,
                      ),
                      // text 파라미터 대신 labelResolver를 사용합니다.
                      labelResolver: (line) {
                        return '코골이 기준 (50dB)';
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

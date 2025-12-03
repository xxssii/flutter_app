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
                    interval: 12, // 12개 데이터 = 60초 (1분)
                    getTitlesWidget: (value, meta) {
                      // 시연용: 5초 단위로 데이터가 들어옴
                      // value는 인덱스 (0, 1, 2...)
                      int seconds = value.toInt() * 5;
                      
                      // 60초 이상이면 분:초로 표시
                      String timeText;
                      if (seconds >= 60) {
                        int min = seconds ~/ 60;
                        int sec = seconds % 60;
                        timeText = '$min분${sec > 0 ? " $sec초" : ""}';
                      } else {
                        timeText = '${seconds}초';
                      }
                      
                      return SideTitleWidget(
                        meta: meta,
                        space: 8.0,
                        child: Text(timeText, style: AppTextStyles.smallText),
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
              maxX: (spots.length > 48) ? spots.length.toDouble() : 48.0, // 49개 데이터 포인트 (0-48)
              minY: minDecibel,
              maxY: maxDecibel,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: spots.length > 1,
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
                  dotData: FlDotData(show: spots.length == 1),
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
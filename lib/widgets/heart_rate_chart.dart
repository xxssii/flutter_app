// lib/widgets/heart_rate_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../state/sleep_data_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class HeartRateChartSection extends StatelessWidget {
  const HeartRateChartSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Provider로 데이터 가져오기
    final sleepDataState = Provider.of<SleepDataState>(context);
    final sleepMetrics = sleepDataState.todayMetrics;

    // 데이터가 없거나 비어있을 경우 처리
    if (sleepMetrics == null || sleepMetrics.heartRateData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text('심박수 데이터가 없습니다.', style: AppTextStyles.bodyText),
      );
    }

    // 그래프에 사용할 그라데이션 색상 (네이비 -> 연한 네이비 -> 투명)
    final List<Color> gradientColors = [
      AppColors.errorRed.withOpacity(0.5), // AppColors.errorRed는 빨간색 계열일 거야
      AppColors.errorRed.withOpacity(0.2), // 조금 더 연하게
      AppColors.errorRed.withOpacity(0.0), // 투명하게
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 그래프 제목
        Text('오늘의 수면 중 심박수 변화', style: AppTextStyles.heading3),
        const SizedBox(height: 20),

        // 2. 그래프 영역
        AspectRatio(
          aspectRatio: 1.70,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20, // 가로선 간격
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppColors.borderColor, strokeWidth: 1);
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
                    interval: 2, // 2시간 간격
                    getTitlesWidget: (value, meta) {
                      // X축 시간 표시 (임시 데이터 기준 0~8시간)
                      // 실제로는 시작 시간(예: 23:00)을 더해서 표시해야 함
                      int time = (22 + value.toInt()) % 24;
                      return SideTitleWidget(
                        meta: meta,
                        child: Text('${time}시', style: AppTextStyles.smallText),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20, // 20 BPM 간격
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: AppTextStyles.smallText,
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: AppColors.borderColor),
                  left: BorderSide(color: Colors.transparent),
                  right: BorderSide(color: Colors.transparent),
                  top: BorderSide(color: Colors.transparent),
                ),
              ),
              minX: 0,
              maxX: 8, // 8시간 수면 가정
              minY: 40, // 최소 심박수
              maxY: 100, // 최대 심박수
              lineBarsData: [
                LineChartBarData(
                  // ✅ 실제 심박수 데이터 사용
                  spots: sleepMetrics.heartRateData.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value);
                  }).toList(),
                  isCurved: true, // ✨ 부드러운 곡선 효과
                  color: AppColors.errorRed, // ✨ 선 색상도 빨간색 계열로 변경
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), // 점 숨기기 (깔끔하게)
                  belowBarData: BarAreaData(
                    show: true, // ✨ 그래프 아래 색칠하기
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 3. 해석 가이드 및 팁 (카드 형태)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withOpacity(0.05), // 연한 배경색
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryNavy.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primaryNavy,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '심박수 해석 가이드',
                    style: AppTextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildGuideText('• 그래프가 낮고 평평할수록 깊은 잠을 잘 잤다는 의미입니다.'),
              const SizedBox(height: 8),
              _buildGuideText(
                '• 그래프가 뾰족하게 튀어 오르는 구간은 꿈을 꾸거나(REM), 잠시 뒤척인 시간입니다.',
              ),
              const SizedBox(height: 8),
              _buildGuideText('• 평소보다 심박수가 높다면 스트레스나 카페인 섭취를 점검해보세요.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideText(String text) {
    return Text(
      text,
      style: AppTextStyles.secondaryBodyText.copyWith(height: 1.4),
    );
  }
}

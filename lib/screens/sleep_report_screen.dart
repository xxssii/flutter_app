// lib/screens/sleep_report_screen.dart

import 'package:flutter/material.dart';
import '../widgets/data_chart.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'package:provider/provider.dart'; // Provider 사용을 위해 추가
import '../state/sleep_data_state.dart'; // SleepDataState 추가

class SleepReportScreen extends StatelessWidget {
  const SleepReportScreen({Key? key})
    : super(key: key); // Make sure the constructor includes 'key'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 수면 리포트'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(context),
            const SizedBox(height: 20),
            _buildSleepScoreCard(context),
            const SizedBox(height: 20),
            _buildChartSection(
              context,
              '수면 주기 그래프',
              const DataChart(chartTitle: '수면 주기', chartData: []),
            ),
            const SizedBox(height: 20),
            _buildFeedbackSection(context),
            const SizedBox(height: 20),
            _buildRecommendationSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader(BuildContext context) {
    // Provider를 통해 SleepMetrics 데이터에 접근
    final metrics = Provider.of<SleepDataState>(context).todayMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metrics.reportDate, style: AppTextStyles.secondaryBodyText),
        const SizedBox(height: 5),
        Text(
          '총 수면 시간: ${metrics.totalSleepDuration}시간',
          style: AppTextStyles.heading1,
        ),
      ],
    );
  }

  Widget _buildSleepScoreCard(BuildContext context) {
    // Provider를 통해 SleepMetrics 데이터에 접근
    final metrics = Provider.of<SleepDataState>(context).todayMetrics;

    // Mock 데이터 기반 점수 계산 (SleepScoreAnalyzer 사용 필요)
    // 임시 점수로 85점 유지
    final score = 85;

    return Card(
      color: AppColors.secondaryWhite,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '총 수면 점수',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${score}점',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.successGreen,
                fontSize: 60,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '수면 효율: ${metrics.sleepEfficiency}%', // Mock 데이터 사용
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    String title,
    Widget chartWidget,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 15),
        chartWidget,
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    final metrics = Provider.of<SleepDataState>(context).todayMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('수면 분석 피드백', style: AppTextStyles.heading2),
        const SizedBox(height: 15),
        Card(
          color: AppColors.secondaryWhite,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 깊은 수면 시간: 총 수면 시간 * N3 비율
                _buildFeedbackItem(
                  Icons.bedtime,
                  '깊은 수면 시간',
                  '${(metrics.totalSleepDuration * (metrics.deepSleepRatio / 100)).toStringAsFixed(1)}시간',
                ),
                // REM 수면 시간: 총 수면 시간 * REM 비율
                _buildFeedbackItem(
                  Icons.airline_seat_legroom_extra,
                  '렘 수면 시간',
                  '${(metrics.totalSleepDuration * (metrics.remRatio / 100)).toStringAsFixed(1)}시간',
                ),
                // 얕은 수면 시간: 총 수면 시간 - N3 - REM - 깨어있음
                _buildFeedbackItem(
                  Icons.snooze,
                  '얕은 수면 시간',
                  '${(metrics.totalSleepDuration * ((100 - metrics.remRatio - metrics.deepSleepRatio) / 100)).toStringAsFixed(1)}시간',
                ),
                _buildFeedbackItem(
                  Icons.swap_horiz,
                  '뒤척임',
                  '${metrics.tossingAndTurning}회',
                ),
                _buildFeedbackItem(
                  Icons.mic_off,
                  '코골이',
                  metrics.avgSnoringDuration > 10
                      ? '감지됨 (${metrics.avgSnoringDuration}분)'
                      : '없음',
                ),
                _buildFeedbackItem(
                  Icons.favorite_border,
                  'HRV',
                  '${metrics.avgHrv}ms',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildFeedbackItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryNavy, size: 20),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyText,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('개선 가이드', style: AppTextStyles.heading2),
        const SizedBox(height: 15),
        Card(
          color: AppColors.secondaryWhite,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecommendationItem('💡 규칙적인 수면 습관을 유지하는 것이 좋습니다.'),
                _buildRecommendationItem('🛌 취침 전 가벼운 스트레칭은 수면의 질을 높여줍니다.'),
                _buildRecommendationItem('☕️ 카페인 섭취를 줄여보세요.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.successGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.secondaryBodyText.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/screens/sleep_report_screen.dart

import 'package:flutter/material.dart';
import '../widgets/data_chart.dart';
import '../utils/app_colors.dart';

class SleepReportScreen extends StatelessWidget {
  const SleepReportScreen({super.key});

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
            _buildChartSection(context, '수면 주기 그래프', const DataChart()),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2023년 10월 27일', style: TextStyle(color: AppColors.secondaryText)),
        SizedBox(height: 5),
        Text(
          '총 수면 시간: 7시간 30분',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepScoreCard(BuildContext context) {
    return const Card(
      color: AppColors.secondaryWhite,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '총 수면 점수',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '85점',
              style: TextStyle(
                color: AppColors.successGreen,
                fontWeight: FontWeight.bold,
                fontSize: 60,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '매우 좋은 수면을 취하셨습니다!',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
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
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        chartWidget,
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Column(
      // Removed const
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '수면 분석 피드백',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Card(
          // Removed const
          color: AppColors.secondaryWhite,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeedbackItem(Icons.bedtime, '깊은 수면 시간', '2시간 30분'),
                _buildFeedbackItem(Icons.snooze, '얕은 수면 시간', '4시간 00분'),
                _buildFeedbackItem(
                  Icons.airline_seat_legroom_extra,
                  '렘 수면 시간',
                  '1시간 00분',
                ),
                _buildFeedbackItem(Icons.swap_horiz, '뒤척임', '12회'),
                _buildFeedbackItem(Icons.mic_off, '코골이 감지', '없음'),
                _buildFeedbackItem(Icons.favorite_border, '수면 무호흡', '감지되지 않음'),
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
          Icon(icon, color: AppColors.accentNavy, size: 20),
          const SizedBox(width: 10),
          Text(
            '$title: ',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection(BuildContext context) {
    return Column(
      // Removed const
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '개선 가이드',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Card(
          // Removed const
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
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

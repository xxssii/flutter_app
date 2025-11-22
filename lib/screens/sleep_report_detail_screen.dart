import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/heart_rate_chart.dart'; // ✅ 임포트 추가

class SleepReportDetailScreen extends StatelessWidget {
  // 실제로는 이 데이터를 생성자에서 받아와야 합니다.
  // final SleepReport report;
  // const SleepReportDetailScreen({Key? key, required this.report}) : super(key: key);

  const SleepReportDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 수면 리포트', style: AppTextStyles.heading2),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 날짜 및 총 수면 시간
            Text('2025년 10월 29일', style: AppTextStyles.secondaryBodyText),
            const SizedBox(height: 4),
            Text('총 수면 시간: 7.5시간', style: AppTextStyles.heading1),
            const SizedBox(height: 24),

            // 2. 수면 점수 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.secondaryWhite, // 배경색 (연한 회색)
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '총 수면 점수',
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '100점',
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 60,
                      color: AppColors.successGreen,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '훌륭한 수면이었습니다. 어젯밤 꿀잠 주무셨네요!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.secondaryBodyText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. ✨ 수면 주기 그래프 (HeartRateChartSection으로 교체) ✨
            const HeartRateChartSection(), // ✅ 여기에 새 위젯 삽입

            const SizedBox(height: 32), // ✅ 그래프와 피드백 목록 사이 간격
            // 4. 수면 분석 피드백 목록
            Text('수면 분석 피드백', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.secondaryWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildFeedbackItem(
                    Icons.wb_sunny_outlined,
                    'Awake (깨어있음):',
                    '0.5시간',
                  ),
                  const Divider(),
                  _buildFeedbackItem(
                    Icons.cloud_outlined,
                    'Light (얕은 수면):',
                    '4.5시간',
                  ),
                  const Divider(),
                  _buildFeedbackItem(
                    Icons.nightlight_round,
                    'Deep (깊은 수면):',
                    '1.3시간',
                  ),
                  const Divider(),
                  _buildFeedbackItem(
                    Icons.psychology_outlined,
                    'REM (렘수면):',
                    '1.6시간',
                  ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 24),

                  _buildFeedbackItem(Icons.compare_arrows, '뒤척임:', '12회'),
                  const Divider(),
                  _buildFeedbackItem(
                    Icons.mic_off_outlined,
                    '코골이 감지:',
                    '15.0분',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryNavy),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyText),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyText),
        ],
      ),
    );
  }
}

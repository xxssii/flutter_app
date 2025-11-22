// lib/state/sleep_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/sleep_data_state.dart';
import '../utils/sleep_score_analyzer.dart';
import '../widgets/heart_rate_chart.dart';
import '../widgets/snoring_chart.dart'; // ✅ SnoringChartSection 임포트 추가!

// StatefulWidget으로 변경하여 탭 상태를 관리합니다.
class SleepReportScreen extends StatefulWidget {
  const SleepReportScreen({super.key});

  @override
  State<SleepReportScreen> createState() => _SleepReportScreenState();
}

class _SleepReportScreenState extends State<SleepReportScreen> {
  String _selectedGraphType = 'heart_rate'; // 기본값은 심박수

  @override
  Widget build(BuildContext context) {
    final sleepData = Provider.of<SleepDataState>(context);

    final metrics = sleepData.todayMetrics;
    if (metrics == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('리포트 로딩 중')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final analyzer = SleepScoreAnalyzer();
    final int score = analyzer.getSleepScore(
      metrics.sleepEfficiency,
      metrics.remRatio,
      metrics.deepSleepRatio,
    );
    final String reportMessage = analyzer.generateDailyReport(score);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 수면 리포트'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.primaryText),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(
              context,
              metrics.reportDate,
              metrics.totalSleepDuration,
            ),
            const SizedBox(height: 20),
            _buildSleepScoreCard(context, score, reportMessage),
            const SizedBox(height: 20),

            // ✅ 그래프 전환 탭과 그래프 위젯
            _buildGraphSection(context),

            const SizedBox(height: 20),
            _buildFeedbackSection(context, metrics),
            const SizedBox(height: 20),
            _buildRecommendationSection(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ 그래프 섹션 위젯 추가 (탭 전환 로직 포함)
  Widget _buildGraphSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedGraphType == 'heart_rate' ? '오늘의 심박수 변화' : '오늘의 코골이 패턴',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGraphTabButton(
              context: context,
              text: '심박수',
              graphType: 'heart_rate',
              isSelected: _selectedGraphType == 'heart_rate',
            ),
            const SizedBox(width: 10),
            _buildGraphTabButton(
              context: context,
              text: '코골이',
              graphType: 'snoring',
              isSelected: _selectedGraphType == 'snoring',
            ),
          ],
        ),
        const SizedBox(height: 15),
        // 선택된 그래프 타입에 따라 다른 위젯을 보여줍니다.
        _selectedGraphType == 'heart_rate'
            ? const HeartRateChartSection()
            : SnoringChartSection(), // 코골이 그래프 (아래에서 새로 정의)
        const SizedBox(height: 15),
        // 선택된 그래프 타입에 따라 다른 해석 가이드를 보여줍니다.
        _selectedGraphType == 'heart_rate'
            ? _buildHeartRateGuide()
            : _buildSnoringGuide(), // 코골이 해석 가이드 (아래에서 새로 정의)
      ],
    );
  }

  // ✅ 그래프 탭 버튼 위젯
  Widget _buildGraphTabButton({
    required BuildContext context,
    required String text,
    required String graphType,
    required bool isSelected,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedGraphType = graphType;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColors.primaryNavy
              : AppColors.secondaryWhite,
          foregroundColor: isSelected ? AppColors.white : AppColors.primaryText,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primaryNavy : AppColors.lightGrey,
              width: 1,
            ),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ✅ 심박수 해석 가이드 위젯 (기존 내용)
  Widget _buildHeartRateGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline,
              size: 20,
              color: AppColors.primaryNavy,
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
        const SizedBox(height: 10),
        _buildGuideItem('그래프가 낮고 평평할수록 깊은 잠을 잘 잤다는 의미입니다.'),
        _buildGuideItem('그래프가 뾰족하게 튀어 오르는 구간은 꿈을 꾸거나(REM), 잠시 뒤척인 시간입니다.'),
        _buildGuideItem('평소보다 심박수가 높다면 스트레스나 카페인 섭취를 점검해보세요.'),
      ],
    );
  }

  // ✅ 코골이 해석 가이드 위젯 (새로 추가)
  Widget _buildSnoringGuide() {
    return Card(
      // ✅ Card로 감싸서 디자인 통일
      color: AppColors.secondaryWhite,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 8),
                Text(
                  '코골이 해석 가이드',
                  style: AppTextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildGuideItem('그래프가 높게 솟아오른 구간은 코골이가 심했던 시간입니다.'),
            _buildGuideItem('코골이 강도가 높다면 수면 중 호흡에 방해가 될 수 있습니다.'),
            _buildGuideItem('수면 자세 변경이나 생활 습관 개선을 통해 코골이를 줄일 수 있습니다.'),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: AppTextStyles.bodyText),
          Expanded(child: Text(text, style: AppTextStyles.bodyText)),
        ],
      ),
    );
  }

  Widget _buildReportHeader(
    BuildContext context,
    String date,
    double totalSleepTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(date, style: AppTextStyles.secondaryBodyText),
        const SizedBox(height: 5),
        Text(
          '총 수면 시간: ${totalSleepTime.toStringAsFixed(1)}시간',
          style: AppTextStyles.heading1,
        ),
      ],
    );
  }

  Widget _buildSleepScoreCard(BuildContext context, int score, String message) {
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
              message,
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ --- 피드백 섹션 (아이콘 및 순서 수정) ---
  Widget _buildFeedbackSection(BuildContext context, SleepMetrics metrics) {
    // Mock 데이터를 기반으로 시간 계산
    final double deepSleepTime =
        metrics.totalSleepDuration * (metrics.deepSleepRatio / 100);
    final double remSleepTime =
        metrics.totalSleepDuration * (metrics.remRatio / 100);

    // 얕은 수면 = 총 수면 - (깊은잠 + 렘수면)
    final double lightSleepTime =
        metrics.totalSleepDuration *
        ((100 - metrics.remRatio - metrics.deepSleepRatio) / 100);

    // 깨어있음 = 누운 시간 - 실 수면 시간
    final double awakeTime = metrics.timeInBed - metrics.totalSleepDuration;

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
                // ✅ 1. Awake (깨어있음)
                _buildFeedbackItem(
                  Icons.wb_sunny, // ☀️
                  'Awake (깨어있음)',
                  '${awakeTime.toStringAsFixed(1)}시간',
                ),
                // ✅ 2. Light (얕은 수면)
                _buildFeedbackItem(
                  Icons.cloud_queue, // ☁️
                  'Light (얕은 수면)',
                  '${lightSleepTime.toStringAsFixed(1)}시간',
                ),
                // ✅ 3. Deep (깊은 수면)
                _buildFeedbackItem(
                  Icons.nights_stay, // 🌙
                  'Deep (깊은 수면)',
                  '${deepSleepTime.toStringAsFixed(1)}시간',
                ),
                // ✅ 4. REM (렘수면)
                _buildFeedbackItem(
                  Icons.psychology, // 🧠
                  'REM (렘수면)',
                  '${remSleepTime.toStringAsFixed(1)}시간',
                ),
                const Divider(height: 24), // 수면 단계와 기타 지표 구분
                _buildFeedbackItem(
                  Icons.swap_horiz,
                  '뒤척임',
                  '${metrics.tossingAndTurning}회',
                ),
                _buildFeedbackItem(
                  Icons.mic, // ✅ 아이콘 변경
                  '코골이 감지',
                  '${metrics.avgSnoringDuration}분', // 이 값은 하드웨어에서 오는 실제 데이터로 변경해야 합니다.
                ),
                _buildFeedbackItem(
                  Icons.warning_amber_rounded,
                  '수면 무호흡',
                  metrics.apneaCount > 0
                      ? '${metrics.apneaCount}회 감지됨'
                      : '감지되지 않음',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackItem(IconData icon, String title, String value) {
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

  Widget _buildRecommendationItem(String text) {
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

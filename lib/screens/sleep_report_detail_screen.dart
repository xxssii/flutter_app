// lib/screens/sleep_report_detail_screen.dart
// ✅ 전체 파일을 이 내용으로 교체하세요!

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/heart_rate_chart.dart';    // ✅ 심박수 그래프
import '../widgets/snoring_chart.dart';       // ✅ 코골이 그래프 임포트 추가!

class SleepReportDetailScreen extends StatefulWidget {  // ✅ StatefulWidget으로 변경
  const SleepReportDetailScreen({Key? key}) : super(key: key);

  @override
  State<SleepReportDetailScreen> createState() => _SleepReportDetailScreenState();
}

class _SleepReportDetailScreenState extends State<SleepReportDetailScreen> {
  // ✅ 그래프 전환을 위한 상태 변수
  String _selectedGraphType = 'heart_rate'; // 'heart_rate' 또는 'snoring'

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
                color: AppColors.secondaryWhite,
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

            // ✅ 3. 그래프 섹션 (탭 전환 기능 추가!)
            _buildGraphSection(context),

            const SizedBox(height: 32),
            
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

  // ✅ 그래프 섹션 빌더 (탭 전환 기능 포함)
  Widget _buildGraphSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 그래프 제목
        Text(
          _selectedGraphType == 'heart_rate' ? '오늘의 심박수 변화' : '오늘의 코골이 소리 크기',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 15),
        
        // 탭 버튼
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
        
        // 선택된 그래프 표시
        _selectedGraphType == 'heart_rate'
            ? const HeartRateChartSection()  // 심박수 그래프
            : const SnoringChartSection(),   // 코골이 그래프
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
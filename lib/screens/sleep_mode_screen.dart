// lib/screens/s_main_moon.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class SMainMoonScreen extends StatelessWidget {
  const SMainMoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // AppState에서 실시간 데이터를 가져옵니다.
        // 소수점 제거 및 단위 추가
        final heartRate = appState.currentHeartRate.toStringAsFixed(0);
        final spo2 = appState.currentSpo2.toStringAsFixed(0);

        return Scaffold(
          backgroundColor: AppColors.primaryNavy, // 측정 중 배경색
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.cardBackground,
              ),
              onPressed: () {
                // 측정 중에는 뒤로가기 버튼 비활성화 또는 경고가 일반적이지만,
                // 현재는 뒤로가기 버튼을 통해 앱을 강제로 닫는 상황을 방지하기 위해 제거하거나 주석 처리하는 것이 좋지만,
                // 간단한 앱에서는 pop으로 처리합니다.
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. 실시간 지표 표시 영역 (복원)
                _buildMetricDisplay(
                  icon: Icons.favorite,
                  value: '$heartRate bpm',
                  label: '심박수',
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 30),
                _buildMetricDisplay(
                  icon: Icons.opacity,
                  value: '$spo2 %',
                  label: '산소포화도',
                  color: AppColors.successGreen,
                ),

                const Spacer(flex: 3),

                // 2. 수면 기록 중지 버튼
                Text(
                  '수면 기록 중...',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.cardBackground,
                  ),
                ),
                const SizedBox(height: 16),

                // lib/screens/s_main_moon.dart (ElevatedButton 부분 교체)
                ElevatedButton(
                  onPressed: () {
                    appState.toggleMeasurement(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: Colors.white,
                        width: 2.5,
                      ), // 흰색 테두리
                    ),
                    padding: const EdgeInsets.all(35),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.nightlight_round, // ✨ 이 부분을 달 느낌의 아이콘으로 변경했습니다. ✨
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '측정 종료',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        );
      },
    );
  }

  // 지표를 표시하는 헬퍼 위젯
  Widget _buildMetricDisplay({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 60, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.cardBackground,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

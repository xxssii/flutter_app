// lib/screens/sleep_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

// ✅ 1. 클래스 이름을 SMainMoonScreen -> SleepModeScreen 으로 수정
class SleepModeScreen extends StatelessWidget {
  // ✅ 2. 생성자 이름도 수정
  const SleepModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // AppState에서 실시간 데이터를 가져옵니다.
        // (Firestore 또는 BLE에서 업데이트된 값)
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
                // AppState에 측정 종료를 알리기만 함
                appState.toggleMeasurement(context);
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. 실시간 지표 표시 영역 (심박수)
                _buildMetricDisplay(
                  icon: Icons.favorite,
                  value: '$heartRate bpm',
                  label: '심박수',
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 30),

                // 2. 실시간 지표 표시 영역 (산소포화도)
                _buildMetricDisplay(
                  icon: Icons.opacity,
                  value: '$spo2 %',
                  label: '산소포화도',
                  color: AppColors.successGreen,
                ),

                const Spacer(flex: 3),

                // 3. 수면 기록 중 텍스트
                Text(
                  '수면 기록 중...',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.cardBackground,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. 측정 종료 버튼 (달 아이콘)
                ElevatedButton(
                  onPressed: () {
                    // AppState에 측정 종료를 알리기만 함
                    appState.toggleMeasurement(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // 투명 배경
                    foregroundColor: Colors.white, // 눌렀을 때 색상
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
                      const Icon(
                        Icons.nightlight_round, // 달 아이콘
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

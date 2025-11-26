// lib/screens/sleep_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
// import 'dart:math' as math; // math.sin 사용 (이제 필요 없음)

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({Key? key}) : super(key: key);

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen>
    with TickerProviderStateMixin {
  // 심박수 애니메이션 컨트롤러
  late AnimationController _heartAnimationController;
  late Animation<double> _heartBeatAnimation; // 박동 (크기 변화)
  late Animation<double> _heartGlowAnimation; // 글로우 (빛나는 효과)

  // 산소포화도 글로우 애니메이션 컨트롤러 (물결은 제거)
  late AnimationController _spo2GlowAnimationController;
  late Animation<double> _spo2GlowAnimation;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------
    // 심박수 애니메이션 초기화
    // ----------------------------------------------------
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 한 번의 박동 시간
    )..repeat(reverse: true); // 계속 반복 (커졌다가 작아지기)

    // 크기 변화 애니메이션 (예: 1.0배에서 1.2배로 커졌다가 다시 1.0배)
    _heartBeatAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeInOut, // 부드러운 박동 효과
      ),
    );

    // 글로우 애니메이션: 박동에 맞춰 그림자 퍼짐 정도를 0에서 15로 변화
    _heartGlowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeIn, // 빛이 빠르게 커졌다가 서서히 줄어드는 느낌
      ),
    );

    // ----------------------------------------------------
    // 산소포화도 글로우 애니메이션 초기화 (물결 대신 단순히 빛나는 효과)
    // ----------------------------------------------------
    _spo2GlowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 글로우 주기
    )..repeat(reverse: true); // 반복 (밝아졌다가 어두워지기)

    _spo2GlowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _spo2GlowAnimationController,
        curve: Curves.easeInOut, // 부드럽게 빛남
      ),
    );
  }

  // SPO2 관련 애니메이션은 글로우로 대체되었으므로, 별도의 update 함수는 필요 없음
  // AppState의 currentSpo2 값이 변경되어도 UI는 Text 위젯이 자동으로 업데이트 됨

  @override
  void dispose() {
    _heartAnimationController.dispose();
    _spo2GlowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
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
                appState.toggleMeasurement(context);
              },
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. 심박수 지표 표시 영역
                _buildHeartRateDisplay(
                  value: '$heartRate bpm',
                  label: '심박수',
                  color: AppColors.errorRed,
                  scaleAnimation: _heartBeatAnimation,
                  glowAnimation: _heartGlowAnimation,
                ),
                const SizedBox(height: 30),

                // 2. 산소포화도 지표 표시 영역 (물방울 아이콘 + 글로우)
                _buildSpo2Display(
                  value: '$spo2 %',
                  label: '산소포화도',
                  color: AppColors.successGreen,
                  glowAnimation: _spo2GlowAnimation,
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

  // 심박수 애니메이션 전용 헬퍼 위젯
  Widget _buildHeartRateDisplay({
    required String value,
    required String label,
    required Color color,
    required Animation<double> scaleAnimation,
    required Animation<double> glowAnimation,
  }) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([scaleAnimation, glowAnimation]),
          builder: (context, child) {
            final blurRadius = glowAnimation.value;
            final opacity = (glowAnimation.value / 15.0) * 0.7;

            Widget iconWidget = Icon(Icons.favorite, size: 60, color: color);

            iconWidget = Transform.scale(
              scale: scaleAnimation.value,
              child: iconWidget,
            );

            iconWidget = Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(opacity),
                    blurRadius: blurRadius,
                    spreadRadius: blurRadius * 0.1,
                  ),
                ],
              ),
              child: iconWidget,
            );

            return iconWidget;
          },
        ),
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

  // 산소포화도 애니메이션 전용 헬퍼 위젯 (기본 물방울 아이콘 + 글로우)
  Widget _buildSpo2Display({
    required String value,
    required String label,
    required Color color,
    required Animation<double> glowAnimation, // 글로우 애니메이션
  }) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: glowAnimation,
          builder: (context, child) {
            final blurRadius = glowAnimation.value;
            final opacity = (glowAnimation.value / 10.0) * 0.7; // 글로우 최대치 10.0

            Widget iconWidget = Icon(
              Icons.water_drop, // 깔끔한 기본 물방울 아이콘
              size: 60,
              color: color,
            );

            iconWidget = Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle, // 물방울 주변에 원형 글로우 효과를 줌
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(opacity),
                    blurRadius: blurRadius,
                    spreadRadius: blurRadius * 0.1,
                  ),
                ],
              ),
              child: iconWidget,
            );

            return iconWidget;
          },
        ),
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

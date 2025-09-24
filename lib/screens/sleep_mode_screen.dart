// lib/screens/sleep_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart';

class SMainMoonScreen extends StatelessWidget {
  const SMainMoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset('assets/s_main.png', fit: BoxFit.cover),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '편안한 밤 되세요',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '수면 기록 중...',
                      style: AppTextStyles.secondaryBodyText.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // 버튼을 누르면 AppState의 toggleMeasurement만 호출하고,
                        // 화면 전환은 AppState 내부 로직에 맡깁니다.
                        appState.toggleMeasurement(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy, // <-- 색상 변경
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('수면 기록 종료'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

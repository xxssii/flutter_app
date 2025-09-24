// lib/screens/sleep_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/app_state.dart'; // 이 줄을 추가합니다.

class SMainMoonScreen extends StatelessWidget {
  const SMainMoonScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AppState에 접근하기 위해 Consumer를 사용합니다.
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
                        // '수면 기록 종료' 버튼을 누르면 appState의 toggleMeasurement를 호출합니다.
                        appState.toggleMeasurement();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
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

// lib/utils/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // ----------------------------------------------------
  // Light Theme Colors
  // ----------------------------------------------------
  static const Color primaryNavy = Color(0xFF1A1A3A);
  static const Color secondaryWhite = Color(0xFFF0F0F0);
  static const Color background = Color(0xFFF0F2F5);
  static const Color cardBackground = Colors.white;
  static const Color lightGrey = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF); // ✅ white 색상 정의
  static const Color black = Color(0xFF000000); // 필요할 경우를 대비해 추가
  static const Color primaryText = Color(0xFF2C3E50);
  static const Color secondaryText = Color(0xFF7F8C8D);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color successGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color progressBackground = Color(0xFFE0E0E0);
  // ✅ 이 줄을 추가해주세요! (라이트 모드용 구분선 색상)
  static const Color divider = Color(0xFFE0E0E0);

  // ✅ --- Chart Colors (4단계로 수정됨) ---
  static final Color lightSleepColor = primaryNavy.withOpacity(
    0.7,
  ); // 얕은 수면 (N1+N2)
  static const Color deepSleepColor = primaryNavy; // 깊은 수면 (N3)
  static const Color remColor = secondaryText;
  static const Color awakeColor = errorRed;

  // ✅ 이 부분을 추가해 주세요!
  static const Color cardBorder = Color(0xFFE0E0E0); // 카드 테두리 색상 (연한 회색 예시)

  // ----------------------------------------------------
  // Dark Theme Colors
  // ----------------------------------------------------
  static const Color darkPrimaryNavy = Color(0xFFBBDEFB);
  static const Color darkBackground = Color(0xFF202124);
  static const Color darkCardBackground = Color(0xFF303134);
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white;
  static const Color darkBorderColor = Color(0xFF5F6368);
  static const Color darkSuccessGreen = Color(0xFF6AA84F);
  static const Color darkWarningOrange = Color(0xFFF9AB00);
  static const Color darkErrorRed = Color(0xFFF28B82);
  static const Color darkProgressBackground = Color(0xFF5F6368);

  // ✅ --- 다크 모드용 Chart Colors (4단계로 수정됨) ---
  static final Color darkLightSleepColor = darkPrimaryNavy.withOpacity(0.7);
  static const Color darkDeepSleepColor = darkPrimaryNavy;
  static const Color darkRemColor = darkSecondaryText;
  static const Color darkAwakeColor = darkErrorRed;
  // ✅ 이 줄도 추가해주세요! (다크 모드용 구분선 색상)
  static const Color darkDivider = Color(0xFF424242);
}

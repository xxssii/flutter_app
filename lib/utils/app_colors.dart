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
  static const Color primaryText = Color(0xFF2C3E50);
  static const Color secondaryText = Color(0xFF7F8C8D);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color successGreen = Color(0xFF2ECC71);
  static const Color warningOrange = Color(0xFFF39C12);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color progressBackground = Color(0xFFE0E0E0);

  // Chart Colors
  static final Color nrem1Color = primaryNavy.withOpacity(0.4);
  static final Color nrem2Color = primaryNavy.withOpacity(0.7);
  static const Color nrem3Color = primaryNavy;
  static const Color remColor = secondaryText;
  static const Color awakeColor = errorRed;

  // ----------------------------------------------------
  // Dark Theme Colors (모든 텍스트를 순수한 흰색으로 통일)
  // ----------------------------------------------------
  static const Color darkPrimaryNavy = Color(0xFFBBDEFB);
  static const Color darkBackground = Color(0xFF202124);
  static const Color darkCardBackground = Color(0xFF303134);

  // 모든 글씨를 순수한 흰색으로 변경 (가독성 확보)
  static const Color darkPrimaryText = Colors.white;
  static const Color darkSecondaryText = Colors.white; // ✨ 이 부분이 흰색으로 통일됩니다.

  static const Color darkBorderColor = Color(0xFF5F6368);
  static const Color darkSuccessGreen = Color(0xFF6AA84F);
  static const Color darkWarningOrange = Color(0xFFF9AB00);
  static const Color darkErrorRed = Color(0xFFF28B82);
  static const Color darkProgressBackground = Color(0xFF5F6368);

  // 다크 모드용 Chart Colors
  static final Color darkNrem1Color = darkPrimaryNavy.withOpacity(0.4);
  static final Color darkNrem2Color = darkPrimaryNavy.withOpacity(0.7);
  static const Color darkNrem3Color = darkPrimaryNavy;
  static const Color darkRemColor = darkSecondaryText;
  static const Color darkAwakeColor = darkErrorRed;
}

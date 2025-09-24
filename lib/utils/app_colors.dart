// lib/utils/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  // 새 포인트 색상 (제공해주신 이미지에서 추출한 네이비 색상)
  static const Color primaryNavy = Color(0xFF1A1A3A);
  static const Color secondaryWhite = Color(0xFFF0F0F0); // 이 줄을 추가합니다.

  // 배경 및 카드 색상
  static const Color background = Color(0xFFF0F2F5); // 밝은 회색 배경 (화이트톤 유지)
  static const Color cardBackground = Colors.white; // 카드 배경은 흰색

  // 텍스트 색상
  static const Color primaryText = Color(0xFF2C3E50); // 진한 회색 (기본 텍스트)
  static const Color secondaryText = Color(0xFF7F8C8D); // 연한 회색 (보조 텍스트)

  // 상태 색상
  static const Color successGreen = Color(0xFF2ECC71); // 성공 (초록)
  static const Color warningOrange = Color(0xFFF39C12); // 경고 (주황)
  static const Color errorRed = Color(0xFFE74C3C); // 에러 (빨강)

  // 기타 UI 요소 색상
  static const Color borderColor = Color(0xFFE0E0E0); // 연한 회색 테두리
  static const Color progressBackground = Color(0xFFE0E0E0); // 프로그레스 바 배경

  // Chart Colors (수면 단계별 색상)
  static final Color nrem1Color = primaryNavy.withOpacity(0.4);
  static final Color nrem2Color = primaryNavy.withOpacity(0.7);
  static const Color nrem3Color = primaryNavy;
  static const Color remColor = secondaryText;
  static const Color awakeColor = errorRed;

  // Dark Theme Colors
  static const Color darkPrimaryNavy = Color(0xFFBBDEFB); // 다크 모드용 포인트 색상
  static const Color darkBackground = Color(0xFF202124);
  static const Color darkCardBackground = Color(0xFF303134);
  static const Color darkPrimaryText = Color(0xFFE8EAED);
  static const Color darkSecondaryText = Color(0xFFA0A0A0);
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

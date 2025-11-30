//lib/utils/app_text_styles.dart

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Light Theme Text Styles
  // ✅ 색상을 제거하여 Theme의 기본 텍스트 색상을 사용하도록 수정
  // 다크모드에서 자동으로 밝은 색으로 표시됩니다

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    // 색상 제거: Theme의 기본 텍스트 색상 사용
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    // 색상 제거: Theme의 기본 텍스트 색상 사용
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    // 색상 제거: Theme의 기본 텍스트 색상 사용
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    // 색상 제거: Theme의 기본 텍스트 색상 사용
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    // 색상 제거: Theme의 기본 텍스트 색상 사용
  );

  static const TextStyle secondaryBodyText = TextStyle(
    fontSize: 14,
    // 색상 제거: Theme의 보조 텍스트 색상 사용 (다크모드에서 자동으로 밝게)
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 12,
    // 색상 제거: Theme의 보조 텍스트 색상 사용 (다크모드에서 자동으로 밝게)
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle bottomNavItemLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  // Dark Theme Text Styles (하위 호환성을 위해 유지)
  // 실제로는 위의 스타일들이 Theme에 따라 자동으로 색상이 변경됩니다

  static const TextStyle darkAppBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkPrimaryText,
  );
  static const TextStyle darkHeading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.darkPrimaryText,
  );
  static const TextStyle darkHeading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.darkPrimaryText,
  );
  static const TextStyle darkHeading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkPrimaryText,
  );
  static const TextStyle darkBodyText = TextStyle(
    fontSize: 16,
    color: AppColors.darkPrimaryText,
  );
  static const TextStyle darkSecondaryBodyText = TextStyle(
    fontSize: 14,
    color: AppColors.darkSecondaryText,
  );
  static const TextStyle darkSmallText = TextStyle(
    fontSize: 12,
    color: AppColors.darkSecondaryText,
  );
  static const TextStyle darkButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const TextStyle darkBottomNavItemLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle darkTabLabelText = TextStyle(fontSize: 14);
}

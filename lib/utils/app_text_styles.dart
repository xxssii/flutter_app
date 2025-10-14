//lib/utils/app_text_styles.dart

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Light Theme Text Styles

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,

    fontWeight: FontWeight.bold,

    color: AppColors.primaryText,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,

    fontWeight: FontWeight.bold,

    color: AppColors.primaryText,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,

    fontWeight: FontWeight.bold,

    color: AppColors.primaryText,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,

    fontWeight: FontWeight.bold,

    color: AppColors.primaryText,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,

    color: AppColors.primaryText,
  );

  static const TextStyle secondaryBodyText = TextStyle(
    fontSize: 14,

    color: AppColors.secondaryText,
  );

  static const TextStyle smallText = TextStyle(
    fontSize: 12,

    color: AppColors.secondaryText,
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

  // Dark Theme Text Styles (모든 텍스트 색상을 흰색으로 변경)

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

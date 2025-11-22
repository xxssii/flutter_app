// lib/widgets/apnea_warning_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ApneaWarningDialog extends StatelessWidget {
  final String message;

  const ApneaWarningDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.errorRed.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Text('무호흡 경고', style: AppTextStyles.heading2),
        ],
      ),
      content: Text(message, style: AppTextStyles.bodyText),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '확인',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

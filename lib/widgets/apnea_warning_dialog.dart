// lib/widgets/apnea_warning_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ApneaWarningDialog extends StatelessWidget {
  final String message;

  const ApneaWarningDialog({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      title: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Text(
            '경고',
            style: AppTextStyles.heading2.copyWith(color: AppColors.errorRed),
          ),
        ],
      ),
      content: Text(message, style: AppTextStyles.bodyText),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 팝업 닫기
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

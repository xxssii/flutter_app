// lib/widgets/apnea_report_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ApneaReportDialog extends StatelessWidget {
  final List<String> reportDetails;
  final List<String> apneaEvents;
  final VoidCallback? onClose;

  const ApneaReportDialog({
    Key? key,
    required this.reportDetails,
    required this.apneaEvents,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String reportContent;
    if (apneaEvents.isEmpty) {
      reportContent = '수면 중 무호흡 증상이 감지되지 않았습니다.';
    } else {
      reportContent =
          '총 무호흡 의심 횟수: ${apneaEvents.length}회\n\n'
              '발생 시기:\n' +
          apneaEvents.join('\n');
      reportContent += '\n\n무호흡증이 의심됩니다. 전문가와 상담해보세요.';
    }

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primaryNavy, width: 2),
      ),
      title: Text('수면 무호흡 리포트', style: AppTextStyles.heading2),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reportDetails.join('\n\n'), style: AppTextStyles.bodyText),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(reportContent, style: AppTextStyles.bodyText),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // onClose 콜백 함수를 호출합니다.
            if (onClose != null) {
              onClose!();
            } else {
              Navigator.of(context).pop();
            }
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

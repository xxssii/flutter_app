// lib/widgets/apnea_report_dialog.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ApneaReportDialog extends StatelessWidget {
  final List<String> reportDetails;
  final List<String> apneaEvents;
  final VoidCallback? onClose;
  final VoidCallback? onViewDetails; // ✅ 상세 보기 콜백 추가

  const ApneaReportDialog({
    super.key,
    required this.reportDetails,
    required this.apneaEvents,
    this.onClose,
    this.onViewDetails, // ✅ 생성자에 추가
  });

  @override
  Widget build(BuildContext context) {
    // 리포트 내용 구성
    String reportContent = reportDetails.join('\n\n');

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primaryNavy, width: 2),
      ),
      title: Text('수면 요약 리포트', style: AppTextStyles.heading2),
      content: SingleChildScrollView(
        child: Text(reportContent, style: AppTextStyles.bodyText),
      ),
      actions: [
        // ✅ "상세 리포트 보기" 버튼 추가
        if (onViewDetails != null)
          TextButton(
            onPressed: onViewDetails, // 상세 보기 콜백 호출
            child: Text(
              '상세 리포트 보기',
              style: AppTextStyles.bodyText.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // ✅ "확인" 버튼 (기존 닫기 기능)
        TextButton(
          onPressed: onClose ?? () => Navigator.of(context).pop(), // 닫기 콜백 호출
          child: Text(
            '확인',
            style: AppTextStyles.bodyText.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

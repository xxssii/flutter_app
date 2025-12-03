// lib/screens/sleep_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../state/sleep_data_state.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'sleep_report_screen.dart';

class SleepHistoryScreen extends StatefulWidget {
  const SleepHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ 화면이 열릴 때 데이터가 없을 때만 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sleepDataState = Provider.of<SleepDataState>(context, listen: false);
      
      // ✅ 이미 데이터가 있으면 다시 로딩하지 않음!
      if (sleepDataState.sleepHistory.isEmpty && !sleepDataState.isLoading) {
        final userId = Provider.of<AppState>(context, listen: false).currentUserId;
        print('📋 SleepHistoryScreen: 데이터가 없어서 로딩 시작');
        sleepDataState.fetchAllSleepReports(userId);
      } else {
        print('✅ SleepHistoryScreen: 이미 데이터가 있음 (${sleepDataState.sleepHistory.length}개)');
      }
    });
  }

  // ✅ 날짜 포맷 변환 헬퍼 함수
  String _formatDate(String sessionId) {
    try {
      // "session-2025-11-30" 형식에서 날짜 부분 추출
      final parts = sessionId.split('-');
      if (parts.length >= 4) {
        final year = parts[1];
        final month = parts[2];
        final day = parts[3];
        return '$year년 $month월 $day일';
      }
    } catch (e) {
      print('날짜 변환 오류: $e');
    }
    return sessionId; // 변환 실패시 원본 반환
  }

  @override
  Widget build(BuildContext context) {
    final sleepDataState = Provider.of<SleepDataState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('지난 수면 기록', style: AppTextStyles.heading2),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      body: sleepDataState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sleepDataState.sleepHistory.isEmpty
          ? const Center(
              child: Text('저장된 수면 기록이 없습니다.', style: AppTextStyles.bodyText),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sleepDataState.sleepHistory.length,
              itemBuilder: (context, index) {
                final metrics = sleepDataState.sleepHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      _formatDate(metrics.reportDate),
                      style: AppTextStyles.heading3,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '총 수면 시간: ${metrics.totalSleepDuration.toStringAsFixed(1)}시간',
                          style: AppTextStyles.bodyText,
                        ),
                        Text(
                          '수면 효율: ${metrics.sleepEfficiency.toStringAsFixed(1)}%',
                          style: AppTextStyles.bodyText,
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // ✅ 상세 리포트 화면으로 이동
                      // 1. 선택된 수면 데이터를 SleepDataState의 todayMetrics로 설정
                      Provider.of<SleepDataState>(
                        context,
                        listen: false,
                      ).setTodayMetrics(metrics);

                      // 2. SleepReportScreen으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SleepReportScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
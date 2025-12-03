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
    // 화면이 열릴 때 데이터를 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ AppState에서 현재 사용자 ID 가져오기
      final userId = Provider.of<AppState>(context, listen: false).currentUserId;
      
      // ✅ context 제거! userId만 전달
      Provider.of<SleepDataState>(
        context,
        listen: false,
      ).fetchAllSleepReports(userId);  // ✅ 이 부분이 수정됨!
    });
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
                      metrics.reportDate,
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
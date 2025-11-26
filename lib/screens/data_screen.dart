// lib/screens/data_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fl_chart/fl_chart.dart'; // SleepHistoryScreen에서 사용
import 'dart:math' as math; // math로 임포트하여 충돌 방지

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../providers/sleep_provider.dart';
import '../models/sleep_report_model.dart';
import 'sleep_history_screen.dart'; // ✅ SleepHistoryScreen 임포트

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepProvider>(context);
    final report = sleepProvider.latestSleepReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 데이터 분석'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 날짜 범위 선택 기능 구현
            },
            child: const Text('최근 7일'),
          ),
        ],
      ),
      // 로딩/에러 상태여도 전체 화면 구조는 유지합니다.
      body: Column(
        children: [
          // 1. 상단 요약 카드 (로딩/에러/데이터 없음 상태를 내부에서 처리)
          _buildOverviewSection(sleepProvider, report),
          const SizedBox(height: 24),
          // 2. 탭바
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryNavy,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primaryNavy,
            tabs: const [
              Tab(text: '효율성'),
              Tab(text: '수면 단계'),
              Tab(text: '트렌드'),
              // ✅ '개선 가이드'를 '지난 기록'으로 변경
              Tab(text: '지난 기록'),
            ],
          ),
          // 3. 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEfficiencyTab(report), // 데이터가 없으면 null이 전달됨
                _buildPlaceholderTab('수면 단계'),
                _buildPlaceholderTab('트렌드'),
                // ✅ '개선 가이드' 탭 대신 SleepHistoryScreen을 보여줍니다.
                const SleepHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 상단 요약 섹션을 상태에 따라 다르게 표시하는 함수
  Widget _buildOverviewSection(
    SleepProvider sleepProvider,
    SleepReport? report,
  ) {
    if (sleepProvider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: SpinKitFadingCircle(color: AppColors.primaryNavy, size: 30.0),
        ),
      );
    }

    if (sleepProvider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            sleepProvider.errorMessage!,
            style: const TextStyle(color: AppColors.errorRed),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (report == null) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            '아직 수면 리포트가 없습니다.\n오늘 밤 수면을 측정해보세요!',
            style: AppTextStyles.secondaryBodyText,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 데이터가 있을 때만 정상적인 요약 카드를 보여줍니다.
    return _buildOverviewCards(report);
  }

  // 효율성 탭 내용
  Widget _buildEfficiencyTab(SleepReport? report) {
    if (report == null) {
      return _buildNoDataPlaceholder();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEfficiencyAnalysisCard(report),
          const SizedBox(height: 24),
          _buildSleepComparisonChart(report),
        ],
      ),
    );
  }

  // Placeholder 탭 빌더
  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            '$title 기능은\n준비 중입니다.',
            style: AppTextStyles.secondaryBodyText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 데이터 없음 Placeholder
  Widget _buildNoDataPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nights_stay_outlined,
            size: 48,
            color: AppColors.secondaryText,
          ),
          SizedBox(height: 16),
          Text('수면 데이터가 없습니다.', style: AppTextStyles.secondaryBodyText),
        ],
      ),
    );
  }

  // 상단 요약 카드 영역 (애니메이션 적용됨)
  Widget _buildOverviewCards(SleepReport report) {
    final summary = report.summary;
    double efficiency = 0.0;
    if (summary.totalDurationHours > 0) {
      efficiency =
          (summary.deepSleepHours +
              summary.remSleepHours +
              summary.lightSleepHours) /
          summary.totalDurationHours;
    }
    double remRatio = 0.0;
    final totalSleep =
        summary.deepSleepHours +
        summary.remSleepHours +
        summary.lightSleepHours;
    if (totalSleep > 0) {
      remRatio = summary.remSleepHours / totalSleep;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              title: '수면 효율',
              value: '${(efficiency * 100).toStringAsFixed(0)}%',
              icon: Icons.opacity,
              color: AppColors.primaryNavy,
              backgroundColor: AppColors.cardBackground,
              progress: efficiency,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              title: 'REM 비율',
              value: '${(remRatio * 100).toStringAsFixed(0)}%',
              icon: Icons.psychology,
              color: AppColors.successGreen,
              backgroundColor: AppColors.cardBackground,
              progress: remRatio,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              title: '평균 수면',
              value: '${summary.totalDurationHours.toStringAsFixed(1)}시간',
              icon: Icons.access_time,
              color: AppColors.warningOrange,
              backgroundColor: AppColors.cardBackground,
              progress: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // 개별 요약 카드 빌더 (애니메이션 도넛 그래프 적용)
  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required double progress,
  }) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.secondaryBodyText),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, child) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.progressBackground,
                            ),
                            strokeWidth: 8,
                          ),
                          CircularProgressIndicator(
                            value: animatedValue,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      );
                    },
                  ),
                  Text(
                    value,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 수면 효율 분석 카드 빌더
  Widget _buildEfficiencyAnalysisCard(SleepReport report) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수면 효율 분석', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            _buildAnalysisItem(
              title: '평균 수면 효율',
              value: '92%',
              description: '85% 이상이 이상적입니다.',
              isPositive: true,
            ),
            const Divider(color: AppColors.divider, height: 24),
            _buildAnalysisItem(
              title: 'REM 수면 비율',
              value: '20%',
              description: '20~25%가 이상적입니다.',
              isPositive: true,
            ),
            const Divider(color: AppColors.divider, height: 24),
            _buildAnalysisItem(
              title: '깊은 수면 비율',
              value: '15%',
              description: '15~20%가 이상적입니다.',
              isPositive: false,
              alertMessage: '깊은 수면이 약간 부족합니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String title,
    required String value,
    required String description,
    bool isPositive = true,
    String? alertMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bodyText),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: isPositive
                    ? AppColors.successGreen
                    : AppColors.warningOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(description, style: AppTextStyles.smallText),
        if (alertMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.warningOrange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                alertMessage,
                style: AppTextStyles.smallText.copyWith(
                  color: AppColors.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // 누운 시간 대비 실 수면 시간 비교 차트 빌더 (애니메이션 적용)
  Widget _buildSleepComparisonChart(SleepReport report) {
    final List<Map<String, dynamic>> data = [
      {'date': '7/13', 'total': 8.5, 'actual': 7.2},
      {'date': '7/14', 'total': 8.0, 'actual': 6.8},
      {'date': '7/15', 'total': 9.0, 'actual': 7.5},
      {'date': '7/16', 'total': 7.5, 'actual': 6.0},
      {'date': '7/17', 'total': 8.2, 'actual': 7.0},
      {'date': '7/18', 'total': 8.8, 'actual': 7.8},
      {'date': '7/19', 'total': 8.0, 'actual': 7.0},
    ];
    double maxHours = 0.0;
    for (var d in data) {
      maxHours = math.max(maxHours, d['total']);
    }
    maxHours = (maxHours / 2).ceil() * 2.0 + 2.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('누운 시간 대비 실 수면 시간', style: AppTextStyles.heading3),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 40;
                  return Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          for (int i = 0; i <= maxHours; i += 2)
                            Expanded(
                              child: Text(
                                '${i}h',
                                style: AppTextStyles.smallText,
                                textAlign: TextAlign.right,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: data.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final d = data[index];
                            final totalWidth =
                                (d['total'] / maxHours) * availableWidth;
                            final actualWidth =
                                (d['actual'] / maxHours) * availableWidth;
                            return Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    d['date'],
                                    style: AppTextStyles.smallText,
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Container(
                                        height: 20,
                                        width: totalWidth,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryNavy
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: actualWidth,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder:
                                            (context, animatedWidth, child) {
                                              return Container(
                                                height: 20,
                                                width: animatedWidth,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryNavy,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              );
                                            },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  AppColors.primaryNavy.withOpacity(0.1),
                  '누운 시간',
                ),
                const SizedBox(width: 24),
                _buildLegendItem(AppColors.primaryNavy, '실 수면 시간'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '진한 색 막대가 연한 색 배경을 많이 채울수록 수면 효율이 높은 날입니다.',
              style: AppTextStyles.smallText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.secondaryBodyText),
      ],
    );
  }
}

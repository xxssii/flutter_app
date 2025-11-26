// lib/screens/data_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // LineChart, PieChart 사용을 위해 필요
import 'dart:math' as math;

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../providers/sleep_provider.dart';
import '../models/sleep_report_model.dart';
import 'sleep_history_screen.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ 막대 그래프 애니메이션 컨트롤러
  late AnimationController _barChartAnimationController;
  late Animation<double> _barChartAnimation;

  // 도넛 그래프 애니메이션 컨트롤러
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  // 트렌드 그래프에서 현재 터치된 인덱스를 저장하는 상태 변수
  int? _touchedTrendIndex;

  // 가짜(Mock) 수면 리포트 데이터
  SleepReport _getMockSleepReport() {
    final now = DateTime.now();
    final sleepStart = DateTime(now.year, now.month, now.day - 1, 23, 30);
    final sleepEnd = DateTime(now.year, now.month, now.day, 7, 15);
    final totalDuration = sleepEnd.difference(sleepStart);
    final totalDurationHours = totalDuration.inMinutes / 60.0;

    const deepSleepHours = 1.8;
    const lightSleepHours = 4.2;
    const remSleepHours = 1.5;
    const awakeHours = 0.25;

    final deepRatio = deepSleepHours / totalDurationHours;
    final remRatio = remSleepHours / totalDurationHours;
    final awakeRatio = awakeHours / totalDurationHours;

    final mockSummary = SleepSummary(
      totalDurationHours: totalDurationHours,
      deepSleepHours: deepSleepHours,
      remSleepHours: remSleepHours,
      lightSleepHours: lightSleepHours,
      awakeHours: awakeHours,
      deepRatio: deepRatio,
      remRatio: remRatio,
      awakeRatio: awakeRatio,
      apneaCount: 2,
      snoringDuration: 45.0,
    );

    final mockBreakdown = Breakdown(
      durationScore: 90,
      deepScore: 85,
      remScore: 88,
      efficiencyScore: 92,
    );

    return SleepReport(
      sessionId: 'mock_session_id',
      userId: 'mock_user_id',
      createdAt: sleepEnd,
      totalScore: 88,
      grade: 'B+',
      message: '전반적으로 좋은 수면이었습니다.',
      summary: mockSummary,
      breakdown: mockBreakdown,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ✅ 막대 그래프 애니메이션 초기화 (1초 동안 진행, 부드러운 곡선)
    _barChartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _barChartAnimation = CurvedAnimation(
      parent: _barChartAnimationController,
      curve: Curves.easeOutCubic,
    );

    // 도넛 그래프 애니메이션 (1.2초)
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // 탭 변경 리스너
    _tabController.addListener(() {
      // 효율성 탭 (index 0) 진입 시 막대 애니메이션 재실행
      if (_tabController.index == 0) {
        _barChartAnimationController.reset();
        _barChartAnimationController.forward();
      }
      // 수면 단계 탭 (index 1) 진입 시 도넛 애니메이션 재실행
      if (_tabController.index == 1) {
        _chartAnimationController.reset();
        _chartAnimationController.forward();
      }
      // 트렌드 탭 이탈 시 터치 상태 초기화
      if (_tabController.index != 2) {
        setState(() {
          _touchedTrendIndex = null;
        });
      }
    });

    // 초기 실행 시 현재 탭에 맞는 애니메이션 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 0) {
        _barChartAnimationController.forward();
      } else if (_tabController.index == 1) {
        _chartAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _barChartAnimationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sleepProvider = Provider.of<SleepProvider>(context);
    final report = sleepProvider.latestSleepReport ?? _getMockSleepReport();

    return Scaffold(
      appBar: AppBar(
        // 폰트 크기가 커졌으므로 툴바 높이를 약간 늘려 공간을 확보합니다. 필요에 따라 조절하세요.
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
          children: [
            // ✅ 요청하신 폰트 스타일 적용 (heading1)
            Text('수면 데이터 분석', style: AppTextStyles.heading1),
            // heading1이 크므로 사이 간격을 제거하거나 아주 줄입니다.
            const SizedBox(height: 4),
            // ✅ 요청하신 폰트 스타일 적용 (secondaryBodyText)
            Text(
              '상세한 수면 패턴과 효율성을 확인해보세요',
              style: AppTextStyles.secondaryBodyText,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 날짜 범위 선택 기능 구현
            },
            child: const Text('최근 7일'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 상단 요약 카드 섹션
          _buildTopSummaryCards(report),
          const SizedBox(height: 16),

          // 2. 탭바
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryNavy,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primaryNavy,
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: AppTextStyles.bodyText.copyWith(
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: '효율성'),
              Tab(text: '수면 단계'),
              Tab(text: '트렌드'),
              Tab(text: '지난 기록'),
            ],
          ),
          // 3. 탭 내용
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _buildEfficiencyTab(report),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _buildSleepStagesTab(report),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: _buildTrendTab(),
                    ),
                    const SleepHistoryScreen(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 상단 요약 카드 섹션
  Widget _buildTopSummaryCards(SleepReport report) {
    final summary = report.summary;
    final efficiency =
        (summary.deepSleepHours +
            summary.remSleepHours +
            summary.lightSleepHours) /
        summary.totalDurationHours;
    final remRatio = summary.remRatio;
    final avgSleep = summary.totalDurationHours.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.opacity,
              title: '수면 효율',
              valueText: '${(efficiency * 100).toStringAsFixed(0)}%',
              iconColor: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.psychology,
              title: 'REM 비율',
              valueText: '${(remRatio * 100).toStringAsFixed(0)}%',
              iconColor: AppColors.successGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.access_time,
              title: '평균 수면',
              valueText: '${avgSleep}시간',
              iconColor: AppColors.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  // 개별 요약 카드
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String valueText,
    required Color iconColor,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 6),
                Text(title, style: AppTextStyles.smallText),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valueText,
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 효율성 탭 관련 위젯 ====================
  Widget _buildEfficiencyTab(SleepReport? report) {
    if (report == null) return _buildNoDataPlaceholder();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEfficiencyAnalysisCard(report),
          const SizedBox(height: 24),
          _buildSleepComparisonChart(report),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

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

  // ✅ 수정: 막대 그래프 애니메이션 확실하게 적용 (AnimatedBuilder 위치 변경)
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
            Text('누운 시간 vs 실 수면 시간', style: AppTextStyles.heading3),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 40;
                  return Column(
                    children: [
                      // X축 레이블 (시간)
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
                      // 막대 그래프 리스트
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: data.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final d = data[index];
                            // 최종 목표 너비 계산
                            final targetTotalWidth =
                                (d['total'] / maxHours) * availableWidth;
                            final targetActualWidth =
                                (d['actual'] / maxHours) * availableWidth;

                            // ✅ AnimatedBuilder를 각 아이템 내부로 이동
                            return AnimatedBuilder(
                              animation: _barChartAnimation,
                              builder: (context, child) {
                                final animationValue = _barChartAnimation.value;
                                // 현재 프레임의 너비 계산 (채워지는 효과)
                                final currentTotalWidth =
                                    targetTotalWidth * animationValue;
                                final currentActualWidth =
                                    targetActualWidth * animationValue;

                                return Row(
                                  children: [
                                    // Y축 레이블 (날짜)
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        d['date'],
                                        style: AppTextStyles.smallText,
                                      ),
                                    ),
                                    // 막대 부분
                                    Expanded(
                                      child: Stack(
                                        alignment: Alignment.centerLeft,
                                        children: [
                                          // 누운 시간 (배경 막대)
                                          Container(
                                            height: 20,
                                            width: currentTotalWidth,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryNavy
                                                  .withOpacity(0.1),
                                              // ✅ 둥근 모서리 적용
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          // 실 수면 시간 (전경 막대)
                                          Container(
                                            height: 20,
                                            width: currentActualWidth,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryNavy,
                                              // ✅ 둥근 모서리 적용
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
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
              '두 막대의 차이가 적을수록(실 수면 시간 막대가 꽉 찰수록) 수면 효율이 높은 날입니다.',
              style: AppTextStyles.smallText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 수면 단계 탭 관련 위젯 ====================
  Widget _buildSleepStagesTab(SleepReport? report) {
    if (report == null) return _buildNoDataPlaceholder();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 도넛 그래프 카드
          _buildAnimatedDonutChart(report),
          const SizedBox(height: 24),
          // 상세 정보 카드
          _buildSleepStageDetails(report),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 도넛 그래프 위젯 (애니메이션 적용)
  Widget _buildAnimatedDonutChart(SleepReport report) {
    final summary = report.summary;

    final Color deepColor = const Color(0xFF2C2C54);
    final Color lightColor = const Color(0xFF7F7F98);
    final Color remColor = const Color(0xFF4DB6AC);
    final Color awakeColor = const Color(0xFFE57373);

    // 데이터가 없거나 애니메이션 시작 전이면 빈 화면 표시
    if (summary.totalDurationHours < 0.1 ||
        !_chartAnimationController.isAnimating) {
      return Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text(
              '데이터를 불러오는 중...',
              style: AppTextStyles.secondaryBodyText,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수면 단계 분포', style: AppTextStyles.heading3),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: Center(
                child: SizedBox(
                  width: 200, // 도넛 그래프 전체 크기
                  height: 200,
                  // TweenAnimationBuilder를 사용하여 애니메이션 적용
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      // 각 단계의 누적 비율 계산
                      final deepEnd = summary.deepRatio * value;
                      final lightEnd =
                          deepEnd +
                          (summary.lightSleepHours /
                                  summary.totalDurationHours) *
                              value;
                      final remEnd = lightEnd + summary.remRatio * value;
                      final awakeEnd = remEnd + summary.awakeRatio * value;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. 배경 원
                          CircularProgressIndicator(
                            value: 1.0,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.progressBackground,
                            ),
                            strokeWidth: 25,
                          ),
                          // 2. 깬 상태 (Awake)
                          CircularProgressIndicator(
                            value: awakeEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              awakeColor,
                            ),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.round,
                          ),
                          // 3. REM 수면
                          CircularProgressIndicator(
                            value: remEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(remColor),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.round,
                          ),
                          // 4. 얕은 수면 (Light)
                          CircularProgressIndicator(
                            value: lightEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lightColor,
                            ),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.round,
                          ),
                          // 5. 깊은 수면 (Deep)
                          CircularProgressIndicator(
                            value: deepEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              deepColor,
                            ),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 수면 단계 상세 정보 위젯
  Widget _buildSleepStageDetails(SleepReport report) {
    final summary = report.summary;

    final Color deepColor = const Color(0xFF2C2C54);
    final Color lightColor = const Color(0xFF7F7F98);
    final Color remColor = const Color(0xFF4DB6AC);
    final Color awakeColor = const Color(0xFFE57373);

    String formatDuration(double hours) {
      int h = hours.floor();
      int m = ((hours - h) * 60).round();
      return '${h > 0 ? '$h시간 ' : ''}${m}분';
    }

    String formatPercentage(double ratio) {
      return '(${(ratio * 100).toStringAsFixed(0)}%)';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수면 단계별 상세 정보', style: AppTextStyles.heading3),
            const SizedBox(height: 24),
            _buildDetailRow(
              color: deepColor,
              label: '깊은 수면',
              duration: formatDuration(summary.deepSleepHours),
              percentage: formatPercentage(summary.deepRatio),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              color: lightColor,
              label: '얕은 수면',
              duration: formatDuration(summary.lightSleepHours),
              percentage: formatPercentage(
                summary.lightSleepHours / summary.totalDurationHours,
              ),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              color: remColor,
              label: 'REM 수면',
              duration: formatDuration(summary.remSleepHours),
              percentage: formatPercentage(summary.remRatio),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              color: awakeColor,
              label: '깬 상태',
              duration: formatDuration(summary.awakeHours),
              percentage: formatPercentage(summary.awakeRatio),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required Color color,
    required String label,
    required String duration,
    required String percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyText),
        const Spacer(),
        Text(
          duration,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(percentage, style: AppTextStyles.secondaryBodyText),
      ],
    );
  }

  // ==================== 트렌드 탭 구현 ====================
  Widget _buildTrendTab() {
    // 가상의 트렌드 데이터 (최근 7일)
    final List<Map<String, dynamic>> trendData = [
      {'date': '13일', 'efficiency': 88.0, 'remRatio': 18.0},
      {'date': '14일', 'efficiency': 91.0, 'remRatio': 22.0},
      {'date': '15일', 'efficiency': 85.0, 'remRatio': 15.0},
      {'date': '16일', 'efficiency': 93.0, 'remRatio': 23.0},
      {'date': '17일', 'efficiency': 89.0, 'remRatio': 19.0},
      {'date': '18일', 'efficiency': 90.0, 'remRatio': 21.0},
      {'date': '19일', 'efficiency': 92.0, 'remRatio': 20.0},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. 트렌드 차트 카드
          _buildTrendChartCard(trendData),
          const SizedBox(height: 16),

          // 2. 터치된 날짜 상세 정보 박스 (터치되었을 때만 표시)
          if (_touchedTrendIndex != null)
            _buildTrendDetailsBox(trendData[_touchedTrendIndex!]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 트렌드 꺾은선 그래프 카드 빌더
  Widget _buildTrendChartCard(List<Map<String, dynamic>> data) {
    // 수면 효율 데이터 포인트
    final List<FlSpot> efficiencySpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['efficiency'] as double))
        .toList();

    // REM 비율 데이터 포인트
    final List<FlSpot> remSpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['remRatio'] as double))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수면 효율 및 REM 트렌드', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text('그래프를 터치하여 상세 정보를 확인하세요.', style: AppTextStyles.smallText),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  // 터치 조작 활성화 및 콜백 구현
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                          // 터치가 끝나거나 유효하지 않은 경우 인덱스 초기화
                          if (event is FlTapUpEvent ||
                              event is FlPanEndEvent ||
                              touchResponse == null ||
                              touchResponse.lineBarSpots == null ||
                              touchResponse.lineBarSpots!.isEmpty) {
                            setState(() {
                              _touchedTrendIndex = null;
                            });
                          } else {
                            // 터치된 지점의 인덱스를 가져와 상태 업데이트
                            setState(() {
                              _touchedTrendIndex =
                                  touchResponse.lineBarSpots![0].spotIndex;
                            });
                          }
                        },
                    handleBuiltInTouches: true, // 기본 터치 시각 효과 활성화
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((index) {
                            // 터치된 지점에 대한 인디케이터 설정
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: AppColors.secondaryText.withOpacity(0.5),
                                strokeWidth: 1,
                              ),
                              FlDotData(show: false), // 기본 닷은 숨기고 아래에서 커스텀 닷 사용
                            );
                          }).toList();
                        },
                    // 툴팁은 그래프 위에 뜨지 않도록 비활성화 (하단 박스로 대체)
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot touchedSpot) =>
                          Colors.transparent,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          // 툴팁 내용을 비워서 그래프 위에는 아무것도 표시되지 않게 함
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: AppColors.divider, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[index]['date'],
                                style: AppTextStyles.smallText,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    // 수면 효율 선
                    LineChartBarData(
                      spots: efficiencySpots,
                      isCurved: true,
                      color: AppColors.primaryNavy,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        // 터치된 인덱스에만 닷 표시
                        checkToShowDot: (spot, barData) =>
                            spot.x == _touchedTrendIndex?.toDouble(),
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: AppColors.primaryNavy,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // REM 비율 선
                    LineChartBarData(
                      spots: remSpots,
                      isCurved: true,
                      color: AppColors.successGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        // 터치된 인덱스에만 닷 표시
                        checkToShowDot: (spot, barData) =>
                            spot.x == _touchedTrendIndex?.toDouble(),
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: AppColors.successGreen,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 터치된 날짜의 상세 정보를 보여주는 박스 위젯
  Widget _buildTrendDetailsBox(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBackground, // 약간 다른 배경색 적용
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '7월 ${data['date']} 상세 정보',
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 수면 효율 정보
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('수면 효율', style: AppTextStyles.smallText),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['efficiency']}%',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
                // REM 비율 정보
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('REM 비율', style: AppTextStyles.smallText),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['remRatio']}%',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.successGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 공통 위젯 ====================
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.smallText),
      ],
    );
  }

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
}

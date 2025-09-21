// lib/screens/data_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/sleep_data_state.dart';

class DataScreen extends StatelessWidget {
  const DataScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildMetricCards(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                isScrollable: false,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.secondaryText,
                indicatorColor: AppColors.primaryBlue,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 2.0,
                labelStyle: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: AppTextStyles.bodyText,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                tabs: const [
                  Tab(text: '효율성'),
                  Tab(text: '수면 단계'),
                  Tab(text: '트렌드'),
                  Tab(text: '개선 가이드'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: const [
                  EfficiencyTab(),
                  SleepStagesTab(),
                  TrendsTab(),
                  ImprovementGuideTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<SleepDataState>(
      builder: (context, sleepDataState, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수면 데이터 분석', style: AppTextStyles.heading1),
                    Text(
                      '상세한 수면 패턴과 효율성을 확인해보세요',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    sleepDataState.setSelectedPeriod(result);
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: '최근30일',
                          child: Text('최근30일'),
                        ),
                        const PopupMenuItem<String>(
                          value: '최근7일',
                          child: Text('최근7일'),
                        ),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          sleepDataState.selectedPeriod,
                          style: AppTextStyles.bodyText,
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricCard(
            icon: Icons.water_drop,
            color: AppColors.primaryBlue,
            title: '수면 효율',
            value: '93%',
          ),
          _buildMetricCard(
            icon: Icons.refresh,
            color: AppColors.successGreen,
            title: 'REM 비율',
            value: '20%',
          ),
          _buildMetricCard(
            icon: Icons.trending_up,
            color: AppColors.warningOrange,
            title: '일관성',
            value: '99%',
          ),
          _buildMetricCard(
            icon: Icons.access_time,
            color: AppColors.errorRed,
            title: '평균 수면',
            value: '8시간',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: AppTextStyles.smallText),
                ],
              ),
              const SizedBox(height: 10),
              Text(value, style: AppTextStyles.heading3),
            ],
          ),
        ),
      ),
    );
  }
}

class EfficiencyTab extends StatelessWidget {
  const EfficiencyTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildEfficiencyAnalysis(context)),
          const SizedBox(width: 16),
          Expanded(child: _buildSleepTimeAnalysis(context)),
        ],
      ),
    );
  }

  Widget _buildEfficiencyAnalysis(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수면 효율 분석', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            _buildBarItem(
              context,
              label: '평균 수면 효율',
              value: 93,
              description: '85% 이상이 이상적입니다',
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 10),
            _buildBarItem(
              context,
              label: 'REM 수면 비율',
              value: 20,
              description: '20~25%가 이상적입니다',
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 10),
            _buildBarItem(
              context,
              label: '우수한 수면 효율',
              value: 100,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTimeAnalysis(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('누운 시간 vs 실 수면 시간', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            _buildTimeBarItem(context, '6월23일', 94),
            _buildTimeBarItem(context, '6월24일', 91),
            _buildTimeBarItem(context, '6월25일', 91),
            _buildTimeBarItem(context, '6월26일', 90),
            _buildTimeBarItem(context, '6월27일', 90),
          ],
        ),
      ),
    );
  }

  Widget _buildBarItem(
    BuildContext context, {
    required String label,
    required double value,
    String? description,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyText),
        if (description != null)
          Text(description, style: AppTextStyles.smallText),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: AppColors.progressBackground,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 12,
        ),
      ],
    );
  }

  Widget _buildTimeBarItem(BuildContext context, String date, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(date, style: AppTextStyles.bodyText)),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: AppColors.progressBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryBlue,
              ),
              minHeight: 12,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$value%',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyText,
            ),
          ),
        ],
      ),
    );
  }
}

class SleepStagesTab extends StatelessWidget {
  const SleepStagesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('수면 단계 분포', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: AppColors.primaryBlue,
                              value: 56,
                              title: '얕은 잠56%',
                              radius: 50,
                              titleStyle: AppTextStyles.bodyText.copyWith(
                                color: AppColors.cardBackground,
                              ),
                            ),
                            PieChartSectionData(
                              color: AppColors.errorRed,
                              value: 7,
                              title: '깨어있음7%',
                              radius: 50,
                              titleStyle: AppTextStyles.smallText.copyWith(
                                color: AppColors.cardBackground,
                              ),
                            ),
                            PieChartSectionData(
                              color: AppColors.secondaryText,
                              value: 20,
                              title: 'REM 수면20%',
                              radius: 50,
                              titleStyle: AppTextStyles.smallText.copyWith(
                                color: AppColors.cardBackground,
                              ),
                            ),
                            PieChartSectionData(
                              color: AppColors.successGreen,
                              value: 24,
                              title: '깊은 잠24%',
                              radius: 50,
                              titleStyle: AppTextStyles.smallText.copyWith(
                                color: AppColors.cardBackground,
                              ),
                            ),
                          ],
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildSleepStageDetail(context)),
        ],
      ),
    );
  }

  Widget _buildSleepStageDetail(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수면 단계별 상세 정보', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            _buildDetailItem('얕은 잠', '4시간56분', AppColors.primaryBlue),
            _buildDetailItem('깊은 잠', '2시간0분', AppColors.successGreen),
            _buildDetailItem('REM 수면', '1시간40분', AppColors.secondaryText),
            _buildDetailItem('깨어있음', '0시간37분', AppColors.errorRed),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String stage, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(stage, style: AppTextStyles.bodyText)),
          Text(
            time,
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class TrendsTab extends StatefulWidget {
  const TrendsTab({Key? key}) : super(key: key);

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  // 실제 데이터 연동 시에는 이 부분을 Provider 등으로 관리해야 합니다.
  final List<FlSpot> sleepEfficiencySpots = const [
    FlSpot(0, 93),
    FlSpot(1, 95),
    FlSpot(2, 92),
    FlSpot(3, 97),
    FlSpot(4, 96),
    FlSpot(5, 95),
    FlSpot(6, 97),
    FlSpot(7, 98),
    FlSpot(8, 97),
    FlSpot(9, 99),
    FlSpot(10, 98),
    FlSpot(11, 95),
    FlSpot(12, 94),
    FlSpot(13, 93),
    FlSpot(14, 92),
    FlSpot(15, 95),
    FlSpot(16, 96),
    FlSpot(17, 98),
    FlSpot(18, 97),
    FlSpot(19, 96),
    FlSpot(20, 98),
  ];
  final List<FlSpot> remRatioSpots = const [
    FlSpot(0, 18),
    FlSpot(1, 19),
    FlSpot(2, 15),
    FlSpot(3, 20),
    FlSpot(4, 22),
    FlSpot(5, 21),
    FlSpot(6, 23),
    FlSpot(7, 25),
    FlSpot(8, 24),
    FlSpot(9, 21),
    FlSpot(10, 19),
    FlSpot(11, 20),
    FlSpot(12, 18),
    FlSpot(13, 22),
    FlSpot(14, 23),
    FlSpot(15, 25),
    FlSpot(16, 24),
    FlSpot(17, 21),
    FlSpot(18, 20),
    FlSpot(19, 22),
    FlSpot(20, 24),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('수면 효율 및 REM 트렌드', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, top: 16),
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (FlSpot spot) {
                            return AppColors.cardBackground.withOpacity(0.9);
                          },
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isSleepEfficiency = spot.barIndex == 0;
                              final dates = [
                                '7월 13일',
                                '7월 14일',
                                '7월 15일',
                                '7월 16일',
                                '7월 17일',
                                '7월 18일',
                                '7월 19일',
                                '7월 20일',
                                '7월 21일',
                                '7월 22일',
                                '7월 23일',
                                '7월 24일',
                                '7월 25일',
                                '7월 26일',
                                '7월 27일',
                                '7월 28일',
                                '7월 29일',
                                '7월 30일',
                                '7월 31일',
                                '8월 1일',
                                '8월 2일',
                              ];
                              final date = dates[spot.x.toInt()];
                              final value = spot.y.toStringAsFixed(0);
                              final title = isSleepEfficiency
                                  ? '수면 효율'
                                  : 'REM 비율';

                              return LineTooltipItem(
                                date,
                                AppTextStyles.bodyText.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '\n$title: $value%',
                                    style: AppTextStyles.smallText.copyWith(
                                      color: isSleepEfficiency
                                          ? AppColors.primaryBlue
                                          : AppColors.secondaryText,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                              return spotIndexes.map((index) {
                                final spot = barData.spots[index];
                                if (spot.x == 0 || spot.x == 20) {
                                  return null;
                                }
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: AppColors.primaryBlue,
                                    strokeWidth: 2,
                                  ),
                                  FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: AppColors.primaryBlue,
                                              strokeWidth: 2,
                                              strokeColor:
                                                  AppColors.cardBackground,
                                            ),
                                  ),
                                );
                              }).toList();
                            },
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sleepEfficiencySpots,
                          isCurved: true,
                          barWidth: 2,
                          color: AppColors.primaryBlue,
                          belowBarData: BarAreaData(show: false),
                          dotData: const FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: remRatioSpots,
                          isCurved: true,
                          barWidth: 2,
                          color: AppColors.secondaryText,
                          belowBarData: BarAreaData(show: false),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5, // 5일 간격으로 표시
                            getTitlesWidget: (value, meta) {
                              final dates = [
                                '7월 13일',
                                '7월 14일',
                                '7월 15일',
                                '7월 16일',
                                '7월 17일',
                                '7월 18일',
                                '7월 19일',
                                '7월 20일',
                                '7월 21일',
                                '7월 22일',
                                '7월 23일',
                                '7월 24일',
                                '7월 25일',
                                '7월 26일',
                                '7월 27일',
                                '7월 28일',
                                '7월 29일',
                                '7월 30일',
                                '7월 31일',
                                '8월 1일',
                                '8월 2일',
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dates.length &&
                                  value.toInt() % 5 == 0) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 8,
                                  child: Text(
                                    dates[value.toInt()],
                                    style: AppTextStyles.smallText,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderColor,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(
                            color: AppColors.borderColor,
                            width: 1,
                          ),
                          left: BorderSide(color: Colors.transparent),
                          right: BorderSide(color: Colors.transparent),
                          top: BorderSide(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImprovementGuideTab extends StatelessWidget {
  const ImprovementGuideTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: AppColors.successGreen.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('훌륭한 수면 패턴', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(
                      '현재 수면 패턴이 매우 양호합니다.',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '권장 사항:',
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '현재 수면 습관을 유지하세요.',
                      style: AppTextStyles.secondaryBodyText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/screens/data_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/sleep_data_state.dart';
import 'dart:math'; // ✅ 최대값 계산을 위해 추가!

class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

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
                labelColor: AppColors.primaryNavy,
                unselectedLabelColor: AppColors.secondaryText,
                indicatorColor: AppColors.primaryNavy,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    sleepDataState.selectedPeriod, // '최근7일'
                    style: AppTextStyles.bodyText,
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
            color: AppColors.primaryNavy,
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
                  Expanded(child: Text(title, style: AppTextStyles.smallText)),
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

// ------------------------------------------------------------------
// EfficiencyTab (7일치 데이터 연동)
// ------------------------------------------------------------------

class EfficiencyTab extends StatelessWidget {
  const EfficiencyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepData = Provider.of<SleepDataState>(context);
    final tibTstData = sleepData.tibTstData;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEfficiencyAnalysis(context),
          const SizedBox(height: 16),
          _buildSleepTimeAnalysis(context, tibTstData),
          const SizedBox(height: 16),
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
              color: AppColors.primaryNavy,
            ),
            const SizedBox(height: 10),
            _buildBarItem(
              context,
              label: 'REM 수면 비율',
              value: 20,
              description: '20~25%가 이상적입니다',
              color: AppColors.primaryNavy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTimeAnalysis(BuildContext context, List<TstTibData> data) {
    double maxTib = 0;
    if (data.isNotEmpty) {
      maxTib = data.map((e) => e.tib).reduce(max);
    }
    final double maxValue = (maxTib + 1).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('누운 시간 대비 실 수면 시간', style: AppTextStyles.heading3),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: RotatedBox(
                quarterTurns: 1,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.cardBackground,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dayLabel = data[group.x.toInt()].dayLabel;
                          final item = data[group.x.toInt()];

                          String label;
                          double value;
                          if (rodIndex == 0) {
                            label = '실 수면 시간';
                            value = item.tst;
                          } else {
                            label = '전체 누운 시간';
                            value = item.tib;
                          }

                          final tooltipText =
                              '$dayLabel\n$label: ${value.toStringAsFixed(1)}시간';

                          return BarTooltipItem(
                            tooltipText,
                            AppTextStyles.smallText.copyWith(
                              color: AppColors.primaryNavy,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 2,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text(
                                  '${value.toInt()}h',
                                  style: AppTextStyles.smallText,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value < 0 || value >= data.length) {
                              return const SizedBox();
                            }
                            final label = data[value.toInt()].dayLabel;
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Text(
                                  label,
                                  style: AppTextStyles.smallText,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      drawHorizontalLine: true,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: AppColors.borderColor, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _getBarGroups(data),
                    maxY: maxValue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  AppColors.lightGrey,
                  '누운 시간',
                  isBackground: true,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(AppColors.primaryNavy, '실 수면 시간'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '진한 색 막대가 연한 색 배경을 많이 채울수록 수면 효율이 높은 날입니다.',
              style: AppTextStyles.secondaryBodyText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    Color color,
    String text, {
    bool isBackground = false,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isBackground
                ? Border.all(
                    color: AppColors.primaryNavy.withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.smallText),
      ],
    );
  }

  List<BarChartGroupData> _getBarGroups(List<TstTibData> data) {
    return List.generate(data.length, (index) {
      final item = data[index];
      const double barThickness = 20;

      return BarChartGroupData(
        x: index,
        groupVertically: true,
        barRods: [
          BarChartRodData(
            toY: item.tst,
            color: AppColors.primaryNavy,
            width: barThickness,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: item.tib - item.tst,
            color: AppColors.lightGrey,
            width: barThickness,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
        ],
        showingTooltipIndicators: [],
      );
    });
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
}

// ------------------------------------------------------------------
// SleepStagesTab, TrendsTab, ImprovementGuideTab
// ------------------------------------------------------------------

class SleepStagesTab extends StatelessWidget {
  const SleepStagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
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
                            color: AppColors.lightSleepColor,
                            value: 60,
                            title: 'Light 60%',
                            radius: 50,
                            titleStyle: AppTextStyles.bodyText.copyWith(
                              color: AppColors.cardBackground,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.deepSleepColor,
                            value: 20,
                            title: 'Deep 20%',
                            radius: 50,
                            titleStyle: AppTextStyles.smallText.copyWith(
                              color: AppColors.cardBackground,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.remColor,
                            value: 15,
                            title: 'REM 15%',
                            radius: 50,
                            titleStyle: AppTextStyles.smallText.copyWith(
                              color: AppColors.cardBackground,
                            ),
                          ),
                          PieChartSectionData(
                            color: AppColors.awakeColor,
                            value: 5,
                            title: 'Awake 5%',
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
          const SizedBox(height: 16),
          _buildSleepStageDetail(context),
          const SizedBox(height: 16),
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
            _buildDetailItem('Light', '4시간 30분', AppColors.lightSleepColor),
            _buildDetailItem('Deep', '1시간 40분', AppColors.deepSleepColor),
            _buildDetailItem('REM', '1시간 15분', AppColors.remColor),
            _buildDetailItem('Awake', '0시간 25분', AppColors.awakeColor),
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

class TrendsTab extends StatelessWidget {
  const TrendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepData = Provider.of<SleepDataState>(context);
    final trendMetrics = sleepData.trendMetrics;

    if (trendMetrics.isEmpty) {
      return const Center(child: Text("트렌드 데이터가 없습니다."));
    }

    final List<FlSpot> sleepEfficiencySpots = [];
    final List<FlSpot> remRatioSpots = [];
    final List<String> dates = [];

    for (int i = 0; i < trendMetrics.length; i++) {
      sleepEfficiencySpots.add(
        FlSpot(i.toDouble(), trendMetrics[i].sleepEfficiency),
      );
      remRatioSpots.add(FlSpot(i.toDouble(), trendMetrics[i].remRatio));
      dates.add(trendMetrics[i].reportDate);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('수면 효율 및 REM 트렌드', style: AppTextStyles.heading3),
              const SizedBox(height: 50),
              SizedBox(
                height: 250,
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
                              final date = dates[spot.x.toInt()];
                              final value = spot.y.toStringAsFixed(1);
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
                                          ? AppColors.primaryNavy
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
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: AppColors.primaryNavy,
                                    strokeWidth: 2,
                                  ),
                                  FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: AppColors.primaryNavy,
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
                          color: AppColors.primaryNavy,
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
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dates.length) {
                                String day = dates[value.toInt()].split(' ')[1];

                                // 🔥 여기가 수정된 부분입니다!
                                return SideTitleWidget(
                                  axisSide: meta
                                      .axisSide, // meta: meta 대신 axisSide를 사용해야 합니다.
                                  space: 8,
                                  child: Text(
                                    day,
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
  const ImprovementGuideTab({super.key});

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

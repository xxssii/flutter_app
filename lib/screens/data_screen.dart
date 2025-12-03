// lib/screens/data_screen.dart
// ✅ 수정된 버전: Firebase 실제 데이터 사용

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../providers/sleep_provider.dart';
import '../models/sleep_report_model.dart';
import '../state/app_state.dart';
import '../state/sleep_data_state.dart'; // ✅ SleepDataState 추가!
import 'sleep_history_screen.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // 애니메이션 컨트롤러
  late AnimationController _barChartAnimationController;
  late Animation<double> _barChartAnimation;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  int? _touchedTrendIndex;
  int? _touchedBarIndex;

  // 색상 정의
  final Color _mainDeepColor = const Color(0xFF011F25);
  final Color _lightSleepColor = const Color(0xFF1B4561);
  final Color _remSleepColor = const Color(0xFF6292BE);
  final Color _awakeColor = const Color(0xFFBD9A8E);
  final Color _themeLightGray = const Color(0xFFB5C1D4);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ✅ 화면 진입 시 Firebase에서 실제 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromFirebase();
    });

    _barChartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _barChartAnimation = CurvedAnimation(
      parent: _barChartAnimationController,
      curve: Curves.easeOutCubic,
    );

    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _barChartAnimationController.reset();
        _barChartAnimationController.forward();
      }
      if (_tabController.index == 1) {
        _chartAnimationController.reset();
        _chartAnimationController.forward();
      }
      if (_tabController.index != 2) {
        setState(() {
          _touchedTrendIndex = null;
        });
      }
      if (_tabController.index != 0) {
        setState(() {
          _touchedBarIndex = null;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 0) {
        _barChartAnimationController.forward();
      } else if (_tabController.index == 1) {
        _chartAnimationController.forward();
      }
    });
  }

  // ✅ Firebase에서 데이터 가져오는 함수
  Future<void> _loadDataFromFirebase() async {
    try {
      print('🔄 DataScreen: Firebase에서 데이터 가져오기 시작!');
      
      final sleepDataState = Provider.of<SleepDataState>(context, listen: false);
      await sleepDataState.fetchAllSleepReports('demoUser');  // ✅ context 제거!
      
      print('✅ DataScreen: 데이터 가져오기 완료!');
      print('📊 가져온 데이터 개수: ${sleepDataState.sleepHistory.length}개');
    } catch (e) {
      print('❌ DataScreen 데이터 가져오기 실패: $e');
    }
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
    return Consumer<SleepDataState>(
      builder: (context, sleepDataState, child) {
        // ✅ 로딩 중 처리
        if (sleepDataState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ 데이터가 없으면 안내 메시지
        if (sleepDataState.sleepHistory.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.nights_stay_outlined, size: 64, color: AppColors.secondaryText),
                  const SizedBox(height: 16),
                  Text('수면 데이터가 없습니다.', style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  Text('홈 화면에서 구름 버튼(☁️)을 눌러\n7일치 데이터를 생성해주세요!',
                    style: AppTextStyles.secondaryBodyText,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 35.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('수면 데이터 분석', style: AppTextStyles.heading1),
                          const SizedBox(height: 4),
                          Text(
                            '상세한 수면 패턴과 효율성을 확인해보세요',
                            style: AppTextStyles.secondaryBodyText,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('현재 최근 7일간의 데이터를 보여주고 있습니다.'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: Text(
                          '최근 7일',
                          style: AppTextStyles.bodyText.copyWith(
                            color: AppColors.primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildTopSummaryCards(sleepDataState),
              const SizedBox(height: 16),
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEfficiencyTab(sleepDataState),
                    _buildSleepStagesTab(sleepDataState),
                    _buildTrendTab(sleepDataState),
                    const SleepHistoryScreen(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ 상단 요약 카드 - Firebase 데이터 사용!
  Widget _buildTopSummaryCards(SleepDataState sleepDataState) {
    final history = sleepDataState.sleepHistory;
    
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    // 최근 7일 데이터로 평균 계산
    final recent7Days = history.take(7).toList();
    
    double totalSleepHours = 0;
    double totalTimeInBed = 0;
    double totalRemRatio = 0;
    
    for (var data in recent7Days) {
      totalSleepHours += data.totalSleepDuration;
      totalTimeInBed += data.timeInBed;
      totalRemRatio += data.remRatio;
    }
    
    final count = recent7Days.length;
    final avgSleepHours = totalSleepHours / count;
    final avgEfficiency = (totalSleepHours / totalTimeInBed) * 100;
    final avgRemRatio = totalRemRatio / count;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.opacity,
              title: '수면 효율',
              valueText: '${avgEfficiency.toStringAsFixed(0)}%',
              iconColor: _mainDeepColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.psychology,
              title: 'REM 비율',
              valueText: '${avgRemRatio.toStringAsFixed(0)}%',
              iconColor: _remSleepColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.access_time,
              title: '평균 수면',
              valueText: '${avgSleepHours.toStringAsFixed(1)}시간',
              iconColor: _lightSleepColor,
            ),
          ),
        ],
      ),
    );
  }

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.smallText),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valueText,
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primaryNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 효율성 탭 - Firebase 데이터 사용!
  Widget _buildEfficiencyTab(SleepDataState sleepDataState) {
    if (sleepDataState.sleepHistory.isEmpty) {
      return _buildNoDataPlaceholder();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEfficiencyAnalysisCard(sleepDataState),
          const SizedBox(height: 24),
          _buildSleepComparisonChart(sleepDataState),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ✅ 수면 효율 분석 카드 - Firebase 데이터 사용!
  Widget _buildEfficiencyAnalysisCard(SleepDataState sleepDataState) {
    final recent7Days = sleepDataState.sleepHistory.take(7).toList();
    
    // 평균 계산
    double totalSleepHours = 0;
    double totalTimeInBed = 0;
    double totalRemRatio = 0;
    double totalDeepRatio = 0;
    
    for (var data in recent7Days) {
      totalSleepHours += data.totalSleepDuration;
      totalTimeInBed += data.timeInBed;
      totalRemRatio += data.remRatio;
      totalDeepRatio += data.deepSleepRatio;
    }
    
    final count = recent7Days.length;
    final avgEfficiency = (totalSleepHours / totalTimeInBed) * 100;
    final avgRemRatio = totalRemRatio / count;
    final avgDeepRatio = totalDeepRatio / count;

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
              value: '${avgEfficiency.toStringAsFixed(0)}%',
              description: '85% 이상이 이상적입니다.',
              isPositive: avgEfficiency >= 85,
            ),
            const Divider(color: AppColors.divider, height: 24),
            _buildAnalysisItem(
              title: 'REM 수면 비율',
              value: '${avgRemRatio.toStringAsFixed(0)}%',
              description: '20~25%가 이상적입니다.',
              isPositive: avgRemRatio >= 20 && avgRemRatio <= 25,
            ),
            const Divider(color: AppColors.divider, height: 24),
            _buildAnalysisItem(
              title: '깊은 수면 비율',
              value: '${avgDeepRatio.toStringAsFixed(0)}%',
              description: '15~20%가 이상적입니다.',
              isPositive: avgDeepRatio >= 15 && avgDeepRatio <= 20,
              alertMessage: avgDeepRatio < 15 ? '깊은 수면이 약간 부족합니다.' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 누운 시간 vs 실 수면 시간 차트 - Firebase 데이터 사용!
  Widget _buildSleepComparisonChart(SleepDataState sleepDataState) {
    final recent7Days = sleepDataState.sleepHistory.take(7).toList().reversed.toList();
    
    // Firebase 데이터를 차트 형식으로 변환
    final List<Map<String, dynamic>> data = recent7Days.map((sleepData) {
      // sessionId에서 날짜 추출 (예: "session-2024-12-03" -> "12/03")
      String dateLabel = '-';
      try {
        final sessionId = sleepData.reportDate;
        if (sessionId.contains('-')) {
          final parts = sessionId.split('-');
          if (parts.length >= 3) {
            final month = parts[parts.length - 2];
            final day = parts[parts.length - 1];
            dateLabel = '$month/$day';
          }
        }
      } catch (e) {
        print('날짜 파싱 에러: $e');
      }
      
      return {
        'date': dateLabel,
        'total': sleepData.timeInBed,  // 누운 시간
        'actual': sleepData.totalSleepDuration,  // 실제 수면 시간
      };
    }).toList();

    if (data.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Text('데이터가 없습니다', style: AppTextStyles.secondaryBodyText),
          ),
        ),
      );
    }

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
            if (_touchedBarIndex != null && _touchedBarIndex! < data.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildBarChartTooltip(data[_touchedBarIndex!]),
              ),
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
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final d = data[index];
                            final targetTotalWidth = (d['total'] / maxHours) * availableWidth;
                            final targetActualWidth = (d['actual'] / maxHours) * availableWidth;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_touchedBarIndex == index) {
                                    _touchedBarIndex = null;
                                  } else {
                                    _touchedBarIndex = index;
                                  }
                                });
                              },
                              child: AnimatedBuilder(
                                animation: _barChartAnimation,
                                builder: (context, child) {
                                  final animationValue = _barChartAnimation.value;
                                  final currentTotalWidth = targetTotalWidth * animationValue;
                                  final currentActualWidth = targetActualWidth * animationValue;

                                  return Row(
                                    children: [
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          d['date'],
                                          style: AppTextStyles.smallText.copyWith(
                                            fontWeight: _touchedBarIndex == index
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: _touchedBarIndex == index
                                                ? AppColors.primaryNavy
                                                : AppColors.secondaryText,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.centerLeft,
                                          children: [
                                            Container(
                                              height: 20,
                                              width: currentTotalWidth,
                                              decoration: BoxDecoration(
                                                color: _themeLightGray,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            Container(
                                              height: 20,
                                              width: currentActualWidth,
                                              decoration: BoxDecoration(
                                                color: _mainDeepColor,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
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
                _buildLegendItem(_themeLightGray, '누운 시간'),
                const SizedBox(width: 24),
                _buildLegendItem(_mainDeepColor, '실 수면 시간'),
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

  Widget _buildBarChartTooltip(Map<String, dynamic> data) {
    final total = data['total'].toStringAsFixed(1);
    final actual = data['actual'].toStringAsFixed(1);
    final efficiency = ((data['actual'] / data['total']) * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNavy.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data['date']} 상세 정보',
                style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '수면 효율: $efficiency%',
                style: AppTextStyles.smallText.copyWith(color: AppColors.primaryNavy),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                children: [
                  _buildLegendItem(_themeLightGray, '누운 시간'),
                  const SizedBox(height: 4),
                  Text(
                    '${total}h',
                    style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  _buildLegendItem(_mainDeepColor, '실 수면'),
                  const SizedBox(height: 4),
                  Text(
                    '${actual}h',
                    style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 나머지 함수들은 동일하게 유지...
  Widget _buildSleepStagesTab(SleepDataState sleepDataState) {
    if (sleepDataState.sleepHistory.isEmpty) {
      return _buildNoDataPlaceholder();
    }

    // 최신 데이터 사용
    final latestData = sleepDataState.todayMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAnimatedDonutChart(latestData),
          const SizedBox(height: 24),
          _buildSleepStageDetails(latestData),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnimatedDonutChart(SleepMetrics metrics) {
    final totalDuration = metrics.totalSleepDuration;
    
    if (totalDuration < 0.1) {
      return Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text('데이터를 불러오는 중...', style: AppTextStyles.secondaryBodyText),
          ),
        ),
      );
    }

    // ✅ 실제 비율 계산 (전체 누운 시간 기준)
    final deepSleepHours = (totalDuration * metrics.deepSleepRatio) / 100;
    final remSleepHours = (totalDuration * metrics.remRatio) / 100;
    final awakeDuration = metrics.timeInBed - totalDuration;
    final lightSleepHours = totalDuration - deepSleepHours - remSleepHours;
    
    final deepRatio = deepSleepHours / metrics.timeInBed;
    final lightRatio = lightSleepHours / metrics.timeInBed;
    final remRatio = remSleepHours / metrics.timeInBed;
    final awakeRatio = awakeDuration / metrics.timeInBed;

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
                  width: 200,
                  height: 200,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      final deepEnd = deepRatio * value;
                      final lightEnd = deepEnd + lightRatio * value;
                      final remEnd = lightEnd + remRatio * value;
                      final awakeEnd = remEnd + awakeRatio * value;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.progressBackground,
                            ),
                            strokeWidth: 25,
                          ),
                          CircularProgressIndicator(
                            value: awakeEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(_awakeColor),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.butt,
                          ),
                          CircularProgressIndicator(
                            value: remEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(_remSleepColor),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.butt,
                          ),
                          CircularProgressIndicator(
                            value: lightEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(_lightSleepColor),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.butt,
                          ),
                          CircularProgressIndicator(
                            value: deepEnd,
                            valueColor: AlwaysStoppedAnimation<Color>(_mainDeepColor),
                            strokeWidth: 25,
                            strokeCap: StrokeCap.butt,
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

  Widget _buildSleepStageDetails(SleepMetrics metrics) {
    String formatDuration(double hours) {
      int h = hours.floor();
      int m = ((hours - h) * 60).round();
      return '${h > 0 ? '$h시간 ' : ''}${m}분';
    }

    String formatPercentage(double ratio) {
      return '(${ratio.toStringAsFixed(0)}%)';
    }

    // ✅ 실제 시간 계산
    final deepSleepHours = (metrics.totalSleepDuration * metrics.deepSleepRatio) / 100;
    final remSleepHours = (metrics.totalSleepDuration * metrics.remRatio) / 100;
    
    // ✅ timeInBed에서 totalSleepDuration을 빼면 깬 시간!
    final awakeDuration = metrics.timeInBed - metrics.totalSleepDuration;
    
    // ✅ 얕은 수면 = 전체 수면 - 깊은 수면 - REM
    final lightSleepHours = metrics.totalSleepDuration - deepSleepHours - remSleepHours;
    
    // ✅ 비율 계산 (전체 누운 시간 기준)
    final lightSleepRatio = (lightSleepHours / metrics.timeInBed) * 100;
    final awakeRatio = (awakeDuration / metrics.timeInBed) * 100;
    final deepRatioAdjusted = (deepSleepHours / metrics.timeInBed) * 100;
    final remRatioAdjusted = (remSleepHours / metrics.timeInBed) * 100;

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
              color: _mainDeepColor,
              label: '깊은 수면',
              duration: formatDuration(deepSleepHours),
              percentage: formatPercentage(deepRatioAdjusted),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              color: _lightSleepColor,
              label: '얕은 수면',
              duration: formatDuration(lightSleepHours),
              percentage: formatPercentage(lightSleepRatio),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              color: _remSleepColor,
              label: 'REM 수면',
              duration: formatDuration(remSleepHours),
              percentage: formatPercentage(remRatioAdjusted),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              color: _awakeColor,
              label: '깬 상태',
              duration: formatDuration(awakeDuration),
              percentage: formatPercentage(awakeRatio),
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

  Widget _buildTrendTab(SleepDataState sleepDataState) {
    // Firebase 데이터를 트렌드 형식으로 변환
    final recent7Days = sleepDataState.sleepHistory.take(7).toList().reversed.toList();
    
    final List<Map<String, dynamic>> trendData = recent7Days.map((data) {
      // 날짜 추출
      String dateLabel = '-';
      try {
        final sessionId = data.reportDate;
        if (sessionId.contains('-')) {
          final parts = sessionId.split('-');
          if (parts.length >= 3) {
            final day = parts[parts.length - 1];
            dateLabel = '${day}일';
          }
        }
      } catch (e) {
        print('날짜 파싱 에러: $e');
      }

      final efficiency = (data.totalSleepDuration / data.timeInBed) * 100;
      
      return {
        'date': dateLabel,
        'efficiency': efficiency,
        'remRatio': data.remRatio,
      };
    }).toList();

    if (trendData.isEmpty) {
      return _buildNoDataPlaceholder();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildTrendChartCard(trendData),
          const SizedBox(height: 16),
          if (_touchedTrendIndex != null && _touchedTrendIndex! < trendData.length)
            _buildTrendDetailsBox(trendData[_touchedTrendIndex!]),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard(List<Map<String, dynamic>> data) {
    final List<FlSpot> efficiencySpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['efficiency'] as double))
        .toList();

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
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      if (event is FlTapUpEvent ||
                          event is FlPanEndEvent ||
                          touchResponse == null ||
                          touchResponse.lineBarSpots == null ||
                          touchResponse.lineBarSpots!.isEmpty) {
                        setState(() {
                          _touchedTrendIndex = null;
                        });
                      } else {
                        setState(() {
                          _touchedTrendIndex = touchResponse.lineBarSpots![0].spotIndex;
                        });
                      }
                    },
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: AppColors.secondaryText.withOpacity(0.5),
                            strokeWidth: 1,
                          ),
                          FlDotData(show: false),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot touchedSpot) => Colors.transparent,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) => null).toList();
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
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              child: Text(data[index]['date'], style: AppTextStyles.smallText),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: data.length.toDouble() - 1,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: efficiencySpots,
                      isCurved: true,
                      color: _mainDeepColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) => spot.x == _touchedTrendIndex?.toDouble(),
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: _mainDeepColor,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: remSpots,
                      isCurved: true,
                      color: _remSleepColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, barData) => spot.x == _touchedTrendIndex?.toDouble(),
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: _remSleepColor,
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

  Widget _buildTrendDetailsBox(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${data['date']} 상세 정보',
              style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: _mainDeepColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('수면 효율', style: AppTextStyles.smallText),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['efficiency'].toStringAsFixed(0)}%',
                      style: AppTextStyles.heading3.copyWith(color: _mainDeepColor),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: _remSleepColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('REM 비율', style: AppTextStyles.smallText),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['remRatio'].toStringAsFixed(0)}%',
                      style: AppTextStyles.heading3.copyWith(color: _remSleepColor),
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
                color: isPositive ? _mainDeepColor : _awakeColor,
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
              Icon(Icons.info_outline, color: _awakeColor, size: 16),
              const SizedBox(width: 4),
              Text(
                alertMessage,
                style: AppTextStyles.smallText.copyWith(color: _awakeColor),
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
          Icon(Icons.nights_stay_outlined, size: 48, color: AppColors.secondaryText),
          SizedBox(height: 16),
          Text('수면 데이터가 없습니다.', style: AppTextStyles.secondaryBodyText),
        ],
      ),
    );
  }
}
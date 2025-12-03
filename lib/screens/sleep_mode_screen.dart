// lib/screens/sleep_mode_screen.dart

import 'dart:async'; // 타이머 사용을 위해 추가
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/ble_service.dart'; // BleService import 필수
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class SleepModeScreen extends StatefulWidget {
  const SleepModeScreen({Key? key}) : super(key: key);

  @override
  State<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends State<SleepModeScreen>
    with TickerProviderStateMixin {
  // 심박수 애니메이션 컨트롤러
  late AnimationController _heartAnimationController;
  late Animation<double> _heartBeatAnimation; // 박동 (크기 변화)
  late Animation<double> _heartGlowAnimation; // 글로우 (빛나는 효과)

  // 산소포화도 글로우 애니메이션 컨트롤러 (물결은 제거)
  late AnimationController _spo2GlowAnimationController;
  late Animation<double> _spo2GlowAnimation;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------
    // 심박수 애니메이션 초기화
    // ----------------------------------------------------
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 한 번의 박동 시간
    )..repeat(reverse: true); // 계속 반복 (커졌다가 작아지기)

    // 크기 변화 애니메이션 (예: 1.0배에서 1.2배로 커졌다가 다시 1.0배)
    _heartBeatAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeInOut, // 부드러운 박동 효과
      ),
    );

    // 글로우 애니메이션: 박동에 맞춰 그림자 퍼짐 정도를 0에서 15로 변화
    _heartGlowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.easeIn, // 빛이 빠르게 커졌다가 서서히 줄어드는 느낌
      ),
    );

    // ----------------------------------------------------
    // 산소포화도 글로우 애니메이션 초기화 (물결 대신 단순히 빛나는 효과)
    // ----------------------------------------------------
    _spo2GlowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 글로우 주기
    )..repeat(reverse: true); // 반복 (밝아졌다가 어두워지기)

    _spo2GlowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _spo2GlowAnimationController,
        curve: Curves.easeInOut, // 부드럽게 빛남
      ),
    );
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    _spo2GlowAnimationController.dispose();
    super.dispose();
  }

  // ====================================================
  // 🧪 [시뮬레이션 로직] 특정 시간 동안 동작 후 자동 정지
  // ====================================================
  void _triggerSimulation(BuildContext context, BleService ble, String command, String label, int durationSec) {
    // 1. 동작 시작 명령 전송
    ble.sendRawCommand(command);
    
    // 2. 알림 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚨 $label 감지됨! → 베개 동작 시작 ($durationSec초)"),
        backgroundColor: Colors.orangeAccent,
        duration: Duration(seconds: durationSec),
      ),
    );

    // 3. 설정된 시간 후 정지 명령 전송
    Timer(Duration(seconds: durationSec), () {
      if(mounted) {
        // 공기 관련 명령이었으면 'a'(공기만 멈춤), 진동이었으면 '9'(진동 끄기)
        if (command == '7' || command == '8') {
           ble.sendRawCommand('9'); // 진동 끄기
        } else {
           ble.sendRawCommand('a'); // 공기 멈춤
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ 상황 해제 → 동작 정지"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  // 🧪 시뮬레이션 패널 (Bottom Sheet)
  void _showSimulationPanel(BuildContext context) {
    final ble = Provider.of<BleService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🧪 이벤트 시뮬레이터", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 8),
              const Text("상황 발생 시 베개가 어떻게 반응하는지 테스트합니다.", 
                style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // 1. 코골이 시뮬레이션
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.mic, color: Colors.white),
                ),
                title: const Text("코골이 발생 (Snoring)"),
                subtitle: const Text("반응: 목 부분 높이기 (6초)"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    Navigator.pop(context); // 창 닫기
                    // '1'번 명령: Cell 1(목) 주입
                    _triggerSimulation(context, ble, '1', "코골이", 6);
                  },
                  child: const Text("발생"),
                ),
              ),
              const Divider(),

              // 2. 무호흡 시뮬레이션
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                ),
                title: const Text("무호흡 감지 (Apnea)"),
                subtitle: const Text("반응: 강한 진동 알림 (5초)"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    // '7'번 명령: 진동 강하게
                    _triggerSimulation(context, ble, '7', "무호흡(저산소)", 5);
                  },
                  child: const Text("발생"),
                ),
              ),
              const Divider(),

              // 3. 뒤척임 시뮬레이션
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.rotate_right, color: Colors.white),
                ),
                title: const Text("심한 뒤척임 (Tossing)"),
                subtitle: const Text("반응: 머리 부분 높이기 (4초)"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: () {
                    Navigator.pop(context);
                    // '2'번 명령: Cell 2(머리) 주입
                    _triggerSimulation(context, ble, '2', "뒤척임", 4);
                  },
                  child: const Text("발생"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final heartRate = appState.currentHeartRate.toStringAsFixed(0);
        final spo2 = appState.currentSpo2.toStringAsFixed(0);

        return Scaffold(
          backgroundColor:
              const Color(0xFF011F25), // AppColors. 를 지웁니다., // 측정 중 배경색
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.cardBackground,
              ),
              onPressed: () {
                appState.toggleMeasurement(context);
              },
            ),
            // ✅ [추가됨] 우측 상단 시뮬레이션 버튼
            actions: [
              IconButton(
                icon: const Icon(Icons.science, color: Colors.white), // 실험실 아이콘
                tooltip: "시뮬레이션 패널 열기",
                onPressed: () => _showSimulationPanel(context),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. 심박수 지표 표시 영역
                _buildHeartRateDisplay(
                  value: '$heartRate bpm',
                  label: '심박수',
                  color: AppColors.errorRed,
                  scaleAnimation: _heartBeatAnimation,
                  glowAnimation: _heartGlowAnimation,
                ),
                const SizedBox(height: 30),

                // 2. 산소포화도 지표 표시 영역 (물방울 아이콘 + 글로우)
                _buildSpo2Display(
                  value: '$spo2 %',
                  label: '산소포화도',
                  color: AppColors.successGreen,
                  glowAnimation: _spo2GlowAnimation,
                ),

                const Spacer(flex: 3),

                // 3. 수면 기록 중 텍스트
                Text(
                  '수면 기록 중...',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.cardBackground,
                  ),
                ),
                
                // 시뮬레이션 안내 텍스트 (작게 추가)
                const SizedBox(height: 8),
                const Text(
                  "상단 🧪 아이콘을 눌러 동작을 테스트하세요",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),

                const SizedBox(height: 16),

                // 4. 측정 종료 버튼 (달 아이콘)
                ElevatedButton(
                  onPressed: () {
                    // 데이터 수집 중지 (BleService)
                    final ble = Provider.of<BleService>(context, listen: false);
                    ble.stopDataCollection();
                    
                    appState.toggleMeasurement(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // 투명 배경
                    foregroundColor: Colors.white, // 눌렀을 때 색상
                    shape: const CircleBorder(
                      side: BorderSide(
                        color: Colors.white,
                        width: 2.5,
                      ), // 흰색 테두리
                    ),
                    padding: const EdgeInsets.all(35),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.nightlight_round, // 달 아이콘
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '측정 종료',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyText.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        );
      },
    );
  }

  // 심박수 애니메이션 전용 헬퍼 위젯
  Widget _buildHeartRateDisplay({
    required String value,
    required String label,
    required Color color,
    required Animation<double> scaleAnimation,
    required Animation<double> glowAnimation,
  }) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([scaleAnimation, glowAnimation]),
          builder: (context, child) {
            final blurRadius = glowAnimation.value;
            final opacity = (glowAnimation.value / 15.0) * 0.7;

            Widget iconWidget = Icon(Icons.favorite, size: 60, color: color);

            iconWidget = Transform.scale(
              scale: scaleAnimation.value,
              child: iconWidget,
            );

            iconWidget = Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(opacity),
                    blurRadius: blurRadius,
                    spreadRadius: blurRadius * 0.1,
                  ),
                ],
              ),
              child: iconWidget,
            );

            return iconWidget;
          },
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.cardBackground,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // 산소포화도 애니메이션 전용 헬퍼 위젯 (기본 물방울 아이콘 + 글로우)
  Widget _buildSpo2Display({
    required String value,
    required String label,
    required Color color,
    required Animation<double> glowAnimation, // 글로우 애니메이션
  }) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: glowAnimation,
          builder: (context, child) {
            final blurRadius = glowAnimation.value;
            final opacity = (glowAnimation.value / 10.0) * 0.7; // 글로우 최대치 10.0

            Widget iconWidget = Icon(
              Icons.water_drop, // 깔끔한 기본 물방울 아이콘
              size: 60,
              color: color,
            );

            iconWidget = Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle, // 물방울 주변에 원형 글로우 효과를 줌
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(opacity),
                    blurRadius: blurRadius,
                    spreadRadius: blurRadius * 0.1,
                  ),
                ],
              ),
              child: iconWidget,
            );

            return iconWidget;
          },
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.cardBackground,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

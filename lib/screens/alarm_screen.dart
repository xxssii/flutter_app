import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/ble_service.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({Key? key}) : super(key: key);

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _timer;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    // 펄스 애니메이션 컨트롤러 (무한 반복)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _stopAlarm() {
    final bleService = Provider.of<BleService>(context, listen: false);
    bleService.stopVibration();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.background;
    final textColor =
        isDarkMode ? AppColors.darkPrimaryText : AppColors.primaryText;
    final accentColor =
        isDarkMode ? AppColors.darkPrimaryNavy : AppColors.primaryNavy;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // 1. 펄스 애니메이션 아이콘 (유지)
            Stack(
              alignment: Alignment.center,
              children: [
                _buildRipple(_pulseController, 0.0, isDarkMode, accentColor),
                _buildRipple(_pulseController, 0.5, isDarkMode, accentColor),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(25),
                  child: Icon(
                    Icons.alarm,
                    color: accentColor,
                    size: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // 2. 현재 시간 (기존 앱 스타일로 변경)
            Text(
              _currentTime,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 60,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 3. 메시지
            Text(
              "일어날 시간이에요!",
              style: AppTextStyles.heading2.copyWith(
                color: isDarkMode
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
                fontWeight: FontWeight.normal,
              ),
            ),
            const Spacer(flex: 3),

            // 4. 밀어서 알람 끄기 (Slide to Stop) - 색상 조정
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              child: SlideToStop(
                onSlideCompleted: _stopAlarm,
                isDarkMode: isDarkMode,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRipple(AnimationController controller, double delay,
      bool isDarkMode, Color accentColor) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value + delay) % 1.0;
        final size = 100.0 + (value * 150.0);
        final opacity = (1.0 - value).clamp(0.0, 1.0);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(alpha: opacity * 0.5),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}

// ✅ 커스텀 슬라이드 버튼 위젯
class SlideToStop extends StatefulWidget {
  final VoidCallback onSlideCompleted;
  final bool isDarkMode;
  final Color accentColor;

  const SlideToStop({
    Key? key,
    required this.onSlideCompleted,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<SlideToStop> createState() => _SlideToStopState();
}

class _SlideToStopState extends State<SlideToStop> {
  double _dragValue = 0.0;
  final double _knobSize = 50.0;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDarkMode ? Colors.white : Colors.black;
    final containerColor = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final borderColor = widget.isDarkMode ? Colors.white24 : Colors.black12;

    return LayoutBuilder(builder: (context, constraints) {
      final double maxWidth = constraints.maxWidth;
      final double maxDrag = maxWidth - _knobSize - 10; // 10 is padding

      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
          children: [
            // 배경 텍스트
            Center(
              child: Opacity(
                opacity: (1 - (_dragValue / maxDrag)).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "밀어서 알람 끄기 ",
                      style: TextStyle(
                        color: baseColor.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: baseColor.withValues(alpha: 0.3), size: 20),
                    Icon(Icons.chevron_right,
                        color: baseColor.withValues(alpha: 0.5), size: 20),
                  ],
                ),
              ),
            ),

            // 슬라이드 노브
            Positioned(
              left: 5 + _dragValue,
              top: 5,
              bottom: 5,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragValue += details.delta.dx;
                    _dragValue = _dragValue.clamp(0.0, maxDrag);
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (_dragValue > (maxDrag * 0.8)) {
                    // 완료 임계값 도달
                    widget.onSlideCompleted();
                  } else {
                    // 원위치 복귀
                    setState(() {
                      _dragValue = 0.0;
                    });
                  }
                },
                child: Container(
                  width: _knobSize,
                  height: _knobSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.alarm_off,
                    color: widget.accentColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

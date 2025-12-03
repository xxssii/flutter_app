// lib/screens/pillow_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/settings_state.dart';
import '../services/ble_service.dart';
import 'dart:async';

class PillowScreen extends StatefulWidget {
  const PillowScreen({super.key});

  @override
  _PillowScreenState createState() => _PillowScreenState();
}

class _PillowScreenState extends State<PillowScreen> {
  // ✅ [테마 설정] 기존 테마 색상 유지
  final Color _mainDeepColor = const Color(0xFF011F25); // 텍스트/활성
  final Color _lightSleepColor = const Color(0xFF1B4561); // 목/가운데
  final Color _themeLightGray = const Color(0xFFB5C1D4); // 바닥/비활성

  // ✅ [디자인 포인트 색상]
  final Color _colHead = const Color(0xFF6292BE); // 머리
  final Color _colNeck = const Color(0xFF1B4561); // 목
  final Color _colShoulder = const Color(0xFFBD9A8E); // 어깨

  // 젤리 카드용 반투명 배경
  final Color _colJellyCard = const Color(0xCCFFFFFF);

  // ✅ 개별 에어셀 높이 상태 (0: 꺼짐, 1: 보통, 2: 높음) -> 2단계
  int _cell1Height = 1;
  int _cell2Height = 1;
  int _cell3Height = 1;

  // ✅ 조절 중 상태 및 타이머
  bool _isAdjustingCell1 = false;
  bool _isAdjustingCell2 = false;
  bool _isAdjustingCell3 = false;
  Timer? _timerCell1;
  Timer? _timerCell2;
  Timer? _timerCell3;

  @override
  void dispose() {
    _timerCell1?.cancel();
    _timerCell2?.cancel();
    _timerCell3?.cancel();
    super.dispose();
  }

  // 단계별 텍스트 반환 (2단계에 맞춤)
  String _getHeightText(int stage) {
    if (stage == 0) return 'OFF';
    if (stage == 1) return '1단계';
    if (stage == 2) return '2단계(MAX)';
    return '$stage단계';
  }

  // ✅ 에어셀 높이 업데이트 함수 (최대 2단계로 제한)
  void _updateAircellHeight(int cellNumber, int newHeight) {
    // 0 ~ 2 범위 제한
    if (newHeight < 0 || newHeight > 2) return;

    setState(() {
      switch (cellNumber) {
        case 1:
          _cell1Height = newHeight;
          _isAdjustingCell1 = true;
          _timerCell1?.cancel();
          _timerCell1 = Timer(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _isAdjustingCell1 = false);
          });
          break;
        case 2:
          _cell2Height = newHeight;
          _isAdjustingCell2 = true;
          _timerCell2?.cancel();
          _timerCell2 = Timer(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _isAdjustingCell2 = false);
          });
          break;
        case 3:
          _cell3Height = newHeight;
          _isAdjustingCell3 = true;
          _timerCell3?.cancel();
          _timerCell3 = Timer(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _isAdjustingCell3 = false);
          });
          break;
      }
    });
  }

  void _showHeightChangeSnackBar(BuildContext context, String part, int stage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$part 높이를 ${_getHeightText(stage)}로 설정합니다.'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: _mainDeepColor,
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    PermissionStatus scanStatus = await Permission.bluetoothScan.request();
    PermissionStatus connectStatus =
        await Permission.bluetoothConnect.request();
    PermissionStatus locationStatus = await Permission.location.request();

    if (scanStatus.isGranted && connectStatus.isGranted) return true;
    if (locationStatus.isGranted) return true;

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('권한 필요'),
          content: const Text('블루투스 사용을 위해 권한이 필요합니다.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('설정 열기'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<BleService, SettingsState>(
      builder: (context, bleService, settingsState, child) {
        return Scaffold(
          backgroundColor:
              isDarkMode ? AppColors.darkBackground : AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '베개 및 팔찌 제어',
                          style: AppTextStyles.heading1.copyWith(
                            color: isDarkMode
                                ? AppColors.darkPrimaryText
                                : _mainDeepColor,
                          ),
                        ),
                        Text(
                          '스마트 기기를 연결하고 설정을 관리하세요',
                          style: AppTextStyles.secondaryBodyText.copyWith(
                            color: isDarkMode
                                ? AppColors.darkSecondaryText
                                : _mainDeepColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildConnectionStatusCard(context, bleService),
                const SizedBox(height: 16),

                // ✅ 2단계 조절이 적용된 젤리 물결 카드
                _buildPillowHeightControlCard(context, bleService),

                const SizedBox(height: 16),
                _buildAutoAdjustmentCard(context, settingsState),
                const SizedBox(height: 16),
                _buildGuideCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // 기기 연결 관리 카드
  Widget _buildConnectionStatusCard(
      BuildContext context, BleService bleService) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? AppColors.darkCardBackground : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _themeLightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기기 연결 관리',
              style: AppTextStyles.heading3.copyWith(
                color: isDarkMode ? AppColors.darkPrimaryText : _mainDeepColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              icon: Icons.bed_outlined,
              label: '스마트 베개',
              isConnected: bleService.isPillowConnected,
              statusText: bleService.pillowConnectionStatus,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              icon: Icons.watch_outlined,
              label: '스마트 팔찌',
              isConnected: bleService.isWatchConnected,
              statusText: bleService.watchConnectionStatus,
              isDarkMode: isDarkMode,
            ),
            const Divider(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (bleService.isScanning) {
                    await bleService.stopScan();
                  } else if (bleService.isPillowConnected ||
                      bleService.isWatchConnected) {
                    await bleService.disconnectAll();
                  } else {
                    bool hasPermission = await _requestPermissions();
                    if (hasPermission) await bleService.startScan();
                  }
                },
                icon: Icon(
                  bleService.isScanning
                      ? Icons.stop_circle_outlined
                      : (bleService.isPillowConnected ||
                              bleService.isWatchConnected)
                          ? Icons.link_off
                          : Icons.bluetooth_searching,
                ),
                label: Text(
                  bleService.isScanning
                      ? '스캔 중지'
                      : (bleService.isPillowConnected ||
                              bleService.isWatchConnected)
                          ? '스캔 종료 (연결 해제)'
                          : '기기 스캔하기',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  backgroundColor: _mainDeepColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required bool isConnected,
    required String statusText,
    required bool isDarkMode,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isConnected ? AppColors.successGreen : _themeLightGray,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyText.copyWith(
                color: isDarkMode ? AppColors.darkPrimaryText : _mainDeepColor,
              ),
            ),
          ],
        ),
        Flexible(
          child: Text(
            statusText,
            style: AppTextStyles.bodyText.copyWith(
              color: isConnected ? AppColors.successGreen : AppColors.errorRed,
              fontSize: 12,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ✅ [수정] 2단계 조절에 맞춘 젤리 물결 카드
  Widget _buildPillowHeightControlCard(
    BuildContext context,
    BleService bleService,
  ) {
    final Color shadowColor = _colNeck;
    final Color textColor = _mainDeepColor;
    // ✅ 연결 상태 확인
    final bool isConnected = bleService.isPillowConnected;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        color: _colJellyCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. 타이틀 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '베개 높이 조절',
                        style:
                            AppTextStyles.heading3.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2단계 높이 조절',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _colNeck.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.tune, color: _colNeck, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ✅ [수정] 연결 안 되면 비활성화 (AbsorbPointer + Opacity)
              AbsorbPointer(
                absorbing: !isConnected,
                child: Opacity(
                  opacity: isConnected ? 1.0 : 0.4,
                  child: Column(
                    children: [
                      // 2. 비주얼라이저
                      SizedBox(
                        height: 180,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 1,
                              child: _buildDomeCell(
                                currentLevel: _cell1Height,
                                isAdjusting: _isAdjustingCell1,
                                color: _colHead,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildDomeCell(
                                currentLevel: _cell2Height,
                                isAdjusting: _isAdjustingCell2,
                                isLarge: true,
                                color: _colNeck,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _buildDomeCell(
                                currentLevel: _cell3Height,
                                isAdjusting: _isAdjustingCell3,
                                color: _colShoulder,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 바닥 선
                      Container(
                        height: 2,
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 0, bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _colHead.withOpacity(0.5),
                              _colShoulder.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // 3. 컨트롤러 영역
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildVerticalControl(
                              level: _cell1Height,
                              label: "오른쪽", // 위치 라벨
                              activeColor: _colHead,
                              textColor: textColor,
                              onChanged: (val) {
                                // 1. 현재 레벨 저장 (BleService가 증분 계산용으로 사용)
                                final prevLevel = _cell1Height;
                                
                                // 2. UI 업데이트
                                _updateAircellHeight(1, val);
                                _showHeightChangeSnackBar(context, '오른쪽', val);
                                
                                // 3. BLE 서비스 호출 (currentLevel 전달)
                                bleService.adjustCell(1, val, currentLevel: prevLevel);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _buildVerticalControl(
                              level: _cell2Height,
                              label: "가운데",
                              activeColor: _colNeck,
                              textColor: textColor,
                              onChanged: (val) {
                                final prevLevel = _cell2Height;
                                _updateAircellHeight(2, val);
                                _showHeightChangeSnackBar(context, '가운데', val);

                                bleService.adjustCell(2, val, currentLevel: prevLevel);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _buildVerticalControl(
                              level: _cell3Height,
                              label: "왼쪽",
                              activeColor: _colShoulder,
                              textColor: textColor,
                              onChanged: (val) {
                                final prevLevel = _cell3Height;
                                _updateAircellHeight(3, val);
                                _showHeightChangeSnackBar(context, '왼쪽', val);

                                bleService.adjustCell(3, val, currentLevel: prevLevel);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 🟢 [수정] 하단 안내 멘트
              const SizedBox(height: 24),
              Center(
                child: Text(
                  isConnected 
                      ? '베개를 연결하여 버튼을 눌러 높이를 조절해보세요.'
                      : '⚠️ 베개를 연결해야 높이를 조절할 수 있습니다.',
                  style: AppTextStyles.secondaryBodyText.copyWith(
                    color: isConnected 
                        ? textColor.withOpacity(0.5) 
                        : AppColors.errorRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 [수정] 2단계에 맞춰 물결 높이 계산 수정 ( / 2.0 )
  Widget _buildDomeCell({
    required int currentLevel,
    required bool isAdjusting,
    bool isLarge = false,
    required Color color,
  }) {
    // 프레임 높이
    double maxPixelHeight = isLarge ? 120.0 : 90.0;

    // 🟢 [핵심] 채워지는 비율: 레벨 / 2.0 (1이면 반, 2면 꽉참)
    double fillPercent = currentLevel / 2.0;

    // 최소 높이 설정
    if (currentLevel > 0 && fillPercent < 0.1) fillPercent = 0.1;

    double animatedHeight = maxPixelHeight * fillPercent;
    // 0단계여도 바닥에 아주 살짝 깔리는 느낌 (선택사항)
    if (animatedHeight < 5) animatedHeight = 5;

    final domeRadius = BorderRadius.vertical(
      top: Radius.elliptical(100, isLarge ? 100 : 60),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 숫자 표시
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: currentLevel > 0 ? 1.0 : 0.0,
            child: Text(
              "$currentLevel",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 5)],
              ),
            ),
          ),
        ),

        // ClipRRect: 물결 가두기
        ClipRRect(
          borderRadius: domeRadius,
          child: Container(
            width: double.infinity,
            height: maxPixelHeight,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. 빛나는 베이스
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  width: double.infinity,
                  height: animatedHeight,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: isAdjusting
                            ? color.withOpacity(0.6)
                            : color.withOpacity(0.2),
                        blurRadius: isAdjusting ? 20 : 10,
                        spreadRadius: isAdjusting ? 2 : 0,
                      ),
                    ],
                    color: color.withOpacity(0.1),
                  ),
                ),

                // 2. 물결 층
                ClipPath(
                  clipper: _WaveClipper(isLarge: isLarge),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    width: double.infinity,
                    height: animatedHeight * 0.9,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          color,
                          color.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. 유리 광택
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🎛️ [UI] 보석형 컨트롤러 (Max 2단계 제한)
  Widget _buildVerticalControl({
    required int level,
    required String label,
    required Color activeColor,
    required Color textColor,
    required Function(int) onChanged,
  }) {
    // 🟢 [핵심] 최대 레벨 2로 제한
    final bool canUp = level < 2;
    final bool canDown = level > 0;
    final Color disableColor = _themeLightGray;

    return Column(
      children: [
        // 라벨
        Text(
          label,
          style: TextStyle(
            color: activeColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // 캡슐 컨테이너
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // ▲ 높이기 버튼
              _buildJewelButton(
                icon: Icons.keyboard_arrow_up_rounded,
                isEnabled: canUp,
                color: activeColor,
                disableColor: disableColor,
                textColor: textColor,
                onTap: () => onChanged(level + 1),
              ),

              // 현재 단계
              Container(
                height: 34,
                alignment: Alignment.center,
                child: Text(
                  level == 0 ? "-" : "$level",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: level == 0 ? disableColor : textColor,
                  ),
                ),
              ),

              // ▼ 낮추기 버튼
              _buildJewelButton(
                icon: Icons.keyboard_arrow_down_rounded,
                isEnabled: canDown,
                color: activeColor,
                disableColor: disableColor,
                textColor: textColor,
                isDown: true,
                onTap: () => onChanged(level - 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 💎 보석 버튼 위젯 (내부용)
  Widget _buildJewelButton({
    required IconData icon,
    required bool isEnabled,
    required Color color,
    required Color disableColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isDown = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? (isDown ? Colors.white : color.withOpacity(0.2))
                : Colors.transparent,
            border: Border.all(
              color: isEnabled
                  ? (isDown ? disableColor : color.withOpacity(0.8))
                  : disableColor.withOpacity(0.3),
              width: isEnabled ? 1.5 : 1,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(isDown ? 0.1 : 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isEnabled ? (isDown ? textColor : color) : disableColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  // 자동 조절 카드
  Widget _buildAutoAdjustmentCard(
    BuildContext context,
    SettingsState settingsState,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode ? AppColors.darkCardBackground : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _themeLightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: _mainDeepColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '자동 조절 설정',
                      style: AppTextStyles.heading3.copyWith(
                        color: isDarkMode
                            ? AppColors.darkPrimaryText
                            : _mainDeepColor,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: settingsState.isAutoAdjustOn,
                  onChanged: (val) => settingsState.toggleAutoAdjust(val),
                  activeColor: _mainDeepColor,
                ),
              ],
            ),
            if (settingsState.isAutoAdjustOn) ...[
              const Divider(height: 24),
              _buildSleepStageInfo(
                context,
                title: 'REM 수면 단계',
                description: '꿈을 꾸는 단계에서 베개를 약간 낮춤',
                icon: Icons.waves,
              ),
              const SizedBox(height: 12),
              _buildSleepStageInfo(
                context,
                title: '깊은 수면 단계',
                description: '깊은 잠에서 최적의 높이 유지',
                icon: Icons.nightlight_round,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSleepStageInfo(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _colHead),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode ? AppColors.darkPrimaryText : _mainDeepColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.secondaryBodyText.copyWith(
                  color: isDarkMode
                      ? AppColors.darkSecondaryText
                      : _mainDeepColor.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDarkMode
          ? _mainDeepColor.withOpacity(0.3)
          : _mainDeepColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: _mainDeepColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('스마트 조절 안내',
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkPrimaryText
                            : _mainDeepColor,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    '자동 조절이 활성화되면 수면 단계를 감지하여 최적의 높이로 조절합니다. 부드럽게 움직여 수면을 방해하지 않습니다.',
                    style: AppTextStyles.secondaryBodyText.copyWith(
                      color: isDarkMode
                          ? AppColors.darkSecondaryText
                          : _mainDeepColor.withOpacity(0.8),
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
}

// 🌊 [CLIPPING] 상단만 부드러운 물결 모양 (기존 로직 유지)
class _WaveClipper extends CustomClipper<Path> {
  final bool isLarge;
  _WaveClipper({this.isLarge = false});

  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);

    // 부드러운 S자 곡선 (물결)
    var firstControlPoint =
        Offset(size.width / 4, size.height - (isLarge ? 25 : 15));
    var firstEndPoint =
        Offset(size.width / 2, size.height - (isLarge ? 10 : 5));
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width - (size.width / 4), size.height);
    var secondEndPoint = Offset(size.width, size.height - (isLarge ? 15 : 10));
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
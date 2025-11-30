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
  // ✅ [테마 적용] 색상 팔레트
  final Color _mainDeepColor = const Color(0xFF011F25);
  final Color _lightSleepColor = const Color(0xFF1B4561);
  final Color _themeLightGray = const Color(0xFFB5C1D4);

  // ✅ 개별 에어셀 높이 상태 (1: 낮음, 2: 보통, 3: 높음)
  int _cell1Height = 2; // 머리
  int _cell2Height = 2; // 목
  int _cell3Height = 2; // 어깨

  // ✅ 각 에어셀별 조절 중 상태 및 타이머
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

  // 단계별 텍스트 반환
  String _getHeightText(int stage) {
    switch (stage) {
      case 1:
        return '낮음';
      case 2:
        return '보통';
      case 3:
        return '높음';
      default:
        return '보통';
    }
  }

  // ✅ 에어셀 높이 업데이트 및 애니메이션 처리 공통 함수
  void _updateAircellHeight(int cellNumber, int newHeight) {
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

  // 높이 변경 스낵바 (UI 테스트용 문구 추가)
  void _showHeightChangeSnackBar(BuildContext context, String part, int stage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$part 높이를 ${_getHeightText(stage)}으로 설정합니다. (UI 테스트)'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  // 권한 요청 (기존 동일)
  Future<bool> _requestPermissions() async {
    // ... (권한 요청 로직 유지)
    print("\n" + "=" * 50);
    print("📱 권한 요청 시작...");
    print("=" * 50);

    PermissionStatus bluetoothScan = await Permission.bluetoothScan.request();
    PermissionStatus bluetoothConnect =
        await Permission.bluetoothConnect.request();
    PermissionStatus location = await Permission.location.request();

    print("\n📋 권한 상태:");
    print("   🔵 bluetoothScan: $bluetoothScan");
    print("   🔵 bluetoothConnect: $bluetoothConnect");
    print("   📍 location: $location (선택사항)");
    print("");

    List<String> deniedPermissions = [];
    if (!bluetoothScan.isGranted) deniedPermissions.add("블루투스 스캔");
    if (!bluetoothConnect.isGranted) deniedPermissions.add("블루투스 연결");

    if (deniedPermissions.isNotEmpty) {
      print("\n💥 거부된 필수 권한: ${deniedPermissions.join(', ')}");
      print("=" * 50 + "\n");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('권한이 필요합니다'),
            content: const Text('필수 권한이 거부되었습니다.\n설정에서 권한을 허용해주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
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
    print("✅ 필수 권한 허용됨! 스캔 가능!");
    print("=" * 50 + "\n");
    return true;
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
                                : AppColors.primaryText,
                          ),
                        ),
                        Text(
                          '스마트 기기를 연결하고 설정을 관리하세요',
                          style: AppTextStyles.secondaryBodyText.copyWith(
                            color: isDarkMode
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildConnectionStatusCard(context, bleService),
                const SizedBox(height: 16),

                // ✅ 수정된 높이 조절 카드 (애니메이션 + 개별 조절)
                _buildPillowHeightControlCard(context, bleService),

                const SizedBox(height: 16),
                _buildAutoAdjustmentCard(context, settingsState),
                const SizedBox(height: 16),
                // _buildSleepModeSettings(context) 제거됨
                _buildGuideCard(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // 기기 연결 관리 카드 (기존 동일)
  Widget _buildConnectionStatusCard(
    BuildContext context,
    BleService bleService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // ... (기존 코드 내용 유지)
    return Card(
      color:
          isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기기 연결 관리',
              style: AppTextStyles.heading3.copyWith(
                color: isDarkMode
                    ? AppColors.darkPrimaryText
                    : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      color: bleService.isPillowConnected
                          ? AppColors.successGreen
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '스마트 베개',
                      style: AppTextStyles.bodyText.copyWith(
                        color: isDarkMode
                            ? AppColors.darkPrimaryText
                            : AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    bleService.pillowConnectionStatus,
                    style: AppTextStyles.bodyText.copyWith(
                      color: bleService.isPillowConnected
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.watch_outlined,
                      color: bleService.isWatchConnected
                          ? AppColors.successGreen
                          : AppColors.secondaryText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '스마트 팔찌',
                      style: AppTextStyles.bodyText.copyWith(
                        color: isDarkMode
                            ? AppColors.darkPrimaryText
                            : AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    bleService.watchConnectionStatus,
                    style: AppTextStyles.bodyText.copyWith(
                      color: bleService.isWatchConnected
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (bleService.isScanning) {
                    // ✅ 스캔 중이면 중지
                    await bleService.stopScan();
                  } else if (bleService.isPillowConnected ||
                      bleService.isWatchConnected) {
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('연결 해제'),
                        content: const Text('모든 기기의 연결을 해제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              '해제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await bleService.disconnectAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('기기 연결이 해제되었습니다'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    }
                  } else {
                    bool hasPermission = await _requestPermissions();
                    if (hasPermission) {
                      await bleService.startScan();
                    }
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
                  backgroundColor: bleService.isScanning
                      ? _mainDeepColor // ✅ 스캔 중 색상: 테마 색상 사용
                      : (bleService.isPillowConnected ||
                              bleService.isWatchConnected)
                          ? Colors.red
                          : _mainDeepColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('권한 수동 설정', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: _mainDeepColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ [수정된 함수] 3개 에어셀 애니메이션 및 조절 카드
  Widget _buildPillowHeightControlCard(
    BuildContext context,
    BleService bleService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppColors.darkPrimaryText : AppColors.primaryText;

    return Card(
      color:
          isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '베개 높이 조절',
              style: AppTextStyles.heading3.copyWith(color: textColor),
            ),
            const SizedBox(height: 20),

            // ✅ 시각적 피드백 영역 (3개 에어셀 애니메이션)
            Center(
              child: SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 베개 배경 (고정, 3등분)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPillowBasePart(isLeft: true),
                        _buildPillowBasePart(isMiddle: true),
                        _buildPillowBasePart(isRight: true),
                      ],
                    ),
                    // 에어셀 높이 애니메이션 (3등분)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildAnimatedCell(1, _cell1Height, _isAdjustingCell1,
                            isLeft: true),
                        _buildAnimatedCell(2, _cell2Height, _isAdjustingCell2,
                            isMiddle: true),
                        _buildAnimatedCell(3, _cell3Height, _isAdjustingCell3,
                            isRight: true),
                      ],
                    ),
                    // 베개 윗부분 (고정, 3등분)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPillowTopPart(isLeft: true),
                        _buildPillowTopPart(isMiddle: true),
                        _buildPillowTopPart(isRight: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ 개별 조절 버튼 그룹
            _buildIndividualControlButtons(context, bleService),

            const SizedBox(height: 24),

            // ✅ 설명 텍스트 수정
            Center(
              child: Text(
                '베개를 연결하여 버튼을 눌러 높이를 조절해보세요.',
                style: AppTextStyles.secondaryBodyText.copyWith(
                  color: isDarkMode
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 베개 배경 부분 빌더 (고정)
  Widget _buildPillowBasePart({
    bool isLeft = false,
    bool isMiddle = false,
    bool isRight = false,
  }) {
    return Container(
      width: 60, // 전체 180 / 3
      height: 100,
      decoration: BoxDecoration(
        color: _themeLightGray.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? const Radius.circular(50) : Radius.zero,
          bottomLeft: isLeft ? const Radius.circular(50) : Radius.zero,
          topRight: isRight ? const Radius.circular(50) : Radius.zero,
          bottomRight: isRight ? const Radius.circular(50) : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );
  }

  // ✅ 애니메이션 에어셀 빌더
  Widget _buildAnimatedCell(
    int cellNumber,
    int currentHeight,
    bool isAdjusting, {
    bool isLeft = false,
    bool isMiddle = false,
    bool isRight = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 60, // 전체 180 / 3
      // 단계에 따른 높이 설정
      height: 40.0 + (currentHeight * 20.0),
      decoration: BoxDecoration(
        // 조절 중: 얕은 수면 색상, 평소: 깊은 수면 색상
        color: isAdjusting
            ? _lightSleepColor.withOpacity(0.8)
            : _mainDeepColor.withOpacity(0.6),
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? const Radius.circular(50) : Radius.zero,
          topRight: isRight ? const Radius.circular(50) : Radius.zero,
          bottomLeft: isLeft
              ? Radius.circular(50 - (currentHeight * 10.0))
              : Radius.zero,
          bottomRight: isRight
              ? Radius.circular(50 - (currentHeight * 10.0))
              : Radius.zero,
        ),
      ),
    );
  }

  // ✅ 베개 윗부분 빌더 (고정)
  Widget _buildPillowTopPart({
    bool isLeft = false,
    bool isMiddle = false,
    bool isRight = false,
  }) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: _themeLightGray,
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? const Radius.circular(50) : Radius.zero,
          topRight: isRight ? const Radius.circular(50) : Radius.zero,
        ),
      ),
    );
  }

  // ✅ 개별 조절 버튼 그룹 빌더
  Widget _buildIndividualControlButtons(
    BuildContext context,
    BleService bleService,
  ) {
    return Column(
      children: [
        _buildSingleControlRow(
          context: context,
          label: '에어셀 1 (머리)',
          currentHeight: _cell1Height,
          isConnected: bleService.isPillowConnected,
          onChanged: (newHeight) {
            _updateAircellHeight(1, newHeight);
            _showHeightChangeSnackBar(context, '머리', newHeight);
            // TODO: bleService.adjustCell(1, newHeight);
          },
        ),
        const Divider(height: 24),
        _buildSingleControlRow(
          context: context,
          label: '에어셀 2 (목)',
          currentHeight: _cell2Height,
          isConnected: bleService.isPillowConnected,
          onChanged: (newHeight) {
            _updateAircellHeight(2, newHeight);
            _showHeightChangeSnackBar(context, '목', newHeight);
            // TODO: bleService.adjustCell(2, newHeight);
          },
        ),
        const Divider(height: 24),
        _buildSingleControlRow(
          context: context,
          label: '에어셀 3 (어깨)',
          currentHeight: _cell3Height,
          isConnected: bleService.isPillowConnected,
          onChanged: (newHeight) {
            _updateAircellHeight(3, newHeight);
            _showHeightChangeSnackBar(context, '어깨', newHeight);
            // TODO: bleService.adjustCell(3, newHeight);
          },
        ),
      ],
    );
  }

  // ✅ 단일 조절 행 빌더 (수정됨: 연결 여부 상관없이 활성화)
  Widget _buildSingleControlRow({
    required BuildContext context,
    required String label,
    required int currentHeight,
    required bool isConnected,
    required Function(int) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? AppColors.darkPrimaryText : AppColors.primaryText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: ${_getHeightText(currentHeight)}',
          style: AppTextStyles.bodyText
              .copyWith(fontWeight: FontWeight.bold, color: textColor),
        ),
        Row(
          children: [
            // 낮추기 버튼 (isConnected 조건 추가)
            ElevatedButton(
              onPressed: (isConnected && currentHeight > 1)
                  ? () => onChanged(currentHeight - 1)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lightSleepColor,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              child: const Icon(Icons.remove, size: 20),
            ),
            const SizedBox(width: 8),
            // 높이기 버튼 (isConnected 조건 추가)
            ElevatedButton(
              onPressed: (isConnected && currentHeight < 3)
                  ? () => onChanged(currentHeight + 1)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _mainDeepColor,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  // ... (_buildAutoAdjustmentCard, _buildSleepModeSettings, _buildGuideCard는 기존 코드 유지)
  Widget _buildAutoAdjustmentCard(
    BuildContext context,
    SettingsState settingsState,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // ... (기존 코드 내용 유지)
    return Card(
      color:
          isDarkMode ? AppColors.darkCardBackground : AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        : AppColors.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '수면 시 높이 자동 조절 활성화',
                        style: AppTextStyles.bodyText.copyWith(
                          color: isDarkMode
                              ? AppColors.darkPrimaryText
                              : AppColors.primaryText,
                        ),
                      ),
                      Text(
                        '수면 단계에 따라 자동으로 베개 높이를 조절합니다.',
                        style: AppTextStyles.secondaryBodyText.copyWith(
                          color: isDarkMode
                              ? AppColors.darkSecondaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settingsState.isAutoAdjustOn,
                  onChanged: (bool value) {
                    settingsState.toggleAutoAdjust(value);
                  },
                  activeColor: _mainDeepColor,
                ),
              ],
            ),
            if (settingsState.isAutoAdjustOn) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(height: 1),
              ),
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

  // ✅ 수면 단계 정보 행 빌더 (새로 추가됨)
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
        Icon(icon, size: 20, color: AppColors.secondaryText),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? AppColors.darkPrimaryText
                      : AppColors.primaryText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.secondaryBodyText.copyWith(
                  color: isDarkMode
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
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
    // ... (기존 코드 내용 유지)
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
                            : AppColors.primaryText,
                      )),
                  const SizedBox(height: 4),
                  Text(
                      '자동 조절이 활성화되면 수면 단계를 감지하여 최적의 높이로 조절합니다. 조절 중에도 잠이 깨지 않도록 매우 부드럽게 움직입니다.',
                      style: AppTextStyles.secondaryBodyText.copyWith(
                        color: isDarkMode
                            ? AppColors.darkSecondaryText
                            : AppColors.primaryText
                                .withOpacity(0.8), // ✅ 가독성 개선: 더 진한 색상 사용
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/services/ble_service.dart
// ✅ [긴급 수정] 10초 쿨타임 적용 (과금 방지) + ID 통일 완료 + 스마트 높이 조절 로직 통합

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- 베개 UUID ---
const String PILLOW_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c7c9c331914b";
const String PRESSURE_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String SNORING_CHAR_UUID = "a3c4287c-c51d-4054-9f7a-85d7065f4900";
const String PILLOW_BATTERY_CHAR_UUID = "c0839e0b-226f-40f4-8a49-9c5957b98d30";
const String COMMAND_CHAR_UUID = "f00b462c-8822-4809-b620-835697621c17";

// --- 팔찌 UUID ---
const String WRISTBAND_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String WATCH_DATA_CHAR_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

class BleService extends ChangeNotifier {
  // 장치
  BluetoothDevice? _pillowDevice;
  BluetoothDevice? _watchDevice;

  // 특성
  BluetoothCharacteristic? _pressureChar;
  BluetoothCharacteristic? _snoringChar;
  BluetoothCharacteristic? _pillowBatteryChar;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _watchDataChar;

  // 상태
  String _pillowStatus = "베개 연결 끊김";
  String _watchStatus = "팔찌 연결 끊김";
  bool _isPillowConnected = false;
  bool _isWatchConnected = false;
  
  // ✅ [안전장치] 데이터 수집 상태
  bool _isCollectingData = false; 
  // ✅ [스캔 제어] 스캔 상태
  bool _isScanning = false; 
  
  // ✅ [추가됨] 마지막 업로드 시간 (쿨타임용)
  DateTime? _lastUploadTime;

  bool _autoHeightControl = false;
  DateTime? _lastAdjustmentTime;

  // 센서 데이터
  double pressure1_avg = 0.0;
  double pressure2_avg = 0.0;
  double pressure3_avg = 0.0;
  double pressureAvg = 0.0;

  double mic1_avg = 0.0;
  double mic2_avg = 0.0;
  double micAvg = 0.0;
  bool isSnoring = false;

  double heartRate = 0.0;
  double spo2 = 0.0;

  int pillowBattery = 0;
  int watchBattery = 0;

  int _snoringCount = 0;
  int _lowSpo2Count = 0;
  int _highMovementCount = 0;

  // Firebase
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // ✅ [수정됨] ID를 AppState와 통일 (demoUser)
  String userId = "demoUser"; 
  String sessionId = "";

  // Getters
  String get pillowConnectionStatus => _pillowStatus;
  String get watchConnectionStatus => _watchStatus;
  bool get isPillowConnected => _isPillowConnected;
  bool get isWatchConnected => _isWatchConnected;
  bool get isCollectingData => _isCollectingData;
  bool get isScanning => _isScanning;
  bool get autoHeightControl => _autoHeightControl;
  double get micLevel => micAvg; // ✅ 마이크 데시벨 레벨 getter 추가

  void toggleAutoHeightControl(bool value) {
    _autoHeightControl = value;
    notifyListeners();
  }

  // ==========================================
  // 스캔 (안전장치 포함)
  // ==========================================
  Future<void> startScan() async {
    if (kIsWeb) return;

    _pillowStatus = "베개 스캔 중...";
    _watchStatus = "팔찌 스캔 중...";
    _isScanning = true;
    notifyListeners();

    try {
      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      } catch (e) {
        print("⚠️ 스캔 시작 실패: $e");
      }

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          String deviceName = r.device.platformName.toLowerCase();

          // 베개 찾기
          if ((deviceName.contains("smartpillow") || 
               r.advertisementData.serviceUuids.contains(Guid(PILLOW_SERVICE_UUID))) && 
              _pillowDevice == null) {
            print("✅ 베개 발견: ${r.device.platformName}");
            _pillowDevice = r.device;
            connectToPillow();
          }

          // 팔찌 찾기
          if ((deviceName.contains("watch") || 
               deviceName.contains("band") || 
               r.advertisementData.serviceUuids.contains(Guid(WRISTBAND_SERVICE_UUID))) && 
              _watchDevice == null) {
            print("✅ 팔찌 발견: ${r.device.platformName}");
            _watchDevice = r.device;
            connectToWatch();
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      if (_isScanning) await stopScan();

      if (_pillowDevice == null && _pillowStatus.contains("스캔")) _pillowStatus = "베개 없음";
      if (_watchDevice == null && _watchStatus.contains("스캔")) _watchStatus = "팔찌 없음";

    } catch (e) {
      print("⚠️ 스캔 로직 오류: $e");
    } finally {
      if (_isScanning) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopScan() async {
    _isScanning = false;
    notifyListeners();
    try {
      await FlutterBluePlus.stopScan();
      if (_pillowDevice == null) _pillowStatus = "스캔 중지됨";
      if (_watchDevice == null) _watchStatus = "스캔 중지됨";
      notifyListeners();
    } catch (e) {}
  }

  // ==========================================
  // 연결
  // ==========================================
  Future<void> connectToPillow() async {
    if (kIsWeb || _pillowDevice == null) return;
    _pillowStatus = "베개 연결 시도 중...";
    notifyListeners();

    try {
      await _pillowDevice!.connect(timeout: const Duration(seconds: 10));
      _isPillowConnected = true;
      _pillowStatus = "베개 연결 성공 ✅";
      _isCollectingData = false; 
      await _discoverPillowServices();
    } catch (e) {
      _isPillowConnected = false;
      _pillowStatus = "베개 연결 실패 ❌";
    }
    notifyListeners();
  }

  Future<void> connectToWatch() async {
    if (kIsWeb || _watchDevice == null) return;
    _watchStatus = "팔찌 연결 시도 중...";
    notifyListeners();

    try {
      await _watchDevice!.connect(timeout: const Duration(seconds: 10));
      _isWatchConnected = true;
      _watchStatus = "팔찌 연결 성공 ✅";
      _isCollectingData = false; 
      await _discoverWatchServices();
    } catch (e) {
      _isWatchConnected = false;
      _watchStatus = "팔찌 연결 실패 ❌";
    }
    notifyListeners();
  }

  // ==========================================
  // 서비스 검색
  // ==========================================
  Future<void> _subscribeToCharacteristic(BluetoothCharacteristic char, Function(List<int>) onData) async {
    try {
      await char.setNotifyValue(true);
      char.onValueReceived.listen(onData);
    } catch (e) {}
  }

  Future<void> _discoverPillowServices() async {
    try {
      List<BluetoothService> services = await _pillowDevice!.discoverServices();
      for (var s in services) {
        if (s.uuid == Guid(PILLOW_SERVICE_UUID)) {
          for (var c in s.characteristics) {
            
            if (c.uuid == Guid(PRESSURE_CHAR_UUID)) {
              _pressureChar = c;
              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  List<String> values = rawData.split('/');
                  if (values.length >= 3) {
                    pressure1_avg = double.parse(values[0]);
                    pressure2_avg = double.parse(values[1]);
                    pressure3_avg = double.parse(values[2]);
                    pressureAvg = (pressure1_avg + pressure2_avg + pressure3_avg) / 3;
                    
                    if (_isCollectingData) {
                       _sendToFirebase();
                       _checkAndAdjustCell();
                    }
                  }
                } catch (e) {}
                notifyListeners();
              });
            }

            if (c.uuid == Guid(SNORING_CHAR_UUID)) {
              _snoringChar = c;
              _subscribeToCharacteristic(c, (value) {
                try {
                  List<String> values = String.fromCharCodes(value).split('/');
                  if (values.length >= 2) {
                    mic1_avg = double.parse(values[0]);
                    mic2_avg = double.parse(values[1]);
                    micAvg = (mic1_avg + mic2_avg) / 2;
                    isSnoring = micAvg > 100;
                    if (_isCollectingData) _checkAndAdjustCell();
                  }
                } catch (e) {}
                notifyListeners();
              });
            }

            if (c.uuid == Guid(PILLOW_BATTERY_CHAR_UUID)) {
              _pillowBatteryChar = c;
              _subscribeToCharacteristic(c, (value) {
                try {
                   List<String> values = String.fromCharCodes(value).split('/');
                   if (values.length >= 2) pillowBattery = int.parse(values[1]);
                } catch(e) {}
                notifyListeners();
              });
            }

            if (c.uuid == Guid(COMMAND_CHAR_UUID)) _commandChar = c;
          }
        }
      }
    } catch (e) {}
  }

  Future<void> _discoverWatchServices() async {
    try {
      List<BluetoothService> services = await _watchDevice!.discoverServices();
      for (var s in services) {
        if (s.uuid == Guid(WRISTBAND_SERVICE_UUID)) {
          for (var c in s.characteristics) {
            if (c.uuid == Guid(WATCH_DATA_CHAR_UUID)) {
              _watchDataChar = c;
              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  
                  RegExp bpmRegex = RegExp(r'bpm\s*:\s*(\d+)');
                  RegExp spo2Regex = RegExp(r'spo2\s*:\s*(\d+)');
                  RegExp batRegex = RegExp(r'bat:\s*(\d+)');
                  
                  var bpmMatch = bpmRegex.firstMatch(rawData);
                  var spo2Match = spo2Regex.firstMatch(rawData);
                  var batMatch = batRegex.firstMatch(rawData);

                  if (bpmMatch != null) heartRate = double.parse(bpmMatch.group(1)!);
                  if (spo2Match != null) spo2 = double.parse(spo2Match.group(1)!);
                  if (batMatch != null) watchBattery = int.parse(batMatch.group(1)!);

                  if (_isCollectingData) {
                    _sendToFirebase(); 
                    _checkAndAdjustCell();
                  }
                } catch (e) {}
                notifyListeners();
              });
            }
          }
        }
      }
    } catch (e) {}
  }

  // ==========================================
  // 데이터 수집 및 제어
  // ==========================================
  void startDataCollection() {
    print("🚀 데이터 수집 시작");
    _isCollectingData = true;
    // 세션 ID 생성 시점 중요
    sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
    // 쿨타임 초기화
    _lastUploadTime = null; 
    notifyListeners();
  }

  void stopDataCollection() {
    print("🛑 데이터 수집 종료");
    _isCollectingData = false;
    notifyListeners();
  }

  Future<void> _sendToFirebase() async {
    if (!_isCollectingData) return;

    // ✅ [핵심 기능] 10초 쿨타임 체크 (데이터 홍수 방지)
    if (_lastUploadTime != null && 
        DateTime.now().difference(_lastUploadTime!).inSeconds < 10) {
      // 10초가 안 지났으면 저장하지 않고 무시함
      return; 
    }
    
    // 10초 지났으면 시간 갱신하고 저장 진행
    _lastUploadTime = DateTime.now();

    try {
      await _db.collection('raw_data').add({
        'userId': userId,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),
        'hr': heartRate.toInt(),
        'spo2': spo2.toInt(),
        'pressure_avg': pressureAvg,
        'pressure_1_avg_10s': pressure1_avg,
        'pressure_2_avg_10s': pressure2_avg,
        'pressure_3_avg_10s': pressure3_avg,
        'mic_avg': micAvg,
        'mic_1_avg_10s': mic1_avg,
        'mic_2_avg_10s': mic2_avg,
        'is_snoring': isSnoring,
        'pillow_battery': pillowBattery,
        'watch_battery': watchBattery,
        'auto_control_active': _autoHeightControl,
      });
      print("📤 Firebase 저장 완료 (10초 주기)");
    } catch (e) {
      print("⚠️ Firebase 전송 실패: $e");
    }
  }

  // ==========================================
  // 8. 하드웨어 명령 (✅ 통합 및 정리 완료)
  // ==========================================

  // ❌ [삭제됨] 옛날 adjustHeight 함수는 이제 안 씁니다. (헷갈림 방지)
  
  // ✅ [수정] 현재 레벨 추적을 위한 변수 추가
  final Map<int, int> _currentCellLevels = {}; // cellIndex -> currentLevel

  // ✅ [최종 통합] 레벨(Level)을 받아서 시간(Duration)으로 변환하여 쏘는 로직
  // ✅ [핵심 수정] 이전 레벨에서 목표 레벨로 가기 위한 **증분 시간**을 계산합니다.
  // 예: 2번 에어셀이 1단계(35초)에서 2단계(75초)로 올리려면 40초 추가로 넣어야 함
  Future<void> adjustCell(int cellIndex, int targetLevel, {int? currentLevel}) async {
    // 1. 연결 체크
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
        print("⚠️ 명령 실패: 베개 미연결");
        return;
    }

    // 2. 현재 레벨 확인 (파라미터로 받거나, 저장된 값 사용)
    int prevLevel = currentLevel ?? _currentCellLevels[cellIndex] ?? 0;
    
    // 3. 목표 레벨로 업데이트
    _currentCellLevels[cellIndex] = targetLevel;

    // 4. 레벨별 누적 시간 정의 (하드웨어 팀 제공 최대 값)
    // ✅ 하드웨어 팀 제공 시간 값 (누적 시간):
    // 1단계: 1번 에어셀 25초, 2번 에어셀 35초, 3번 에어셀 20초
    // 2단계: 1번 에어셀 50초, 2번 에어셀 75초, 3번 에어셀 40초
    int getCumulativeTime(int cellIdx, int level) {
      if (level == 0) return 0;
      
      switch (cellIdx) {
        case 1:
          return level == 1 ? 25 : 50; // 1단계: 25초, 2단계: 50초
        case 2:
          return level == 1 ? 35 : 75; // 1단계: 35초, 2단계: 75초
        case 3:
          return level == 1 ? 20 : 40; // 1단계: 20초, 2단계: 40초
        default:
          return level == 1 ? 25 : 50;
      }
    }

    // 5. 이전 레벨과 목표 레벨의 누적 시간 계산
    int prevCumulativeTime = getCumulativeTime(cellIndex, prevLevel);
    int targetCumulativeTime = getCumulativeTime(cellIndex, targetLevel);
    
    // 6. **증분 시간** 계산 (추가로 넣어야 하는 시간)
    int incrementalTimeMs = (targetCumulativeTime - prevCumulativeTime) * 1000;
    
    // 7. 0단계로 내려가면 배기 (음수 방지)
    if (targetLevel == 0) {
      incrementalTimeMs = 0; // 배기 명령은 별도 처리 필요할 수 있음
    }

    try {
      // 8. 프로토콜 생성: "C{셀번호}:{밀리초}" (예: "C1:25000" 또는 "C2:40000")
      String command = "C$cellIndex:$incrementalTimeMs";
      
      // 9. 전송 (withoutResponse: false로 안정성 확보)
      // string을 byte로 변환해서 전송
      await _commandChar!.write(command.codeUnits, withoutResponse: false);
      
      print("📤 [명령 전송] 셀 $cellIndex번: Level $prevLevel → $targetLevel (${incrementalTimeMs}ms = ${incrementalTimeMs ~/ 1000}초 추가 가동)");
      print("   누적 시간: $prevCumulativeTime초 → $targetCumulativeTime초");
      
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }

  Future<void> sendVibrateStrong() async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) return;
    try { await _commandChar!.write([0x37], withoutResponse: true); } catch (e) {}
  }

  Future<void> sendVibrateGently() async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) return;
    try { 
      await _commandChar!.write([0x37], withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 500));
      await _commandChar!.write([0x38], withoutResponse: true);
    } catch (e) {}
  }

  Future<void> stopAll() async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) return;
    try { await _commandChar!.write([0x30], withoutResponse: true); } catch (e) {}
  }

  Future<void> sendRawCommand(String cmd) async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) return;
    try {
      List<int> bytes = cmd.codeUnits; 
      await _commandChar!.write(bytes, withoutResponse: false);
    } catch (e) {}
  }

  // ==========================================
  // 자동 제어 로직
  // ==========================================
  void _checkAndAdjustCell() {
    if (!_isCollectingData || !_autoHeightControl || !_isPillowConnected) return;

    if (_lastAdjustmentTime != null && DateTime.now().difference(_lastAdjustmentTime!).inSeconds < 30) return;
    
    if (isSnoring) {
        _snoringCount++;
        if (_snoringCount >= 3) { adjustCell(1, 1); _lastAdjustmentTime = DateTime.now(); _snoringCount = 0; }
    } else { _snoringCount = 0; }

    if (spo2 > 0 && spo2 < 92) {
        _lowSpo2Count++;
        if (_lowSpo2Count >= 2) { adjustCell(1, 1); _lastAdjustmentTime = DateTime.now(); _lowSpo2Count = 0; }
    } else { _lowSpo2Count = 0; }

    if (pressureAvg > 2000) {
        _highMovementCount++;
        if (_highMovementCount >= 5) { adjustCell(1, 2); _lastAdjustmentTime = DateTime.now(); _highMovementCount = 0; }
    } else { _highMovementCount = 0; }
  }

  Future<void> disconnectAll() async {
    _isCollectingData = false; 
    _isScanning = false;
    try {
      if (_pillowDevice != null) await _pillowDevice!.disconnect();
      if (_watchDevice != null) await _watchDevice!.disconnect();
      
      // ✅ 중요: 디바이스 참조 해제하여 재연결 가능하도록 수정
      _pillowDevice = null;
      _watchDevice = null;
      
      _isPillowConnected = false;
      _isWatchConnected = false;
      _pillowStatus = "베개 연결 끊김";
      _watchStatus = "팔찌 연결 끊김";
    } catch (e) {}
    notifyListeners();
  }

  // 개별 연결 해제 메서드
  Future<void> disconnectPillow() async {
    try {
      if (_pillowDevice != null) await _pillowDevice!.disconnect();
      _pillowDevice = null;
      _isPillowConnected = false;
      _pillowStatus = "베개 연결 끊김";
    } catch (e) {}
    notifyListeners();
  }

  Future<void> disconnectWatch() async {
    try {
      if (_watchDevice != null) await _watchDevice!.disconnect();
      _watchDevice = null;
      _isWatchConnected = false;
      _watchStatus = "팔찌 연결 끊김";
    } catch (e) {}
    notifyListeners();
  }
}
// lib/services/ble_service.dart
// ✅ 최종 완벽 버전: 측정 종료 + 각 센서 10초 평균 저장

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
  // ==========================================
  // 1. 변수 선언
  // ==========================================

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
  bool _isCollectingData = false;  // ✅✅✅ 핵심!
  bool _isScanning = false; // ✅ 스캔 상태 추가
  bool _autoHeightControl = false;
  DateTime? _lastAdjustmentTime;

  // ✅ 센서 데이터 (아두이노가 보내는 10초 평균값)
  double pressure1_avg = 0.0;  // 센서 1의 10초 평균
  double pressure2_avg = 0.0;  // 센서 2의 10초 평균
  double pressure3_avg = 0.0;  // 센서 3의 10초 평균
  double pressureAvg = 0.0;    // 3개 센서 평균

  double mic1_avg = 0.0;       // 마이크 1의 10초 평균
  double mic2_avg = 0.0;       // 마이크 2의 10초 평균
  double micAvg = 0.0;         // 2개 마이크 평균
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
  String userId = "demoUser";
  String sessionId = "";

  // Getters
  String get pillowConnectionStatus => _pillowStatus;
  String get watchConnectionStatus => _watchStatus;
  bool get isPillowConnected => _isPillowConnected;
  bool get isWatchConnected => _isWatchConnected;
  bool get isCollectingData => _isCollectingData;
  bool get isScanning => _isScanning; // ✅ Getter 추가
  bool get autoHeightControl => _autoHeightControl;

  void toggleAutoHeightControl(bool value) {
    _autoHeightControl = value;
    print("\n${'='*50}");
    if (value) {
      print("🤖 자동 베개 높이 제어 활성화");
    } else {
      print("🔴 자동 베개 높이 제어 비활성화");
    }
    print('='*50 + "\n");
    notifyListeners();
  }

  // ==========================================
  // 2. 스캔
  // ==========================================
  Future<void> startScan() async {
    if (kIsWeb) {
      _pillowStatus = "웹 환경: BLE 비활성화";
      _watchStatus = "웹 환경: BLE 비활성화";
      notifyListeners();
      print("🌐 웹 환경에서는 BLE 사용 불가");
      return;
    }

    _pillowStatus = "베개 스캔 중...";
    _watchStatus = "팔찌 스캔 중...";
    _isScanning = true; // ✅ 스캔 시작 상태 설정
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          print(
            "📡 발견: 이름='${r.device.platformName}' ID='${r.device.remoteId}'",
          );
          print("   서비스 UUID: ${r.advertisementData.serviceUuids}");
          print("   신호 세기: ${r.rssi} dBm");
          print("---");

          String deviceName = r.device.platformName.toLowerCase();

          if (deviceName.contains("smartpillow") && _pillowDevice == null) {
            print("✅✅✅ 베개 발견: ${r.device.platformName}");
            _pillowDevice = r.device;
            connectToPillow();
          }

          if ((deviceName.contains("watch") ||
                  deviceName.contains("band") ||
                  deviceName.contains("wristband")) &&
              _watchDevice == null) {
            print("✅✅✅ 팔찌 발견: ${r.device.platformName}");
            _watchDevice = r.device;
            connectToWatch();
          }
          
          if (r.advertisementData.serviceUuids
                  .contains(Guid(PILLOW_SERVICE_UUID)) &&
              _pillowDevice == null) {
            print("✅ 베개 발견 (UUID): ${r.device.platformName}");
            _pillowDevice = r.device;
            connectToPillow();
          }

          if (r.advertisementData.serviceUuids.contains(
                Guid(WRISTBAND_SERVICE_UUID),
              ) &&
              _watchDevice == null) {
            print("✅ 팔찌 발견 (UUID): ${r.device.platformName}");
            _watchDevice = r.device;
            connectToWatch();
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      // 스캔이 이미 중지되었을 수도 있으므로 체크
      if (_isScanning) {
        await stopScan();
      }

      if (_pillowDevice == null) {
        _pillowStatus = "베개 없음";
        print("❌ 베개를 찾지 못했습니다");
      }
      if (_watchDevice == null) {
        _watchStatus = "팔찌 없음";
        print("❌ 팔찌를 찾지 못했습니다");
      }
    } catch (e) {
      print("⚠️ BLE 스캔 오류: $e");
      _pillowStatus = "스캔 실패";
      _watchStatus = "스캔 실패";
    } finally {
      // ✅ 예외 발생 여부와 상관없이 스캔 종료 상태로 확실하게 변경
      if (_isScanning) {
        _isScanning = false;
        notifyListeners();
      }
    }
  }

  // ✅ 스캔 중지 메서드 추가
  Future<void> stopScan() async {
    // ✅ UI 즉각 반응을 위해 상태 먼저 변경
    _isScanning = false;
    notifyListeners();
    print("🛑 BLE 스캔 중지 요청됨 (UI 즉시 반영)");

    try {
      await FlutterBluePlus.stopScan();
      
      // 기기를 못 찾았을 경우 상태 업데이트
      if (_pillowDevice == null && _pillowStatus == "베개 스캔 중...") {
        _pillowStatus = "스캔 중지됨";
      }
      if (_watchDevice == null && _watchStatus == "팔찌 스캔 중...") {
        _watchStatus = "스캔 중지됨";
      }
      
      print("🛑 BLE 스캔 완전히 중지됨");
      notifyListeners(); // 상태 메시지 업데이트를 위해 한 번 더 알림
    } catch (e) {
      print("⚠️ 스캔 중지 오류: $e");
      notifyListeners();
    }
  }

  // ==========================================
  // 3. 연결
  // ==========================================
  Future<void> connectToPillow() async {
    if (kIsWeb) return;
    if (_pillowDevice == null) return;

    _pillowStatus = "베개 연결 시도 중...";
    notifyListeners();

    try {
      await _pillowDevice!.connect(timeout: const Duration(seconds: 10));
      _isPillowConnected = true;
      _pillowStatus = "베개 연결 성공 ✅";
      print("\n${'='*50}");
      print("✅ 베개 연결 성공!");
      print("⚠️ _isCollectingData = $_isCollectingData");
      print('='*50 + "\n");
      await _discoverPillowServices();
    } catch (e) {
      _isPillowConnected = false;
      _pillowStatus = "베개 연결 실패 ❌";
      print("❌ 베개 연결 실패: $e");
    }
    notifyListeners();
  }

  Future<void> connectToWatch() async {
    if (kIsWeb) return;
    if (_watchDevice == null) return;

    _watchStatus = "팔찌 연결 시도 중...";
    notifyListeners();

    try {
      await _watchDevice!.connect(timeout: const Duration(seconds: 10));
      _isWatchConnected = true;
      _watchStatus = "팔찌 연결 성공 ✅";
      print("\n${'='*50}");
      print("✅ 팔찌 연결 성공!");
      print("⚠️ _isCollectingData = $_isCollectingData");
      print('='*50 + "\n");
      await _discoverWatchServices();
    } catch (e) {
      _isWatchConnected = false;
      _watchStatus = "팔찌 연결 실패 ❌";
      print("❌ 팔찌 연결 실패: $e");
    }
    notifyListeners();
  }

  // ==========================================
  // 4. 특성 구독
  // ==========================================
  Future<void> _subscribeToCharacteristic(
    BluetoothCharacteristic char,
    Function(List<int>) onData,
  ) async {
    try {
      await char.setNotifyValue(true);
      char.onValueReceived.listen(onData);
      print("✅ 특성 구독 성공: ${char.uuid}");
    } catch (e) {
      print("⚠️ 구독 실패: $e");
    }
  }

  // ==========================================
  // 5. 베개 서비스 검색
  // ==========================================
  Future<void> _discoverPillowServices() async {
    try {
      List<BluetoothService> services = await _pillowDevice!.discoverServices();
      print("🔍 베개 서비스 검색 중...");

      for (var s in services) {
        if (s.uuid == Guid(PILLOW_SERVICE_UUID)) {
          print("✅ 베개 서비스 발견!");

          for (var c in s.characteristics) {
            if (c.uuid == Guid(PRESSURE_CHAR_UUID)) {
              _pressureChar = c;
              print("✅ 압력 특성 발견 (10초 평균값 수신)");

              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  List<String> values = rawData.split('/');

                  if (values.length >= 3) {
                    // ✅ 아두이노가 이미 10초 평균을 계산해서 보냄!
                    pressure1_avg = double.parse(values[0]);
                    pressure2_avg = double.parse(values[1]);
                    pressure3_avg = double.parse(values[2]);
                    pressureAvg = (pressure1_avg + pressure2_avg + pressure3_avg) / 3;

                    // ✅ 수집 중일 때만 로그 + Firebase
                    if (_isCollectingData) {
                      print("📊 [수집 중] 압력 10초 평균: ${pressure1_avg.toStringAsFixed(0)} / ${pressure2_avg.toStringAsFixed(0)} / ${pressure3_avg.toStringAsFixed(0)} (전체 평균: ${pressureAvg.toStringAsFixed(0)})");
                      _sendToFirebase();
                    }
                    
                    _checkAndAdjustHeight();
                  }
                } catch (e) {
                  print("⚠️ 압력 데이터 파싱 오류: $e");
                }
                notifyListeners();
              });
            }

            if (c.uuid == Guid(SNORING_CHAR_UUID)) {
              _snoringChar = c;
              print("✅ 마이크 특성 발견 (10초 평균값 수신)");

              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  List<String> values = rawData.split('/');

                  if (values.length >= 2) {
                    // ✅ 아두이노가 이미 10초 평균을 계산해서 보냄!
                    mic1_avg = double.parse(values[0]);
                    mic2_avg = double.parse(values[1]);
                    micAvg = (mic1_avg + mic2_avg) / 2;
                    isSnoring = micAvg > 100;

                    // ✅ 수집 중일 때만 로그
                    if (_isCollectingData) {
                      print("🎤 [수집 중] 마이크 10초 평균: ${mic1_avg.toStringAsFixed(0)} / ${mic2_avg.toStringAsFixed(0)} (전체 평균: ${micAvg.toStringAsFixed(0)}, 코골이: $isSnoring)");
                    }
                    
                    _checkAndAdjustHeight();
                  }
                } catch (e) {
                  print("⚠️ 마이크 데이터 파싱 오류: $e");
                }
                notifyListeners();
              });
            }

            if (c.uuid == Guid(PILLOW_BATTERY_CHAR_UUID)) {
              _pillowBatteryChar = c;
              print("✅ 베개 배터리 특성 발견");

              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  List<String> values = rawData.split('/');

                  if (values.length >= 2) {
                    double voltage = double.parse(values[0]);
                    pillowBattery = int.parse(values[1]);

                    if (_isCollectingData) {
                      print("🔋 [수집 중] 베개 배터리: $pillowBattery% ($voltage V)");
                    }
                  }
                } catch (e) {
                  print("⚠️ 베개 배터리 파싱 오류: $e");
                }
                notifyListeners();
              });
            }

            if (c.uuid == Guid(COMMAND_CHAR_UUID)) {
              _commandChar = c;
              print("✅ 명령 특성 발견");
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ 베개 서비스 검색 오류: $e");
    }
  }

  // ==========================================
  // 6. 팔찌 서비스 검색
  // ==========================================
  Future<void> _discoverWatchServices() async {
    try {
      List<BluetoothService> services = await _watchDevice!.discoverServices();
      print("🔍 팔찌 서비스 검색 중...");

      for (var s in services) {
        if (s.uuid == Guid(WRISTBAND_SERVICE_UUID)) {
          print("✅ 팔찌 서비스 발견!");

          for (var c in s.characteristics) {
            if (c.uuid == Guid(WATCH_DATA_CHAR_UUID)) {
              _watchDataChar = c;
              print("✅ 팔찌 통합 데이터 특성 발견");

              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  
                  RegExp bpmRegex = RegExp(r'bpm\s*:\s*(\d+)');
                  RegExp spo2Regex = RegExp(r'spo2\s*:\s*(\d+)');
                  RegExp batRegex = RegExp(r'bat:\s*(\d+)');

                  var bpmMatch = bpmRegex.firstMatch(rawData);
                  var spo2Match = spo2Regex.firstMatch(rawData);
                  var batMatch = batRegex.firstMatch(rawData);

                  if (bpmMatch != null) {
                    heartRate = double.parse(bpmMatch.group(1)!);
                  }
                  if (spo2Match != null) {
                    spo2 = double.parse(spo2Match.group(1)!);
                  }
                  if (batMatch != null) {
                    watchBattery = int.parse(batMatch.group(1)!);
                  }

                  // ✅ 수집 중일 때만 로그 + Firebase
                  if (_isCollectingData) {
                    print("📱 [수집 중] 받은 데이터: $rawData");
                    print("💓 [수집 중] 심박수: ${heartRate.toStringAsFixed(0)} bpm");
                    print("🩸 [수집 중] 산소포화도: ${spo2.toStringAsFixed(0)} %");
                    print("🔋 [수집 중] 팔찌 배터리: $watchBattery%");
                    _sendToFirebase();
                  }

                  _checkAndAdjustHeight();
                } catch (e) {
                  print("⚠️ 팔찌 데이터 파싱 오류: $e");
                }
                notifyListeners();
              });
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ 팔찌 서비스 검색 오류: $e");
    }
  }

  // ==========================================
  // ✅ 자동 베개 높이 제어 로직
  // ==========================================
  
  void _checkAndAdjustHeight() {
    if (!_autoHeightControl) return;
    if (!_isCollectingData) return;
    if (!_isPillowConnected) return;

    if (_lastAdjustmentTime != null) {
      final timeSinceLastAdjustment = DateTime.now().difference(_lastAdjustmentTime!);
      if (timeSinceLastAdjustment.inSeconds < 30) {
        return;
      }
    }

    if (isSnoring) {
      _snoringCount++;
      print("😴 코골이 감지 카운트: $_snoringCount");
      
      if (_snoringCount >= 3) {
        print("🚨 연속 코골이 감지! 베개 높이 올립니다 (셀 1)");
        adjustHeight(1);
        _lastAdjustmentTime = DateTime.now();
        _snoringCount = 0;
        return;
      }
    } else {
      _snoringCount = 0;
    }

    if (spo2 > 0 && spo2 < 92) {
      _lowSpo2Count++;
      print("⚠️ 낮은 산소포화도 감지: $spo2% (카운트: $_lowSpo2Count)");
      
      if (_lowSpo2Count >= 2) {
        print("🚨 저산소 상태! 베개 높이 올립니다 (셀 1)");
        adjustHeight(1);
        _lastAdjustmentTime = DateTime.now();
        _lowSpo2Count = 0;
        return;
      }
    } else {
      _lowSpo2Count = 0;
    }

    if (pressureAvg > 2000) {
      _highMovementCount++;
      print("🔄 뒤척임 감지 (압력: ${pressureAvg.toStringAsFixed(0)}, 카운트: $_highMovementCount)");
      
      if (_highMovementCount >= 5) {
        print("🚨 과도한 뒤척임! 베개 높이 재조정 (셀 2)");
        adjustHeight(2);
        _lastAdjustmentTime = DateTime.now();
        _highMovementCount = 0;
        return;
      }
    } else {
      _highMovementCount = 0;
    }
  }

  // ==========================================
  // ✅✅✅ 데이터 수집 제어 (핵심!)
  // ==========================================

  /// ✅ 데이터 수집 시작
  void startDataCollection() {
    print("\n${'='*60}");
    print("✅✅✅ [startDataCollection() 호출됨]");
    print("✅✅✅ _isCollectingData: false → true");
    
    _isCollectingData = true;
    sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
    
    _snoringCount = 0;
    _lowSpo2Count = 0;
    _highMovementCount = 0;
    _lastAdjustmentTime = null;
    
    print("✅✅✅ 데이터 수집 시작! (sessionId: $sessionId)");
    if (_autoHeightControl) {
      print("🤖 자동 베개 높이 제어 활성화됨");
    }
    print('='*60 + "\n");
    notifyListeners();
  }

  /// ✅ 데이터 수집 종료
  void stopDataCollection() {
    print("\n${'='*60}");
    print("⏹️⏹️⏹️ [stopDataCollection() 호출됨]");
    print("⏹️⏹️⏹️ _isCollectingData: true → false");
    
    _isCollectingData = false;
    
    print("⏹️⏹️⏹️ 데이터 수집 종료! (sessionId: $sessionId)");
    print("✅ 하드웨어 연결 유지, Firebase 전송 중지");
    print('='*60 + "\n");
    notifyListeners();
  }

  // ==========================================
  // 7. ✅ Firebase 전송 (각 센서 10초 평균값 저장)
  // ==========================================
  
  Future<void> _sendToFirebase() async {
    // ✅✅✅ 핵심 체크!
    if (!_isCollectingData) {
      print("⏸️ [Firebase 전송 차단] _isCollectingData = false");
      return;
    }

    try {
      // ✅ 각 센서의 10초 평균값을 Firebase에 저장
      await _db.collection('raw_data').add({
        'userId': userId,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),

        // ✅ 팔찌 센서 데이터
        'hr': heartRate.toInt(),
        'spo2': spo2.toInt(),

        // ✅ 압력 센서 10초 평균 (각각 저장!)
        'pressure_1_avg_10s': pressure1_avg,
        'pressure_2_avg_10s': pressure2_avg,
        'pressure_3_avg_10s': pressure3_avg,
        'pressure_avg': pressureAvg,  // 3개 센서 전체 평균

        // ✅ 마이크 센서 10초 평균 (각각 저장!)
        'mic_1_avg_10s': mic1_avg,
        'mic_2_avg_10s': mic2_avg,
        'mic_avg': micAvg,  // 2개 마이크 전체 평균
        'is_snoring': isSnoring,

        // 배터리
        'pillow_battery': pillowBattery,
        'watch_battery': watchBattery,
        // 자동 제어 상태
        'auto_control_active': _autoHeightControl,
      });

      print("✅ [Firebase 저장 완료] raw_data");
      print("   - 압력: ${pressure1_avg.toStringAsFixed(0)} / ${pressure2_avg.toStringAsFixed(0)} / ${pressure3_avg.toStringAsFixed(0)} (10초 평균)");
      print("   - 마이크: ${mic1_avg.toStringAsFixed(0)} / ${mic2_avg.toStringAsFixed(0)} (10초 평균)");
      print("   - 심박: $heartRate, 산소: $spo2");
    } catch (e) {
      print("⚠️ Firebase 전송 실패: $e");
    }
  }

  // ==========================================
  // 8. 명령 전송
  // ==========================================

  Future<void> sendVibrateStrong() async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    try {
      await _commandChar!.write([0x37], withoutResponse: true);
      print("📤 강한 진동 명령 전송 성공");
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }

  Future<void> sendVibrateGently() async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    try {
      await _commandChar!.write([0x37], withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 500));
      await _commandChar!.write([0x38], withoutResponse: true);
      print("📤 부드러운 진동 명령 전송 성공");
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }

  Future<void> adjustHeight(int cellNumber) async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    if (cellNumber < 1 || cellNumber > 3) {
      print("⚠️ 잘못된 셀 번호: $cellNumber (1-3 사이여야 함)");
      return;
    }

    try {
      int command = 0x30 + cellNumber;
      await _commandChar!.write([command], withoutResponse: true);
      print("📤 셀 $cellNumber 높이 조절 명령 전송");
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }

  Future<void> stopAll() async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    try {
      await _commandChar!.write([0x30], withoutResponse: true);
      print("📤 전체 정지 명령 전송");
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }
// ==========================================
  // [추가] 하드웨어 테스트용 원시 명령 전송 함수
  // ==========================================
  Future<void> sendRawCommand(String cmd) async {
    // 1. 연결 체크
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    // 2. 명령 전송
    try {
      // 아두이노는 문자 하나(char)를 기다리므로 문자열을 바이트로 변환해서 전송
      // 예: "1" -> [0x31]
      List<int> bytes = cmd.codeUnits; 
      await _commandChar!.write(bytes, withoutResponse: false);
      print("🚀 명령 전송 성공: $cmd");
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }




  // ==========================================
  // 9. 연결 해제
  // ==========================================
  Future<void> disconnectAll() async {
    if (kIsWeb) return;

    print("\n${'='*50}");
    print("🔌 [disconnectAll() 호출됨]");
    
    try {
      if (_pillowDevice != null && _isPillowConnected) {
        await _pillowDevice!.disconnect();
        _isPillowConnected = false;
        _pillowStatus = "베개 연결 끊김";
        print("✅ 베개 연결 해제");
      }

      if (_watchDevice != null && _isWatchConnected) {
        await _watchDevice!.disconnect();
        _isWatchConnected = false;
        _watchStatus = "팔찌 연결 끊김";
        print("✅ 팔찌 연결 해제");
      }

      // ✅ 연결 해제 시 데이터 수집도 자동 중지
      if (_isCollectingData) {
        _isCollectingData = false;
        print("✅ _isCollectingData = false (자동 중지)");
      }

      print('='*50 + "\n");
      notifyListeners();
    } catch (e) {
      print("⚠️ 연결 해제 오류: $e");
    }
  }

  @override
  void dispose() {
    disconnectAll();
    super.dispose();
  }
}



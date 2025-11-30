import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/sleep_apnea_detector.dart';
import '../utils/sleep_score_analyzer.dart';

const String PILLOW_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c7c9c331914b";
const String PRESSURE_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const String SNORING_CHAR_UUID = "a3c4287c-c51d-4054-9f7a-85d7065f4900";
const String PILLOW_BATTERY_CHAR_UUID = "c0839e0b-226f-40f4-8a49-9c5957b98d30";
const String COMMAND_CHAR_UUID = "f00b462c-8822-4809-b620-835697621c17";

const String WRISTBAND_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String WATCH_DATA_CHAR_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

class BleService extends ChangeNotifier {
  BluetoothDevice? _pillowDevice;
  BluetoothDevice? _watchDevice;

  BluetoothCharacteristic? _pressureChar;
  BluetoothCharacteristic? _snoringChar;
  BluetoothCharacteristic? _pillowBatteryChar;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _watchDataChar;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  String _pillowStatus = "베개 연결 끊김";
  String _watchStatus = "팔찌 연결 끊김";
  bool _isPillowConnected = false;
  bool _isWatchConnected = false;
  bool _isCollectingData = false;
  bool _isScanning = false;
  bool _autoHeightControl = false;
  DateTime? _lastAdjustmentTime;

  late final SleepApneaDetector _apneaDetector;

  double _prevHeartRate = 0.0;
  DateTime? _lastBreathingTime;

  final SleepScoreAnalyzer _scoreAnalyzer = SleepScoreAnalyzer();
  DateTime? _collectionStartTime;
  int _totalSnoringSeconds = 0;

  BleService() {
    _apneaDetector = SleepApneaDetector(
      onAdjustPillow: (cellIndex, height) {
        adjustCell(cellIndex, height);
      },
    );
  }

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

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String userId = "demoUser";
  String sessionId = "";

  String get pillowConnectionStatus => _pillowStatus;
  String get watchConnectionStatus => _watchStatus;
  bool get isPillowConnected => _isPillowConnected;
  bool get isWatchConnected => _isWatchConnected;
  bool get isCollectingData => _isCollectingData;
  bool get isScanning => _isScanning;
  bool get autoHeightControl => _autoHeightControl;

  void toggleAutoHeightControl(bool value) {
    _autoHeightControl = value;
    print("\n${'=' * 50}");
    if (value) {
      print("🤖 자동 베개 높이 제어 활성화");
    } else {
      print("🔴 자동 베개 높이 제어 비활성화");
    }
    print('=' * 50 + "\n");
    notifyListeners();
  }

  Future<void> startScan() async {
    if (kIsWeb) {
      _pillowStatus = "웹 환경: BLE 비활성화";
      _watchStatus = "웹 환경: BLE 비활성화";
      notifyListeners();
      print("🌐 웹 환경에서는 BLE 사용 불가");
      return;
    }

    await stopScan();

    if (!_isPillowConnected) _pillowDevice = null;
    if (!_isWatchConnected) _watchDevice = null;

    _pillowStatus = "베개 스캔 중...";
    _watchStatus = "팔찌 스캔 중...";
    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          String deviceName = r.device.platformName.toLowerCase();

          if (_pillowDevice == null) {
             if (deviceName.contains("smartpillow") || 
                 r.advertisementData.serviceUuids.contains(Guid(PILLOW_SERVICE_UUID))) {
               print("✅✅✅ 베개 발견: ${r.device.platformName}");
               _pillowDevice = r.device;
               connectToPillow();
             }
          }

          if (_watchDevice == null) {
            if (deviceName.contains("watch") ||
                deviceName.contains("band") ||
                deviceName.contains("wristband") ||
                r.advertisementData.serviceUuids.contains(Guid(WRISTBAND_SERVICE_UUID))) {
              print("✅✅✅ 팔찌 발견: ${r.device.platformName}");
              _watchDevice = r.device;
              connectToWatch();
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      if (_isScanning) {
        await stopScan();
      }

      if (_pillowDevice == null && !_isPillowConnected) {
        _pillowStatus = "베개 없음";
        print("❌ 베개를 찾지 못했습니다");
      }
      if (_watchDevice == null && !_isWatchConnected) {
        _watchStatus = "팔찌 없음";
        print("❌ 팔찌를 찾지 못했습니다");
      }
    } catch (e) {
      print("⚠️ BLE 스캔 로직 오류: $e");
      _pillowStatus = "스캔 실패";
      _watchStatus = "스캔 실패";
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
    print("🛑 BLE 스캔 중지 요청됨");

    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      
      await FlutterBluePlus.stopScan();
      
      if (!_isPillowConnected && _pillowStatus.contains("스캔 중")) {
        _pillowStatus = "스캔 중지됨";
      }
      if (!_isWatchConnected && _watchStatus.contains("스캔 중")) {
        _watchStatus = "스캔 중지됨";
      }
      
      print("🛑 BLE 스캔 완전히 중지됨");
      notifyListeners();
    } catch (e) {
      print("⚠️ 스캔 중지 오류: $e");
      notifyListeners();
    }
  }

  Future<void> connectToPillow() async {
    if (kIsWeb) return;
    if (_pillowDevice == null) return;

    _pillowStatus = "베개 연결 시도 중...";
    notifyListeners();

    try {
      await _pillowDevice!.connect(timeout: const Duration(seconds: 10));
      _isPillowConnected = true;
      _pillowStatus = "베개 연결 성공 ✅";
      print("\n${'=' * 50}");
      print("✅ 베개 연결 성공!");
      print("⚠️ _isCollectingData = $_isCollectingData");
      print('=' * 50 + "\n");
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
      print("\n${'=' * 50}");
      print("✅ 팔찌 연결 성공!");
      print("⚠️ _isCollectingData = $_isCollectingData");
      print('=' * 50 + "\n");
      await _discoverWatchServices();
    } catch (e) {
      _isWatchConnected = false;
      _watchStatus = "팔찌 연결 실패 ❌";
      print("❌ 팔찌 연결 실패: $e");
    }
    notifyListeners();
  }

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
                    pressure1_avg = double.parse(values[0]);
                    pressure2_avg = double.parse(values[1]);
                    pressure3_avg = double.parse(values[2]);
                    pressureAvg = (pressure1_avg + pressure2_avg + pressure3_avg) / 3;

                    if (_isCollectingData) {
                      print("📊 [수집 중] 압력: ${pressure1_avg.toStringAsFixed(0)} / ${pressure2_avg.toStringAsFixed(0)} / ${pressure3_avg.toStringAsFixed(0)}");
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
                    mic1_avg = double.parse(values[0]);
                    mic2_avg = double.parse(values[1]);
                    micAvg = (mic1_avg + mic2_avg) / 2;
                    isSnoring = micAvg > 100;

                    if (_isCollectingData) {
                      print("🎤 [수집 중] 마이크: ${mic1_avg.toStringAsFixed(0)} / ${mic2_avg.toStringAsFixed(0)} (코골이: $isSnoring)");
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

                  if (_isCollectingData) {
                    print("📱 [수집 중] 팔찌 데이터: $rawData");
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
    
    double hrChange = 0.0;
    if (_prevHeartRate > 0 && heartRate > 0) {
      hrChange = (heartRate - _prevHeartRate).abs();
    }
    _prevHeartRate = heartRate;
    
    double respirationDuration = 0.0;
    if (pressureAvg > 100) {
      _lastBreathingTime = DateTime.now();
    } else if (_lastBreathingTime != null) {
      respirationDuration = DateTime.now().difference(_lastBreathingTime!).inSeconds.toDouble();
    }

    double movementScore = (pressureAvg / 4095.0) * 10.0;

    String? feedback = _apneaDetector.detectApnea(
      respirationDuration: respirationDuration,
      heartRateChange: hrChange,
      spo2Level: spo2,
      chestAbdomenMovement: movementScore,
      isSnoringStopped: !isSnoring,
      isSuddenInhalation: micAvg > 2000,
    );

    if (feedback != null) {
      print("🚨 [수면 무호흡 감지] $feedback");
      _lastAdjustmentTime = DateTime.now();
    }

    if (isSnoring) {
      _snoringCount++;
      _totalSnoringSeconds += 1; 

      if (_snoringCount >= 3) {
        print("😴 연속 코골이 감지 -> 베개 높이 조절");
        adjustHeight(1);
        _lastAdjustmentTime = DateTime.now();
        _snoringCount = 0;
      }
    } else {
      _snoringCount = 0;
    }
  }

  void startDataCollection() {
    print("\n${'=' * 60}");
    print("✅✅✅ [startDataCollection() 호출됨]");
    
    _isCollectingData = true;
    sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";

    _snoringCount = 0;
    _lowSpo2Count = 0;
    _highMovementCount = 0;
    _lastAdjustmentTime = null;

    _collectionStartTime = DateTime.now();
    _totalSnoringSeconds = 0;

    print("✅✅✅ 데이터 수집 시작! (sessionId: $sessionId)");
    if (_autoHeightControl) {
      print("🤖 자동 베개 높이 제어 활성화됨");
    }
    print('=' * 60 + "\n");
    notifyListeners();
  }

  void stopDataCollection() {
    print("\n${'=' * 60}");
    print("⏹️⏹️⏹️ [stopDataCollection() 호출됨]");
    
    _isCollectingData = false;

    if (_collectionStartTime != null) {
      final duration = DateTime.now().difference(_collectionStartTime!);
      final totalMinutes = duration.inMinutes.toDouble();
      final snoringMinutes = _totalSnoringSeconds / 60.0;

      print("\n📊 [수면 분석 결과]");
      print("   - 총 수면 시간: ${totalMinutes.toStringAsFixed(1)}분");
      print("   - 총 코골이 시간: ${snoringMinutes.toStringAsFixed(1)}분");

      double snoringScore = _scoreAnalyzer.getSnoringScore(snoringMinutes, totalMinutes);
      print("   - 코골이 점수: ${snoringScore.toStringAsFixed(1)} / 10.0");

      String? snoringWarning = _scoreAnalyzer.getSnoringWarning(snoringMinutes);
      if (snoringWarning != null) {
        print("   ⚠️ $snoringWarning");
      } else {
        print("   ✅ 코골이 상태 양호");
      }

      double efficiency = 100.0;
      if (totalMinutes > 0) {
        double lostMinutes = _highMovementCount * 1.0;
        efficiency = ((totalMinutes - lostMinutes) / totalMinutes) * 100.0;
        efficiency = efficiency.clamp(0.0, 100.0);
      }
      print("   - 추정 수면 효율: ${efficiency.toStringAsFixed(1)}%");

      int totalScore = _scoreAnalyzer.getSleepScore(efficiency, 20.0, 20.0);
      print("   🏆 종합 수면 점수: $totalScore점");
      print("   📝 ${_scoreAnalyzer.generateDailyReport(totalScore)}");
    }

    print("⏹️⏹️⏹️ 데이터 수집 종료! (sessionId: $sessionId)");
    print("✅ 하드웨어 연결 유지, Firebase 전송 중지");
    print('=' * 60 + "\n");
    notifyListeners();
  }

  Future<void> _sendToFirebase() async {
    if (!_isCollectingData) {
      print("⏸️ [Firebase 전송 차단] _isCollectingData = false");
      return;
    }

    try {
      await _db.collection('raw_data').add({
        'userId': userId,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),
        'hr': heartRate.toInt(),
        'spo2': spo2.toInt(),
        'pressure_1_avg_10s': pressure1_avg,
        'pressure_2_avg_10s': pressure2_avg,
        'pressure_3_avg_10s': pressure3_avg,
        'pressure_avg': pressureAvg,
        'mic_1_avg_10s': mic1_avg,
        'mic_2_avg_10s': mic2_avg,
        'mic_avg': micAvg,
        'is_snoring': isSnoring,
        'pillow_battery': pillowBattery,
        'watch_battery': watchBattery,
        'auto_control_active': _autoHeightControl,
      });

      print("✅ [Firebase 저장 완료] raw_data");
    } catch (e) {
      print("⚠️ Firebase 전송 실패: $e");
    }
  }

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

  Future<void> adjustCell(int cellIndex, int height) async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    try {
      String command = "C$cellIndex:$height";
      await _commandChar!.write(command.codeUnits, withoutResponse: true);
      print("📤 셀 높이 조절 명령 전송: $command");
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

  Future<void> sendRawCommand(String cmd) async {
    if (kIsWeb || _commandChar == null || !_isPillowConnected) {
      print("⚠️ 명령 실패: 특성 없음 또는 미연결");
      return;
    }

    try {
      List<int> bytes = cmd.codeUnits;
      await _commandChar!.write(bytes, withoutResponse: false);
      print("🚀 명령 전송 성공: $cmd");
    } catch (e) {
      print("⚠️ 명령 전송 실패: $e");
    }
  }

  Future<void> disconnectAll() async {
    if (kIsWeb) return;

    print("\n${'=' * 50}");
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

      if (_isCollectingData) {
        _isCollectingData = false;
        print("✅ _isCollectingData = false (자동 중지)");
      }

      print('=' * 50 + "\n");
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

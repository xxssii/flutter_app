// lib/services/ble_service.dart

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
  // ✅ 데이터 수집 제어 플래그
  bool _isCollectingData = false;

  // 센서 데이터
  double pressure1 = 0.0;
  double pressure2 = 0.0;
  double pressure3 = 0.0;
  double pressureAvg = 0.0;

  double mic1 = 0.0;
  double mic2 = 0.0;
  double micAvg = 0.0;
  bool isSnoring = false;

  double heartRate = 0.0;
  double spo2 = 0.0;

  int pillowBattery = 0;
  int watchBattery = 0;

  // Firebase
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String userId = "demoUser";
  String sessionId = ""; // ✅ 빈 문자열로 초기화 (측정 시작할 때 생성)

  // Getters
  String get pillowConnectionStatus => _pillowStatus;
  String get watchConnectionStatus => _watchStatus;
  bool get isPillowConnected => _isPillowConnected;
  bool get isWatchConnected => _isWatchConnected;
  bool get isCollectingData => _isCollectingData;

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

          // ✅ 베개 찾기 (이름으로)
          if (deviceName.contains("smartpillow") && _pillowDevice == null) {
            print("✅✅✅ 베개 발견: ${r.device.platformName}");
            _pillowDevice = r.device;
            connectToPillow();
          }

          // ✅ 팔찌 찾기 (이름으로)
          if ((deviceName.contains("watch") ||
                  deviceName.contains("band") ||
                  deviceName.contains("wristband")) &&
              _watchDevice == null) {
            print("✅✅✅ 팔찌 발견: ${r.device.platformName}");
            _watchDevice = r.device;
            connectToWatch();
          }

          // 기존 UUID 방식도 유지
          if (r.advertisementData.serviceUuids.contains(
                Guid(PILLOW_SERVICE_UUID),
              ) &&
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
      FlutterBluePlus.stopScan();

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
    }

    notifyListeners();
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
      print("✅ 베개 연결 성공!");
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
      print("✅ 팔찌 연결 성공!");
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
            // 압력 센서
            if (c.uuid == Guid(PRESSURE_CHAR_UUID)) {
              _pressureChar = c;
              print("✅ 압력 특성 발견");

              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  List<String> values = rawData.split('/');

                  if (values.length >= 3) {
                    pressure1 = double.parse(values[0]);
                    pressure2 = double.parse(values[1]);
                    pressure3 = double.parse(values[2]);
                    pressureAvg = (pressure1 + pressure2 + pressure3) / 3;

                    print(
                      "📊 압력: $pressure1 / $pressure2 / $pressure3 (평균: ${pressureAvg.toStringAsFixed(0)})",
                    );
                    _sendToFirebase();
                  }
                } catch (e) {
                  print("⚠️ 압력 데이터 파싱 오류: $e");
                }
                notifyListeners();
              });
            }

            // 마이크 센서
            if (c.uuid == Guid(SNORING_CHAR_UUID)) {
              _snoringChar = c;
              print("✅ 마이크 특성 발견");

              _subscribeToCharacteristic(c, (value) {
                try {
                  String rawData = String.fromCharCodes(value);
                  List<String> values = rawData.split('/');

                  if (values.length >= 2) {
                    mic1 = double.parse(values[0]);
                    mic2 = double.parse(values[1]);
                    micAvg = (mic1 + mic2) / 2;
                    isSnoring = micAvg > 100;

                    print(
                      "🎤 마이크: $mic1 / $mic2 (평균: ${micAvg.toStringAsFixed(0)}, 코골이: $isSnoring)",
                    );
                  }
                } catch (e) {
                  print("⚠️ 마이크 데이터 파싱 오류: $e");
                }
                notifyListeners();
              });
            }

            // 베개 배터리
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

                    print("🔋 베개 배터리: $pillowBattery% ($voltage V)");
                  }
                } catch (e) {
                  print("⚠️ 베개 배터리 파싱 오류: $e");
                }
                notifyListeners();
              });
            }

            // 명령 특성
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
                  print("📱 받은 데이터: $rawData");

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

                  print("💓 심박수: ${heartRate.toStringAsFixed(0)} bpm");
                  print("🩸 산소포화도: ${spo2.toStringAsFixed(0)} %");
                  print("🔋 팔찌 배터리: $watchBattery%");

                  _sendToFirebase();
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
  // 데이터 수집 제어
  // ==========================================

  /// ✅ 데이터 수집 시작 (새로운 sessionId 생성!)
  void startDataCollection() {
    _isCollectingData = true;
    // ✅ 새로운 세션 ID 생성!
    sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
    print("✅ 데이터 수집 시작! (sessionId: $sessionId)");
    notifyListeners();
  }

  /// ✅ (수정됨) 데이터 수집만 종료 (연결은 유지)
  void stopDataCollection() {
    _isCollectingData = false;
    print("⏹️ 데이터 수집 종료! (sessionId: $sessionId, 연결은 유지됨)");
    // 연결 해제 코드(disconnectAll)를 제거했습니다.
    notifyListeners();
  }

  // ==========================================
  // 7. Firebase 전송
  // ==========================================
  Future<void> _sendToFirebase() async {
    // ✅ 데이터 수집 중이 아니면 전송하지 않음
    if (!_isCollectingData) {
      print("⏸️ 데이터 수집 중지 상태 - Firebase 전송 안 함");
      return;
    }

    if (heartRate == 0 && spo2 == 0 && pressureAvg == 0) {
      return;
    }

    try {
      await _db.collection('raw_data').add({
        'userId': userId,
        'sessionId': sessionId,
        'ts': FieldValue.serverTimestamp(),

        // 센서 데이터
        'hr': heartRate,
        'spo2': spo2,
        'pressure_level': pressureAvg,
        'mic_level': micAvg,

        // 추가 정보
        'pressure_1': pressure1,
        'pressure_2': pressure2,
        'pressure_3': pressure3,
        'mic_1': mic1,
        'mic_2': mic2,
        'is_snoring': isSnoring,

        // 배터리
        'pillow_battery': pillowBattery,
        'watch_battery': watchBattery,
      });

      print(
        "✅ Firebase 전송 성공 (심박: $heartRate, 산소: $spo2, 베개배터리: $pillowBattery%, 팔찌배터리: $watchBattery%)",
      );
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
  // 9. 연결 해제
  // ==========================================
  Future<void> disconnectAll() async {
    if (kIsWeb) return;

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

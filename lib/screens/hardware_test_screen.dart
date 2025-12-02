import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class HardwareTestScreen extends StatefulWidget {
  const HardwareTestScreen({super.key});

  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen> {
  // ⏱️ 스톱워치 관련 변수
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = "0.0초";
  String _lastAction = "대기 중";

  // 타이머 시작 함수
  void _startTimer(String actionName) {
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {
      _lastAction = "$actionName 중...";
    });

    _timer?.cancel(); // 기존 타이머 취소
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        // 0.1초 단위로 업데이트
        _elapsedTime =
            "${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}초";
      });
    });
  }

  // 타이머 정지 함수
  void _stopTimer(String statusMessage) {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _lastAction = statusMessage;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = Provider.of<BleService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛠️ 하드웨어 통합 제어 (V7.2)"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 상태 및 타이머 카드
            _buildStatusAndTimerCard(bleService),
            const SizedBox(height: 20),

            // 2. 전체 정지 버튼 (Case '0')
            ElevatedButton.icon(
              onPressed: () {
                bleService.sendRawCommand("0"); // Case 0
                _stopTimer("⛔ 전체 정지됨");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.stop_circle, size: 30),
              label: const Text("⛔ 전체 정지 (비상)",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            // 3. 에어백(펌프/밸브) 제어 섹션
            const Text("💨 에어백 제어",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const Divider(thickness: 2),

            // ★ [Case 'a'] 공기 제어만 멈춤 버튼
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              child: ElevatedButton.icon(
                onPressed: () {
                  bleService.sendRawCommand("a"); // Case 'a' (아두이노 코드 반영)
                  _stopTimer("✋ 공기 제어만 멈춤");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[100],
                  foregroundColor: Colors.indigo[900],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.pause_circle_filled),
                label: const Text("✋ 공기만 멈춤 (진동은 유지)",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            // Cell 1 (Case '1', '4')
            _buildControlRow(context, bleService, "Cell 1 (목)", "1", "4"),
            const Divider(),
            // Cell 2 (Case '2', '5')
            _buildControlRow(context, bleService, "Cell 2 (머리)", "2", "5"),
            const Divider(),
            // Cell 3 (Case '3', '6')
            _buildControlRow(context, bleService, "Cell 3 (전체)", "3", "6"),

            const SizedBox(height: 30),

            // 4. 진동 제어 섹션 (Case '7', '8', '9')
            const Text("📳 진동 모터 제어",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange)),
            const Divider(thickness: 2),
            const SizedBox(height: 10),

            Row(
              children: [
                // 강한 진동 (Case '7')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      bleService.sendRawCommand("7");
                      // 진동은 타이머와 별개로 동작하므로 타이머는 건드리지 않거나,
                      // 진동 시작을 알리는 용도로만 사용
                      setState(() {
                        _lastAction = "📳 진동 강(100%)";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.vibration),
                        Text("강하게"),
                        Text("(100%)", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 약한 진동 (Case '8')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      bleService.sendRawCommand("8");
                      setState(() {
                        _lastAction = "📳 진동 약(70%)";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.waves),
                        Text("약하게"),
                        Text("(70%)", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 진동 끄기 (Case '9')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      bleService.sendRawCommand("9");
                      setState(() {
                        _lastAction = "📳 진동 꺼짐";
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.notifications_off),
                        Text("진동만"),
                        Text("끄기", style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndTimerCard(BleService bleService) {
    bool isConnected = bleService.isPillowConnected;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 연결 상태
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: isConnected ? Colors.green : Colors.red),
              const SizedBox(width: 10),
              Text(isConnected ? "베개 연결됨" : "베개 연결 안 됨",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(),
          const SizedBox(height: 10),

          // ⏱️ 타이머 및 상태 표시부
          Text(_lastAction,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            _elapsedTime,
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
                fontFamily: "monospace"),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(BuildContext context, BleService ble, String title,
      String inflateCmd, String deflateCmd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ble.sendRawCommand(inflateCmd);
                    _startTimer("$title 주입");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text("주입 (ON)"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ble.sendRawCommand(deflateCmd);
                    _startTimer("$title 배출");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text("배출 (30s)"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

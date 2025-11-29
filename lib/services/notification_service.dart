// lib/services/notification_service.dart

import 'package:flutter/material.dart'; // debugPrint를 위해 추가
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'dart:io' show Platform; // 플랫폼 확인을 위해 추가

class NotificationService {
  // 싱글톤 패턴 구현
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ✅ 안전장치: 초기화 여부 확인 플래그
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // 1. 알림 서비스 초기화 (main.dart에서 호출됨)
  Future<void> init() async {
    if (_isInitialized) return;

    debugPrint("🔔 NotificationService 초기화 시작...");

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      // 플러그인 초기화
      await _plugin.initialize(settings);

      // ✅ [핵심 추가] 안드로이드 13 이상을 위한 알림 권한 요청
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _plugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        await androidImplementation?.requestNotificationsPermission();
        debugPrint("🔔 안드로이드 알림 권한 요청 팝업 호출됨");
      }

      _isInitialized = true;
      debugPrint("✅ NotificationService 초기화 최종 완료 (플래그: $_isInitialized)");
    } catch (e) {
      debugPrint("🚨 NotificationService 초기화 실패: $e");
      // 초기화 실패 시 플래그를 false로 유지
      _isInitialized = false;
    }
  }

  // ... (나머지 메서드들은 기존과 동일하지만, 안전을 위해 다시 포함합니다) ...

  // 2. 수면 팁 목록 (가이드 알림용)
  final List<String> _sleepTips = [
    "잠들기 1시간 전, 스마트폰 화면 대신 책을 읽어보는 건 어떨까요?",
    "따뜻한 물로 샤워를 하면 체온이 내려가면서 숙면을 유도합니다.",
  ];

  // 3. 매일 밤 9시에 수면 팁 알림 예약
  Future<void> scheduleDailySleepTip() async {
    if (!_isInitialized) {
      debugPrint("⚠️ 알림 서비스가 초기화되지 않아 예약을 건너뜁니다.");
      return;
    }
    // ... (랜덤 팁 선택 및 details 설정 코드 생략 - 필요 시 이전 코드 참고) ...
    // 여기서는 핵심 로직만 보여드립니다. 실제 사용 시에는 이전 코드의 전체 내용을 사용하세요.
    debugPrint("⚠️ (테스트용) scheduleDailySleepTip 호출됨 - 실제 구현 필요");
  }

  // 6. 모든 알림 예약 취소
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _plugin.cancelAll();
  }

  // 7. 즉시 테스트 알림 발송
  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      debugPrint("🚨 알림 서비스가 초기화되지 않았습니다.");
      return;
    }
    // ... (이전 코드 참조) ...
    debugPrint("⚠️ (테스트용) showTestNotification 호출됨 - 실제 구현 필요");
  }

  // 8. 아침 수면 리포트 알림 예약
  Future<void> scheduleDailyReportNotification(
    String title,
    String body,
  ) async {
    if (!_isInitialized) return;
    // ... (이전 코드 참조) ...
    debugPrint("⚠️ (테스트용) scheduleDailyReportNotification 호출됨 - 실제 구현 필요");
  }

  // 9. ✅ [핵심] 즉시 경고 알림 발송 (여기가 문제의 지점)
  Future<void> showImmediateWarning(int id, String title, String body) async {
    // 🔹 1차 방어선: 플래그 확인
    if (!_isInitialized) {
      debugPrint("🚨 [방어 성공] 초기화 플래그가 false입니다. 알림을 보내지 않습니다.");
      return;
    }

    debugPrint("🔔 알림 발송 시도: $title (ID: $id)");

    try {
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_warning_channel',
          '수면 경고',
          channelDescription: '수면 중 문제 발생 시 알림을 보냅니다.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // 🔹 2차 방어선: 실제 플러그인 호출 감싸기
      await _plugin.show(id, title, body, details);
      debugPrint("✅ 알림 발송 성공: $title");
    } catch (e) {
      // 🔹 여기가 핵심: 플러그인 내부 오류를 잡아서 앱 죽음 방지
      debugPrint("🚨 경고 알림 발송 중 플러그인 내부 오류 발생: $e");
      debugPrint("👉 조치 필요: 앱을 완전히 삭제 후 다시 설치하고, 알림 권한을 허용해주세요.");

      // 만약 이 오류가 계속되면 초기화가 풀린 것으로 간주
      _isInitialized = false;
    }
  }
}

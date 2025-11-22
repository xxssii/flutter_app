// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

class NotificationService {
  // 싱글톤 패턴
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // 1. 알림 서비스 초기화 (main.dart에서 호출됨)
  Future<void> init() async {
    // ... (기존 init 코드와 동일)
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
    await _plugin.initialize(settings);
  }

  // 2. 수면 팁 목록
  final List<String> _sleepTips = [
    "잠들기 1시간 전, 스마트폰 화면 대신 책을 읽어보는 건 어떨까요?",
    "따뜻한 물로 샤워를 하면 체온이 내려가면서 숙면을 유도합니다.",
    "저녁 7시 이후에는 카페인 섭취를 피하는 것이 좋습니다.",
  ];

  // 3. 매일 밤 9시에 팁 알림 예약 (SettingsState에서 호출됨)
  Future<void> scheduleDailySleepTip() async {
    // ... (기존 scheduleDailySleepTip 코드와 동일)
    final String randomTip = _sleepTips[Random().nextInt(_sleepTips.length)];
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sleep_tip_channel',
        '수면 가이드 팁',
        channelDescription: '매일 밤 수면 팁을 제공합니다.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
    ); // 밤 9시
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      0,
      '🌙 오늘의 수면 팁',
      randomTip,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 6. 모든 알림 취소 (토글을 끌 때 SettingsState에서 호출됨)
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // 7. 즉시 테스트 알림 (SettingsScreen에서 사용)
  Future<void> showTestNotification() async {
    // ... (기존 showTestNotification 코드와 동일)
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sleep_tip_channel',
        '수면 가이드 팁',
        channelDescription: '테스트 알림입니다.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(0, '🔔 알림 테스트', '가이드 알림이 정상적으로 작동합니다!', details);
  }

  // --- ✅ [신규] 알림 기능 추가 ---

  // 8. ✅ [신규] 아침 수면 리포트 알림 예약
  Future<void> scheduleDailyReportNotification(
    String reportTitle,
    String reportBody,
  ) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sleep_report_channel',
        '수면 리포트',
        channelDescription: '매일 아침 수면 리포트를 제공합니다.',
        importance: Importance.max, // 중요도 최대로 설정
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // 다음 날 아침 8시에 예약
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      8,
    ); // 아침 8시

    // 오늘 아침 8시가 지났으면 내일 아침 8시로
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1, // 알림 ID (팁 알림과 달라야 함)
      reportTitle, // "어젯밤 수면 점수는 85점입니다."
      reportBody, // "자세한 내용을 보려면 탭하세요."
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );
    print("수면 리포트 알림이 다음날 아침 8시에 예약되었습니다.");
  }

  // 9. ✅ [신규] 즉시 경고 알림 (효율, 코골이)
  Future<void> showImmediateWarning(int id, String title, String body) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sleep_warning_channel',
        '수면 경고',
        channelDescription: '수면 중 문제 발생 시 즉시 알림을 보냅니다.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id, // 2: 효율, 3: 코골이
      title,
      body,
      details,
    );
    print("즉시 경고 알림 전송: $title");
  }
}

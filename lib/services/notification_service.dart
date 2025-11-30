// lib/services/notification_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ========================================
// 🔔 백그라운드 메시지 핸들러 (최상위 함수)
// ========================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 백그라운드 메시지 수신: ${message.notification?.title}');
}

// ========================================
// 🔔 NotificationService 클래스
// ========================================
class NotificationService {
  // ✅ 싱글톤 패턴
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // ========================================
  // 📦 인스턴스 변수
  // ========================================
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  // ========================================
  // 🔍 플랫폼 지원 체크
  // ========================================
  /// FCM이 현재 플랫폼에서 지원되는지 확인
  /// FCM은 Android, iOS, Web에서만 지원됩니다
  bool _isFCMSupported() {
    if (kIsWeb) return true; // 웹은 지원

    try {
      // Android 또는 iOS만 FCM 지원
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      // Platform을 사용할 수 없는 경우 (웹 등)
      return kIsWeb;
    }
  }

  // ========================================
  // ✨ 1. 초기화 (Firebase + 로컬 알림)
  // ========================================
  Future<void> init({String? userId}) async {
    if (_isInitialized) {
      debugPrint('🔔 알림 서비스가 이미 초기화되었습니다.');
      return;
    }

    try {
      debugPrint('🔔 알림 서비스 초기화 시작...');

      // ✅ 플랫폼 체크: FCM 지원 확인
      final fcmSupported = _isFCMSupported();

      if (!fcmSupported) {
        debugPrint('ℹ️ FCM은 현재 플랫폼(Windows/Linux/macOS)에서 지원되지 않습니다.');
        debugPrint('ℹ️ 로컬 알림만 초기화합니다. (FCM은 Android/iOS/Web에서만 지원됩니다)');

        // 로컬 알림만 초기화
        await _initializeLocalNotifications();
        _isInitialized = true;
        debugPrint('✅ 알림 서비스 초기화 완료 (로컬 알림만)');
        return;
      }

      // ============ FCM 지원 플랫폼 (Android/iOS/Web)에서만 실행 ============

      // 1-1. 알림 권한 요청 (iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ 알림 권한 승인됨!');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('✅ 임시 알림 권한 승인됨');
      } else {
        debugPrint('❌ 알림 권한 거부됨');
        return;
      }

      // 1-2. FCM 토큰 받기
      _fcmToken = await _fcm.getToken();
      if (_fcmToken != null) {
        debugPrint('📱 FCM 토큰: $_fcmToken');

        // 1-3. Firestore에 저장 (userId가 있으면)
        if (userId != null) {
          await _saveTokenToFirestore(userId, _fcmToken!);
        }
      }

      // 1-4. 토큰 갱신 리스너
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM 토큰 갱신됨: $newToken');
        _fcmToken = newToken;
        if (userId != null) {
          _saveTokenToFirestore(userId, newToken);
        }
      });

      // 1-5. 백그라운드 메시지 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 1-6. 로컬 알림 초기화
      await _initializeLocalNotifications();

      // 1-7. 메시지 리스너 등록
      _setupMessageListeners();

      _isInitialized = true;
      debugPrint('✅ 알림 서비스 초기화 완료!');
    } catch (e) {
      debugPrint('❌ 알림 서비스 초기화 실패: $e');
      rethrow; // 에러를 다시 throw하여 상위에서 처리 가능하게 함
    }
  }

  // ========================================
  // 💾 2. Firestore에 FCM 토큰 저장
  // ========================================
  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'notificationSettings': {
          'sleepReport': true, // 수면 리포트 알림
          'sleepScore': true, // 수면 효율 알림
          'snoring': true, // 코골이 알림
          'guide': true, // 가이드 알림
        }
      }, SetOptions(merge: true)); // 기존 데이터 유지

      debugPrint('✅ FCM 토큰 Firestore에 저장 완료!');
    } catch (e) {
      debugPrint('❌ 토큰 저장 실패: $e');
    }
  }

  // ========================================
  // 🔔 3. 로컬 알림 초기화
  // ========================================
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Windows 설정 추가 (Windows에서 필수)
    // GUID는 Windows 알림을 앱과 연결하기 위한 고유 ID입니다
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Smart Sleep Care',
      appUserModelId: 'com.smartsleepcare.app',
      guid: '3F2504E0-4F89-11D3-9A0C-0305E82C3301', // 앱 고유 GUID
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      windows: windowsSettings, // ✅ Windows 설정 추가
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 알림 탭됨: ${details.payload}');
        // TODO: 여기에 화면 이동 로직 추가
        _handleNotificationTap(details.payload);
      },
    );

    debugPrint('✅ 로컬 알림 초기화 완료');
  }

  // ========================================
  // 📨 4. 메시지 리스너 설정
  // ========================================
  void _setupMessageListeners() {
    // 4-1. 앱이 포그라운드(실행 중)일 때
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 포그라운드 알림 수신: ${message.notification?.title}');

      if (message.notification != null) {
        _showLocalNotification(
          message.notification!,
          payload: message.data['type'] ?? 'default',
        );
      }
    });

    // 4-2. 백그라운드 알림 탭했을 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 백그라운드 알림 탭됨: ${message.notification?.title}');
      _handleNotificationTap(message.data['type']);
    });

    // 4-3. 앱이 완전히 종료된 상태에서 알림 탭했을 때
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📱 종료 상태 알림 탭됨: ${message.notification?.title}');
        _handleNotificationTap(message.data['type']);
      }
    });
  }

  // ========================================
  // 📲 5. 로컬 알림 표시 (앱 실행 중)
  // ========================================
  Future<void> _showLocalNotification(
    RemoteNotification notification, {
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sleep_channel', // 채널 ID
      'Sleep Notifications', // 채널 이름
      channelDescription: '수면 관련 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode, // 알림 ID
      notification.title,
      notification.body,
      platformDetails,
      payload: payload,
    );
  }

  // ========================================
  // 🎯 6. 알림 탭 처리
  // ========================================
  void _handleNotificationTap(String? type) {
    debugPrint('🎯 알림 타입: $type');

    // TODO: 화면 이동 로직 추가
    switch (type) {
      case 'sleep_report':
        debugPrint('→ 수면 리포트 화면으로 이동');
        // Navigator.push(...);
        break;
      case 'sleep_efficiency':
        debugPrint('→ 데이터 화면으로 이동');
        break;
      case 'snoring':
        debugPrint('→ 코골이 분석 화면으로 이동');
        break;
      case 'guide':
        debugPrint('→ 가이드 화면으로 이동');
        break;
      default:
        debugPrint('→ 기본 화면');
    }
  }

  // ========================================
  // 🧪 7. 테스트 알림
  // ========================================
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: '테스트용 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // 알림 ID
      '🔔 테스트 푸시 알림',
      '딩동! 알림이 잘 도착하네요. 앞으로도 꿀잠 소식 전해드릴게요! 🔔',
      platformDetails,
    );

    debugPrint('🔔 테스트 알림 전송됨');
  }

  // ========================================
  // 📅 8. 리포트 알림 예약 (매일 아침 8시)
  // ========================================
  Future<void> scheduleDailyReportNotification(
    String title,
    String body,
  ) async {
    // TODO: 실제로는 Cloud Functions Scheduler 사용 권장
    // 여기서는 로컬 알림으로 간단히 처리
    debugPrint('🔔 리포트 알림 예약됨: $title - $body');

    // 로컬 알림으로 즉시 표시 (테스트용)
    const androidDetails = AndroidNotificationDetails(
      'report_channel',
      'Report Notifications',
      channelDescription: '수면 리포트 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // 알림 ID
      title,
      body,
      platformDetails,
    );
  }

  // ========================================
  // ⚠️ 9. 즉시 경고 알림 (무호흡, 코골이 등)
  // ========================================
  // ✅ [핵심] 즉시 경고 알림 (무호흡, 코골이 등) - 앱 죽음 방지 적용
  Future<void> showImmediateWarning(int id, String title, String body) async {
    // 🔹 1차 방어선: 플래그 확인
    if (!_isInitialized) {
      debugPrint("🚨 [방어 성공] 초기화 플래그가 false입니다. 알림을 보내지 않습니다.");
      return;
    }

    debugPrint("🔔 알림 발송 시도: $title (ID: $id)");

    try {
      const androidDetails = AndroidNotificationDetails(
        'warning_channel',
        'Warning Notifications',
        channelDescription: '긴급 경고 알림',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 🔹 2차 방어선: 실제 플러그인 호출 감싸기
      await _flutterLocalNotificationsPlugin.show(
          id, title, body, platformDetails);
      debugPrint("✅ 알림 발송 성공: $title");
    } catch (e) {
      // 🔹 여기가 핵심: 플러그인 내부 오류를 잡아서 앱 죽음 방지
      debugPrint("🚨 경고 알림 발송 중 플러그인 내부 오류 발생: $e");
      debugPrint("👉 조치 필요: 앱을 완전히 삭제 후 다시 설치하고, 알림 권한을 허용해주세요.");

      // 만약 이 오류가 계속되면 초기화가 풀린 것으로 간주
      _isInitialized = false;
    }
  }

  // ========================================
  // 💡 10. 수면 팁 알림 예약
  // ========================================
  Future<void> scheduleDailySleepTip() async {
    debugPrint('💡 수면 팁 알림 예약됨');

    // 로컬 알림으로 즉시 표시 (테스트용)
    const androidDetails = AndroidNotificationDetails(
      'tip_channel',
      'Tip Notifications',
      channelDescription: '수면 팁 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tips = [
      '💡 오늘은 취침 1시간 전 스마트폰을 내려놓아 보세요.',
      '💡 저녁 6시 이후 카페인을 피하면 더 깊은 잠을 잘 수 있어요.',
      '💡 규칙적인 수면 시간이 수면의 질을 높입니다.',
      '💡 침실 온도를 18-20도로 유지하면 좋아요.',
      '💡 취침 전 가벼운 스트레칭은 숙면에 도움이 됩니다.',
    ];

    final randomTip = tips[DateTime.now().millisecond % tips.length];

    await _flutterLocalNotificationsPlugin.show(
      2, // 알림 ID
      '🌙 오늘의 수면 팁',
      randomTip,
      platformDetails,
    );
  }

  // ========================================
  // 🗑️ 11. 모든 알림 취소
  // ========================================
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🗑️ 모든 알림 취소됨');
  }

  // ========================================
  // ⚙️ 12. 알림 설정 업데이트
  // ========================================
  Future<void> updateNotificationSettings({
    required String userId,
    required String
        settingType, // 'sleepReport', 'sleepScore', 'snoring', 'guide'
    required bool enabled,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notificationSettings.$settingType': enabled,
      });
      debugPrint('✅ 알림 설정 업데이트: $settingType = $enabled');
    } catch (e) {
      debugPrint('❌ 알림 설정 업데이트 실패: $e');
    }
  }

  // ========================================
  // 📖 13. 알림 설정 가져오기
  // ========================================
  Future<Map<String, bool>> getNotificationSettings(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final settings =
            doc.data()?['notificationSettings'] as Map<String, dynamic>? ?? {};
        return {
          'sleepReport': settings['sleepReport'] ?? true,
          'sleepScore': settings['sleepScore'] ?? true,
          'snoring': settings['snoring'] ?? true,
          'guide': settings['guide'] ?? true,
        };
      }
    } catch (e) {
      debugPrint('❌ 알림 설정 가져오기 실패: $e');
    }

    // 기본값
    return {
      'sleepReport': true,
      'sleepScore': true,
      'snoring': true,
      'guide': true,
    };
  }

  // ========================================
  // 🔍 14. FCM 토큰 가져오기
  // ========================================
  String? get fcmToken => _fcmToken;

  // ========================================
  // ✅ 15. 초기화 상태 확인
  // ========================================
  bool get isInitialized => _isInitialized;
}

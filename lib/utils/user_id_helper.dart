// lib/utils/user_id_helper.dart

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserIdHelper {
  static String? _cachedUserId;

  /// 사용자 ID 가져오기 (없으면 자동 생성)
  static Future<String> getUserId() async {
    // 이미 메모리에 있으면 바로 반환
    if (_cachedUserId != null) {
      return _cachedUserId!;
    }

    final prefs = await SharedPreferences.getInstance();

    // SharedPreferences에서 확인
    String? userId = prefs.getString('userId');

    if (userId == null) {
      // 없으면 새로 생성
      userId = await _generateUserId();
      await prefs.setString('userId', userId);
      debugPrint('✅ 새 사용자 ID 생성: $userId');
    } else {
      debugPrint('✅ 기존 사용자 ID 로드: $userId');
    }

    _cachedUserId = userId;
    return userId;
  }

  /// 디바이스 정보 기반 고유 ID 생성
  static Future<String> _generateUserId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // 예: android_SM-G991N_abc123def
        return 'android_${androidInfo.model}_${androidInfo.id.substring(0, 8)}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'ios_${iosInfo.model}_${iosInfo.identifierForVendor?.substring(0, 8) ?? 'unknown'}';
      } else {
        return 'web_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('⚠️ 디바이스 ID 생성 실패, 타임스탬프 사용: $e');
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// 캐시 초기화 (로그아웃 시 사용)
  static void clearCache() {
    _cachedUserId = null;
  }
}

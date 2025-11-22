// lib/state/profile_state.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // UUID 생성을 위해
import '../models/user_profile.dart';

class ProfileState extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  // 모든 프로필 목록
  final List<UserProfile> _profiles = [];

  // 현재 활성화된 프로필 ID
  String? _activeProfileId;

  // --- 기본 프로필 (임시) ---
  // 앱 시작 시 기본 사용자를 하나 만듭니다.
  ProfileState() {
    final defaultProfile = UserProfile(
      id: _uuid.v4(),
      name: "김지지",
      age: 28,
      height: 170,
      weight: 65,
      sleepGoal: 8.0,
      sleepPurpose: "건강 관리",
      bedtime: const TimeOfDay(hour: 23, minute: 0),
      wakeTime: const TimeOfDay(hour: 7, minute: 0),
    );
    _profiles.add(defaultProfile);
    _activeProfileId = defaultProfile.id;
  }

  // --- Getters ---
  List<UserProfile> get allProfiles => _profiles;

  UserProfile get activeProfile {
    // 활성 프로필 ID에 해당하는 프로필을 찾아 반환
    return _profiles.firstWhere(
      (p) => p.id == _activeProfileId,
      orElse: () => _profiles.first, // 없으면 첫 번째 프로필 반환 (안전장치)
    );
  }

  // --- Actions ---

  // 새 프로필 추가 (add_profile_screen.dart에서 사용)
  void addProfile(UserProfile profile) {
    _profiles.add(profile);
    // 새 프로필을 추가하면 자동으로 활성 프로필로 설정
    _activeProfileId = profile.id;
    notifyListeners();
  }

  // 활성 프로필 변경 (profile_screen.dart에서 사용)
  void setActiveProfile(String profileId) {
    _activeProfileId = profileId;
    notifyListeners();
  }
}

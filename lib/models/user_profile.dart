// lib/models/user_profile.dart

import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final int age;
  final double height;
  final double weight;
  final double sleepGoal; // 수면 목표 (시간)
  final String sleepPurpose; // 수면 목적
  final TimeOfDay bedtime; // 선호 취침 시간
  final TimeOfDay wakeTime; // 선호 기상 시간

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.sleepGoal,
    required this.sleepPurpose,
    required this.bedtime,
    required this.wakeTime,
  });
}

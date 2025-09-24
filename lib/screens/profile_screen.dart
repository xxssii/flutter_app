// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'new_profile_screen.dart';

// 임시 프로필 데이터 모델
class UserProfile {
  final String name;
  final int age;
  final String sleepGoal;
  final double height;
  final double weight;
  final String sleepPurpose;
  final String bedtime;
  final String wakeTime;

  UserProfile({
    required this.name,
    required this.age,
    required this.sleepGoal,
    required this.height,
    required this.weight,
    required this.sleepPurpose,
    required this.bedtime,
    required this.wakeTime,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 현재 활성화된 프로필 정보를 담을 임시 변수 (추후 상태관리로 연동)
  UserProfile _currentProfile = UserProfile(
    name: "김코딩",
    age: 28,
    height: 175.0,
    weight: 70.0,
    sleepGoal: "8시간",
    sleepPurpose: "건강 관리",
    bedtime: "오후 11:00",
    wakeTime: "오전 07:00",
  );

  // 임시 프로필 목록
  final List<UserProfile> _allProfiles = [
    UserProfile(
      name: "김코딩",
      age: 28,
      height: 175.0,
      weight: 70.0,
      sleepGoal: "8시간",
      sleepPurpose: "건강 관리",
      bedtime: "오후 11:00",
      wakeTime: "오전 07:00",
    ),
    UserProfile(
      name: "김철수",
      age: 30,
      height: 180.0,
      weight: 75.0,
      sleepGoal: "7시간",
      sleepPurpose: "집중력 및 생산성 향상",
      bedtime: "오전 12:00",
      wakeTime: "오전 07:00",
    ),
    UserProfile(
      name: "박영희",
      age: 25,
      height: 165.0,
      weight: 55.0,
      sleepGoal: "7.5시간",
      sleepPurpose: "스트레스 해소",
      bedtime: "오후 10:30",
      wakeTime: "오전 06:00",
    ),
  ];

  // 프로필을 선택하는 메서드
  void _selectProfile(UserProfile profile) {
    setState(() {
      _currentProfile = profile;
    });
    // 프로필 선택 후 이전 화면으로 돌아갑니다.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필', style: AppTextStyles.appBarTitle),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primaryNavy),
            onPressed: () {
              // 프로필 수정 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('프로필 정보', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            _buildProfileDetailsCard(context),
            const SizedBox(height: 24),
            Text('다른 프로필', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            _buildProfileList(context),
            const SizedBox(height: 16),
            _buildAddProfileButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 40,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 16),
                Text(_currentProfile.name, style: AppTextStyles.heading1),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow('나이', '${_currentProfile.age}세'),
            _buildInfoRow('신장', '${_currentProfile.height}cm'),
            _buildInfoRow('체중', '${_currentProfile.weight}kg'),
            _buildInfoRow('수면 목표', _currentProfile.sleepGoal),
            _buildInfoRow('수면 목적', _currentProfile.sleepPurpose),
            _buildInfoRow('선호 취침 시간', _currentProfile.bedtime),
            _buildInfoRow('선호 기상 시간', _currentProfile.wakeTime),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyText),
          Text(
            value,
            style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allProfiles.length,
      itemBuilder: (context, index) {
        final profile = _allProfiles[index];
        final isCurrent = profile.name == _currentProfile.name;

        // 현재 프로필은 목록에서 제외합니다.
        if (isCurrent) {
          return const SizedBox.shrink();
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(profile.name),
            subtitle: Text('${profile.age}세, 목표 ${profile.sleepGoal}'),
            trailing: isCurrent
                ? const Icon(Icons.check_circle, color: AppColors.primaryNavy)
                : const Icon(Icons.circle_outlined),
            onTap: () => _selectProfile(profile),
          ),
        );
      },
    );
  }

  Widget _buildAddProfileButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProfileScreen()),
        );
      },
      child: const Text('새 프로필 추가'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

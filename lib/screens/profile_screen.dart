// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../state/profile_state.dart';
import '../models/user_profile.dart'; // ✅ 분리된 모델 파일 임포트
import 'add_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileState>(
      builder: (context, profileState, child) {
        // ProfileState에서 현재 활성 프로필과 모든 프로필 목록을 가져옴
        final UserProfile activeProfile = profileState.activeProfile;
        final List<UserProfile> allProfiles = profileState.allProfiles;

        return Scaffold(
          appBar: AppBar(
            title: Text('프로필 관리', style: AppTextStyles.appBarTitle),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primaryNavy),
                tooltip: '새 프로필 추가',
                onPressed: () {
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
                Text('현재 활성 프로필', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                _buildProfileDetailsCard(context, activeProfile), // ✅ 활성 프로필 표시
                const SizedBox(height: 24),
                Text('다른 프로필 목록', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                _buildProfileList(
                  context,
                  profileState,
                  allProfiles,
                ), // ✅ 모든 프로필 목록 표시
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailsCard(BuildContext context, UserProfile profile) {
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
                Text(profile.name, style: AppTextStyles.heading1),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow('나이', '${profile.age}세'),
            _buildInfoRow('신장', '${profile.height}cm'),
            _buildInfoRow('체중', '${profile.weight}kg'),
            _buildInfoRow('수면 목표', '${profile.sleepGoal} 시간'),
            _buildInfoRow('수면 목적', profile.sleepPurpose),
            _buildInfoRow('선호 취침 시간', profile.bedtime.format(context)),
            _buildInfoRow('선호 기상 시간', profile.wakeTime.format(context)),
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

  Widget _buildProfileList(
    BuildContext context,
    ProfileState profileState,
    List<UserProfile> profiles,
  ) {
    if (profiles.length <= 1) {
      return Center(
        child: Text('추가된 프로필이 없습니다.', style: AppTextStyles.secondaryBodyText),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final bool isActive = profile.id == profileState.activeProfile.id;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(
              profile.name,
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text('${profile.age}세, ${profile.sleepPurpose}'),
            trailing: isActive
                ? const Icon(Icons.check_circle, color: AppColors.successGreen)
                : const Icon(
                    Icons.circle_outlined,
                    color: AppColors.secondaryText,
                  ),
            onTap: () {
              // ✅ 프로필 전환
              profileState.setActiveProfile(profile.id);
            },
          ),
        );
      },
    );
  }
}

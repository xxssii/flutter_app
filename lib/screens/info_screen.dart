// lib/screens/info_screen.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('프로젝트 정보', style: AppTextStyles.appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '생체신호 기반 사용자 맞춤형 스마트 수면 케어 베개 통합 플랫폼', // ✅ 여기에 프로젝트 제목
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: 8),
            Text(
              '이 앱은 [한밭대학교] 캡스톤 디자인 프로젝트로 제작되었습니다.', // ✅ 여기에 학교/과목명
              style: AppTextStyles.secondaryBodyText,
            ),
            const Divider(height: 40),

            Text('지도교수', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              '한 정 규 교수', // ✅ 여기에 교수님 성함
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 24),

            Text('Zzz-Lab팀', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              '임 지 영 (팀장)', // ✅ 여기에 팀원 정보
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 4),
            Text(
              '배 유 정', // ✅ 여기에 팀원 정보
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 4),
            Text(
              '이 서 현', // ✅ 여기에 팀원 정보
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 4),
            Text(
              '김 서 연', // ✅ 여기에 팀원 정보
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 4),
            Text(
              '이 수 미', // ✅ 여기에 팀원 정보
              style: AppTextStyles.bodyText,
            ),
          ],
        ),
      ),
    );
  }
}

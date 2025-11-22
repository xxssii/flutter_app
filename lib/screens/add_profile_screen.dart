// lib/screens/add_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../state/profile_state.dart';
import '../utils/app_text_styles.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({Key? key}) : super(key: key);

  @override
  _AddProfileScreenState createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();

  // 폼 필드를 위한 컨트롤러
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _sleepGoalController = TextEditingController();

  String _sleepPurpose = '건강 관리';
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  final List<String> _sleepPurposes = [
    '건강 관리',
    '집중력 및 생산성 향상',
    '스트레스 해소',
    '불면증 완화',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sleepGoalController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isBedtime) async {
    final TimeOfDay initialTime = isBedtime ? _bedtime : _wakeTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // 폼 데이터로 UserProfile 객체 생성
      final newProfile = UserProfile(
        id: _uuid.v4(),
        name: _nameController.text,
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        sleepGoal: double.parse(_sleepGoalController.text),
        sleepPurpose: _sleepPurpose,
        bedtime: _bedtime,
        wakeTime: _wakeTime,
      );

      // ProfileState에 새 프로필 추가
      Provider.of<ProfileState>(context, listen: false).addProfile(newProfile);

      Navigator.of(context).pop(); // 이전 화면으로 돌아가기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('새 프로필 추가', style: AppTextStyles.appBarTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('기본 정보', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildTextField(_nameController, '이름', '홍길동'),
              _buildNumberField(_ageController, '나이', '30'),
              _buildNumberField(_heightController, '신장 (cm)', '175'),
              _buildNumberField(_weightController, '체중 (kg)', '70'),

              const SizedBox(height: 32),
              Text('수면 설정', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildNumberField(_sleepGoalController, '수면 목표 (시간)', '7.5'),

              _buildSleepPurposeDropdown(),

              _buildTimePicker('선호 취침 시간', _bedtime, true),
              _buildTimePicker('선호 기상 시간', _wakeTime, false),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('프로필 저장'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label을(를) 입력해주세요.';
          return null;
        },
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return '$label을(_를) 입력해주세요.';
          if (double.tryParse(value) == null) return '유효한 숫자를 입력해주세요.';
          return null;
        },
      ),
    );
  }

  Widget _buildSleepPurposeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '수면 목적',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        value: _sleepPurpose,
        items: _sleepPurposes.map((String purpose) {
          return DropdownMenuItem<String>(value: purpose, child: Text(purpose));
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _sleepPurpose = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isBedtime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _selectTime(context, isBedtime),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: Icon(Icons.access_time),
          ),
          child: Text(time.format(context), style: AppTextStyles.bodyText),
        ),
      ),
    );
  }
}

// lib/screens/add_profile_screen.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({Key? key}) : super(key: key);

  @override
  _AddProfileScreenState createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  int? _age;
  double? _height;
  double? _weight;
  double? _sleepGoal;
  String? _sleepPurpose;
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeTime;

  final List<String> _sleepPurposes = [
    '건강 관리',
    '집중력 및 생산성 향상',
    '스트레스 해소',
    '불면증 완화',
  ];

  Future<void> _selectTime(BuildContext context, bool isBedtime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: AppColors.primaryNavy,
            colorScheme: ColorScheme.light(primary: AppColors.primaryNavy),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
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
      _formKey.currentState!.save();
      // 여기에 프로필 정보를 저장하는 로직을 추가합니다.
      // 예: print('이름: $_name, 나이: $_age, 신장: $_height...');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 추가', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('기본 정보', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildTextField('이름', '홍길동', (value) => _name = value!),
              _buildNumberField(
                '나이',
                '30',
                (value) => _age = int.tryParse(value!),
              ),
              _buildNumberField(
                '신장 (cm)',
                '175',
                (value) => _height = double.tryParse(value!),
              ),
              _buildNumberField(
                '체중 (kg)',
                '70',
                (value) => _weight = double.tryParse(value!),
              ),

              const SizedBox(height: 32),
              Text('수면 설정', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildNumberField(
                '수면 목표 (시간)',
                '7.5',
                (value) => _sleepGoal = double.tryParse(value!),
              ),

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
    String label,
    String hint,
    void Function(String?) onSaved,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label을(를) 입력해주세요.';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    String hint,
    void Function(String?) onSaved,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label을(를) 입력해주세요.';
          }
          if (double.tryParse(value) == null) {
            return '유효한 숫자를 입력해주세요.';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildSleepPurposeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '수면 목적',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
        ),
        value: _sleepPurpose,
        items: _sleepPurposes.map((String purpose) {
          return DropdownMenuItem<String>(value: purpose, child: Text(purpose));
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _sleepPurpose = newValue;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '수면 목적을 선택해주세요.';
          }
          return null;
        },
        onSaved: (value) => _sleepPurpose = value!,
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, bool isBedtime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _selectTime(context, isBedtime),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            suffixIcon: Icon(Icons.access_time),
          ),
          child: Text(
            time?.format(context) ?? '시간 선택',
            style: AppTextStyles.bodyText,
          ),
        ),
      ),
    );
  }
}

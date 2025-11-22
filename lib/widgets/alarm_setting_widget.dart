// lib/widgets/alarm_setting_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_state.dart'; // SettingsState를 사용하도록 확정

class AlarmSettingWidget extends StatelessWidget {
  const AlarmSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // SettingsState를 읽어와서 사용
    final settingsState = Provider.of<SettingsState>(context);
    final theme = Theme.of(context);

    // 알람이 켜져 있을 때만 시간 표시를 활성화
    final timeStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color:
          settingsState
              .isAlarmOn // isAlarmOn은 SettingsState에 있음
          ? theme.primaryColor
          : Colors.grey.shade400,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      // 1. 알람 켜짐/꺼짐 상태에 따라 제목 변경
      title: Text(
        settingsState.isAlarmOn ? '기상 알람 켜짐' : '기상 알람 꺼짐',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      // 2. 시간 표시 영역
      subtitle: Text(
        settingsState.alarmTime ==
                null // alarmTime은 SettingsState에 있음
            ? '시간을 설정해 주세요'
            : settingsState.alarmTime!.format(context),
        style: timeStyle,
      ),
      // 3. 토글 스위치 (알람 켜기/끄기 기능)
      trailing: Switch(
        value: settingsState.isAlarmOn,
        onChanged: (bool newValue) {
          settingsState.toggleAlarm(newValue); // toggleAlarm은 SettingsState에 있음
          // 알람을 켰을 때, 시간이 설정 안 되어 있으면 TimePicker를 띄워 시간을 선택하게 유도
          if (newValue && settingsState.alarmTime == null) {
            _selectTime(context, settingsState);
          }
        },
      ),
      // 4. 리스트를 탭하면 시간을 설정할 수 있도록 합니다. (알람이 켜져 있을 때만)
      onTap:
          settingsState
              .isAlarmOn // isAlarmOn은 SettingsState에 있음
          ? () => _selectTime(context, settingsState)
          : null, // 꺼져 있으면 탭해도 아무 일도 일어나지 않음
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    SettingsState settingsState, // SettingsState 인자를 받음
  ) async {
    final TimeOfDay initialTime = settingsState.alarmTime ?? TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        // TimePicker의 색상을 앱 테마에 맞게 조정
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != settingsState.alarmTime) {
      settingsState.setAlarmTime(picked); // setAlarmTime은 SettingsState에 있음
    }
  }
}

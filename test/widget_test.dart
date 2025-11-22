import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/state/settings_state.dart';

// 다른 import들...

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsState()),
        // 다른 Provider들을 여기 추가할 수 있습니다.
      ],
      child: MyApp(), // MyApp 클래스를 사용
    ),
  );
}

// 이 부분이 있어야 합니다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return MaterialApp(
          //...
        );
      },
    );
  }
}

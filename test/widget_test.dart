import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 다른 import들...

void main() {
  runApp(
    MultiProvider(
      providers: [
        //...
      ],
      child: MyApp(), // MyApp 클래스를 사용
    ),
  );
}

// 이 부분이 있어야 합니다.
class MyApp extends StatelessWidget {
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

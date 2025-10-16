// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'screens/home_screen.dart';
import 'screens/data_screen.dart';
import 'screens/pillow_screen.dart';

// ✨ SettingsScreen 위젯은 'screen'이라는 별칭으로 임포트하여 충돌을 피합니다.
import 'screens/settings_screen.dart' as screen;

import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart'; // SettingsState 상태 클래스
import 'state/sleep_data_state.dart';

// ⬇️ Firebase 초기화에 필요한 import 2줄 추가
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => SleepDataState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return MaterialApp(
          title: '스마트 수면 케어',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch:
                MaterialColor(AppColors.primaryNavy.value, const <int, Color>{
                  50: Color(0xFFE3E3E8),
                  100: Color(0xFFB8B8C2),
                  200: Color(0xFF8A8A9B),
                  300: Color(0xFF5C5C73),
                  400: Color(0xFF3B3B57),
                  500: AppColors.primaryNavy,
                  600: Color(0xFF171734),
                  700: Color(0xFF13132D),
                  800: Color(0xFF0F0F26),
                  900: Color(0xFF08081A),
                }),
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryNavy,
              brightness: Brightness.light,
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              surface: AppColors.background,
              onSurface: AppColors.primaryText,
              background: AppColors.background,
              onBackground: AppColors.primaryText,
            ),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.cardBackground,
              foregroundColor: AppColors.primaryText,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: AppTextStyles.heading1.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            // Light Theme Text Theme
            textTheme: const TextTheme(
              bodyLarge: AppTextStyles.bodyText,
              bodyMedium: AppTextStyles.bodyText,
              titleLarge: AppTextStyles.heading1,
              titleMedium: AppTextStyles.heading2,
              titleSmall: AppTextStyles.heading3,
            ),
            cardTheme: CardThemeData(
              color: AppColors.cardBackground,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: AppColors.cardBackground,
              selectedItemColor: AppColors.primaryNavy,
              unselectedItemColor: AppColors.secondaryText,
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: AppColors.primaryNavy,
              linearTrackColor: AppColors.progressBackground,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkPrimaryNavy,
              brightness: Brightness.dark,
              primary: AppColors.darkPrimaryNavy,
              onPrimary: Colors.white,
              surface: AppColors.darkBackground,
              onSurface: AppColors.darkPrimaryText,
              background: AppColors.darkBackground,
              onBackground: AppColors.darkPrimaryText,
            ),
            scaffoldBackgroundColor: AppColors.darkBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkCardBackground,
              foregroundColor: AppColors.darkPrimaryText,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: AppTextStyles.darkHeading1.copyWith(
                color: AppColors.darkPrimaryText,
              ),
            ),
            // Dark Theme Text Theme (텍스트 색상 강제 적용)
            textTheme: TextTheme(
              bodyLarge: AppTextStyles.darkBodyText.copyWith(
                color: AppColors.darkPrimaryText,
              ),
              bodyMedium: AppTextStyles.darkBodyText.copyWith(
                color: AppColors.darkPrimaryText,
              ),
              titleLarge: AppTextStyles.darkHeading1.copyWith(
                color: AppColors.darkPrimaryText,
              ),
              titleMedium: AppTextStyles.darkHeading2.copyWith(
                color: AppColors.darkPrimaryText,
              ),
              titleSmall: AppTextStyles.darkHeading3.copyWith(
                color: AppColors.darkPrimaryText,
              ),
            ),
            cardTheme: CardThemeData(
              color: AppColors.darkCardBackground,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: AppColors.darkCardBackground,
              selectedItemColor: AppColors.darkPrimaryNavy,
              unselectedItemColor: AppColors.darkSecondaryText,
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: AppColors.darkPrimaryNavy,
              linearTrackColor: AppColors.darkProgressBackground,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: AppTextStyles.darkBodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          themeMode: settingsState.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const MainWrapper(),
        );
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(key: Key('homeScreen')),
    const DataScreen(key: Key('dataScreen')),
    const PillowScreen(key: Key('pillowScreen')),
    const screen.SettingsScreen(key: Key('settingsScreen')), // ✨ 별칭 사용
  ];

  @override
  Widget build(BuildContext context) {
    // 현재 테마의 밝기를 확인합니다.
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크 모드일 때 Inactive 텍스트를 흰색으로 강제합니다.
    final Color inactiveTextColor = isDarkMode
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    // 선택된 아이템의 텍스트 색상을 결정합니다.
    final Color activeTitleColor = isDarkMode
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavyBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).cardColor,
        items: [
          BottomNavyBarItem(
            icon: const Icon(Icons.home),
            title: Text(
              'Main',
              style: TextStyle(
                color: _currentIndex == 0
                    ? activeTitleColor
                    : inactiveTextColor,
              ),
            ),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: inactiveTextColor,
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.analytics),
            title: Text(
              'Sleep Report',
              style: TextStyle(
                color: _currentIndex == 1
                    ? activeTitleColor
                    : inactiveTextColor,
              ),
            ),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: inactiveTextColor,
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.bed),
            title: Text(
              'Pillow Control',
              style: TextStyle(
                color: _currentIndex == 2
                    ? activeTitleColor
                    : inactiveTextColor,
              ),
            ),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: inactiveTextColor,
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.settings),
            title: Text(
              'Settings',
              style: TextStyle(
                color: _currentIndex == 3
                    ? activeTitleColor
                    : inactiveTextColor,
              ),
            ),
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: inactiveTextColor,
          ),
        ],
      ),
    );
  }
}

class SettingsScreen {
  const SettingsScreen();
}

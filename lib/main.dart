// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/foundation.dart'; // ✅ 웹 환경 체크(kIsWeb)를 위해 필수

import 'screens/home_screen.dart';
import 'screens/data_screen.dart' as data_screen;
import 'screens/pillow_screen.dart';
import 'screens/settings_screen.dart' as screen;

import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'state/sleep_data_state.dart';
import 'state/profile_state.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// BLE
import 'services/ble_service.dart';

// 알림 및 시간대
import 'services/notification_service.dart';

// ⚠️ dart:io는 웹에서 직접 쓰면 에러가 나므로 조심해야 합니다.
import 'dart:io' show Platform;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화 (에러 방지용 try-catch)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("⚠️ Firebase 초기화 경고: $e");
  }

  // 2. 알림 및 시간대 초기화 (웹 호환성 처리)
  try {
    await _configureLocalTimeZone();

    // ✅ [핵심] 웹이 아닐 때만(!kIsWeb) 알림 기능을 켭니다.
    // 웹에서 NotificationService를 그냥 켜면 앱이 멈춥니다.
    if (!kIsWeb) {
      await NotificationService.instance.init();
    }
  } catch (e) {
    print("⚠️ 초기화 설정 중 오류 (무시 가능): $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => SleepDataState()),
        ChangeNotifierProvider(create: (_) => ProfileState()),
        ChangeNotifierProxyProvider2<BleService, SettingsState, AppState>(
          create: (_) => AppState(),
          update: (context, bleService, settingsState, appState) =>
              appState!..updateStates(bleService, settingsState),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// 로컬 시간대 설정 함수 (웹 에러 방지 수정)
Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();

  // ✅ [핵심] 웹(Chrome)이라면 여기서 함수를 끝냅니다.
  // 아래의 Platform 코드를 실행하면 앱이 죽기 때문입니다.
  if (kIsWeb) {
    print("🌐 웹 환경 감지: 모바일 전용 설정 건너뜀");
    return;
  }

  // 여기부터는 모바일(앱)일 때만 실행됨
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isLinux) {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("타임존 설정 실패: $e");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return MaterialApp(
          title: '스마트 수면 케어',
          debugShowCheckedModeBanner: false,

          // --- 라이트 모드 테마 ---
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

          // --- 다크 모드 테마 ---
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
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(key: Key('homeScreen')),
    const data_screen.DataScreen(key: Key('dataScreen')),
    const PillowScreen(key: Key('pillowScreen')),
    const screen.SettingsScreen(key: Key('settingsScreen')),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveTextColor = isDarkMode
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
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

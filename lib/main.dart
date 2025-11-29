// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용

import 'screens/home_screen.dart';
import 'screens/data_screen.dart' as data_screen;
import 'screens/pillow_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/sleep_provider.dart';

import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'utils/user_id_helper.dart';

import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'state/sleep_data_state.dart';
import 'state/profile_state.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// BLE
import 'services/ble_service.dart';

// ✅ 실제 FCM 알림 서비스
import 'services/notification_service.dart';

import 'dart:io' show Platform;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase 초기화 성공!');
  } catch (e) {
    debugPrint('⚠️ Firebase 초기화 경고: $e');
  }
  String userId = 'demoUser'; // 기본값
  try {
    userId = await UserIdHelper.getUserId();
    debugPrint('✅ 사용자 ID: $userId');
  } catch (e) {
    debugPrint('⚠️ 사용자 ID 생성 실패, demoUser 사용: $e');
  }

  // 3. FCM 알림 서비스 초기화
  try {
    // ✅ 실제 FCM 초기화 (플랫폼 체크는 NotificationService 내부에서 처리)
    await NotificationService.instance.init(
      userId: userId, // 자동 생성된 ID 사용!
    );
    debugPrint('✅ 알림 서비스 초기화 완료!');
  } catch (e) {
    debugPrint('⚠️ 알림 서비스 초기화 실패: $e');
    // Windows/Linux/macOS에서는 정상적으로 플랫폼 제한 메시지가 표시됩니다.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => SleepDataState()),
        ChangeNotifierProvider(create: (_) => ProfileState()),
        // ✅ [Fix] SleepProvider 추가
        ChangeNotifierProvider(create: (_) => SleepProvider()),
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
            primarySwatch: MaterialColor(
              AppColors.primaryNavy.value,
              const <int, Color>{
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
              },
            ),
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
          themeMode:
              settingsState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
    const SettingsScreen(key: Key('settingsScreen')),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveTextColor =
        isDarkMode ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final Color activeTitleColor =
        isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary;

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
                color:
                    _currentIndex == 0 ? activeTitleColor : inactiveTextColor,
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
                color:
                    _currentIndex == 1 ? activeTitleColor : inactiveTextColor,
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
                color:
                    _currentIndex == 2 ? activeTitleColor : inactiveTextColor,
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
                color:
                    _currentIndex == 3 ? activeTitleColor : inactiveTextColor,
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

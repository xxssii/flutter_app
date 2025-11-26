// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'dart:io' show Platform;

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// BLE, 알림, 시간대
import 'services/ble_service.dart';
import 'services/notification_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 상태 관리 및 유틸리티
import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'state/sleep_data_state.dart';
import 'state/profile_state.dart';
import 'providers/sleep_provider.dart'; // ✅ 백엔드 리포트 연동
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';

// 화면 (별칭 사용)
import 'screens/home_screen.dart';
import 'screens/data_screen.dart' as data_screen;
import 'screens/pillow_screen.dart';
import 'screens/settings_screen.dart' as screen;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Firestore 오프라인 데이터 지원 활성화
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    // cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // 필요시 설정
  );

  // 3. 알림 및 시간대 초기화
  await _configureLocalTimeZone();
  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        // 독립적인 Provider들
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => SleepDataState()),
        ChangeNotifierProvider(create: (_) => ProfileState()),
        ChangeNotifierProvider(
          create: (_) => SleepProvider(),
        ), // ✅ SleepProvider 등록
        // 다른 Provider에 의존하는 ProxyProvider
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

// 로컬 시간대 설정 함수
Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
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
    // SettingsState의 다크모드 설정에 따라 테마를 변경하기 위해 Consumer 사용
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return MaterialApp(
          title: '스마트 수면 케어',
          debugShowCheckedModeBanner: false,

          // === 라이트 모드 테마 설정 ===
          theme: ThemeData(
            brightness: Brightness.light,
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
            // ✅ CardThemeData -> CardTheme으로 수정
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
          ),

          // === 다크 모드 테마 설정 ===
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
            // ✅ CardThemeData -> CardTheme으로 수정
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

          // 테마 모드 적용 (시스템/라이트/다크)
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

  // 하단 내비게이션바에 연결될 화면들
  final List<Widget> _screens = [
    const HomeScreen(key: Key('homeScreen')),
    const data_screen.DataScreen(key: Key('dataScreen')), // 별칭 사용
    const PillowScreen(key: Key('pillowScreen')),
    const screen.SettingsScreen(key: Key('settingsScreen')), // 별칭 사용
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = isDarkMode
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final Color activeTitleColor = isDarkMode
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavyBar(
        selectedIndex: _currentIndex,
        showElevation: true,
        itemCornerRadius: 24,
        curve: Curves.easeIn,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).cardTheme.color,
        items: [
          BottomNavyBarItem(
            icon: const Icon(Icons.home),
            title: Text(
              'Main',
              style: TextStyle(
                color: _currentIndex == 0 ? activeTitleColor : inactiveColor,
              ),
            ),
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.analytics),
            title: Text(
              'Sleep Report',
              style: TextStyle(
                color: _currentIndex == 1 ? activeTitleColor : inactiveColor,
              ),
            ),
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.bed),
            title: Text(
              'Pillow Control',
              style: TextStyle(
                color: _currentIndex == 2 ? activeTitleColor : inactiveColor,
              ),
            ),
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: const Icon(Icons.settings),
            title: Text(
              'Settings',
              style: TextStyle(
                color: _currentIndex == 3 ? activeTitleColor : inactiveColor,
              ),
            ),
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

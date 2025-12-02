// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'package:flutter_spinkit/flutter_spinkit.dart'; // 로딩 스피너 추가

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
//test_code
// import 'screens/hardware_test_screen.dart'; // (필요하면 주석 해제)
// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// BLE
import 'services/ble_service.dart';

// ✅ 실제 FCM 알림 서비스
import 'services/notification_service.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart'; // ✅ 패키지 임포트

// 비동기 앱 초기화 로직을 수행할 함수
Future<void> _performAppInitialization(BuildContext context) async {
  // 1. Firebase 초기화 (main 함수에서 이미 했지만, 혹시 모를 경우를 대비한 패턴)
  // WidgetsFlutterBinding.ensureInitialized()는 main에서 이미 호출됨
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   debugPrint('✅ Firebase 초기화 성공! (AnimatedSplashScreen 내)');
  // } catch (e) {
  //   debugPrint('⚠️ Firebase 초기화 경고: $e (AnimatedSplashScreen 내)');
  // }

  // 2. 사용자 ID 로드 (main 함수에서 이미 했지만, 여기서도 필요하다면)
  String userId = 'demoUser';
  try {
    userId = await UserIdHelper.getUserId();
    debugPrint('✅ 사용자 ID: $userId (AnimatedSplashScreen 내)');
  } catch (e) {
    debugPrint('⚠️ 사용자 ID 생성 실패, demoUser 사용: $e (AnimatedSplashScreen 내)');
  }

  // 3. FCM 알림 서비스 초기화 (main 함수에서 이미 했지만, 여기서도 필요하다면)
  try {
    await NotificationService.instance.init(
      userId: userId,
    );
    debugPrint('✅ 알림 서비스 초기화 완료! (AnimatedSplashScreen 내)');
  } catch (e) {
    debugPrint('⚠️ 알림 서비스 초기화 실패: $e (AnimatedSplashScreen 내)');
  }

  // TODO: 여기에 앱 시작 시 필요한 추가 데이터 로딩 또는 초기화 로직을 추가합니다.
  // 예: 사용자 설정 불러오기, 초기 데이터베이스 쿼리 등
  // await Future.delayed(const Duration(seconds: 2)); // 데이터 로딩을 시뮬레이션
  debugPrint('✅ 앱 초기화 작업 완료!');
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding); // ✅ 스플래시 화면 유지

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
          home: const AnimatedSplashScreen(), // 첫 화면을 AnimatedSplashScreen으로 설정
        );
      },
    );
  }
}

// ✅ 추가된 AnimatedSplashScreen 위젯
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  // 앱 초기화 상태를 추적하는 Future
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _performAppInitialization(context);
    // ✅ 화면이 빌드된 후 네이티브 스플래시를 즉시 제거하여 로딩 화면(AnimatedSplashScreen)이 보이게 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부에 따라 배경색과 스피너 색상 결정
    // Native Splash와 색상을 일치시켜 자연스러운 전환 유도 (#1A237E)
    final backgroundColor = const Color(0xFF1A237E);
    final spinnerColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand, // ✅ 스택을 화면 전체로 확장
        children: [
          // 1. 배경 이미지 (전체 화면)
          Image.asset(
            'assets/logo.png',
            fit: BoxFit.cover, // ✅ 화면을 꽉 채우도록 설정
          ),
          
          // 2. 로딩 스피너 및 텍스트 (위에 겹쳐서 표시)
          FutureBuilder(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainWrapper()),
                  );
                });
                return Container();
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 200), // 로고 가리지 않게 약간 아래로 내림 (조절 가능)
                      SpinKitRing(
                        color: spinnerColor,
                        size: 50.0,
                        lineWidth: 3.0,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '앱 초기화 중...',
                        style: AppTextStyles.bodyText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: const Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
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

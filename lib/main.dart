// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/data_screen.dart';
import 'screens/pillow_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'package:flutter_app/state/sleep_data_state.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
        ChangeNotifierProvider(create: (_) => SleepDataState()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settingsState, child) {
        return MaterialApp(
          title: '스마트 수면 케어',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: AppColors.background,
            cardColor: AppColors.cardBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.background,
              elevation: 0,
              titleTextStyle: AppTextStyles.appBarTitle,
              iconTheme: IconThemeData(color: AppColors.primaryText),
            ),
            textTheme: TextTheme(
              bodyLarge: AppTextStyles.bodyText,
              bodyMedium: AppTextStyles.bodyText,
              titleLarge: AppTextStyles.heading1,
              titleMedium: AppTextStyles.heading2,
              titleSmall: AppTextStyles.heading3,
            ),
            cardTheme: CardThemeData(
              color: AppColors.cardBackground,
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.borderColor, width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: AppTextStyles.buttonText,
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: AppColors.darkBackground,
            cardColor: AppColors.darkCardBackground,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.darkBackground,
              elevation: 0,
              titleTextStyle: AppTextStyles.darkAppBarTitle,
              iconTheme: IconThemeData(color: AppColors.darkPrimaryText),
            ),
            textTheme: TextTheme(
              bodyLarge: AppTextStyles.darkBodyText,
              bodyMedium: AppTextStyles.darkBodyText,
              titleLarge: AppTextStyles.darkHeading1,
              titleMedium: AppTextStyles.darkHeading2,
              titleSmall: AppTextStyles.darkHeading3,
            ),
            cardTheme: CardThemeData(
              color: AppColors.darkCardBackground,
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.darkBorderColor, width: 1),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: AppTextStyles.darkButtonText,
              ),
            ),
          ),
          themeMode: settingsState.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: MainWrapper(),
        );
      },
    );
  }
}

class MainWrapper extends StatefulWidget {
  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    DataScreen(),
    PillowScreen(),
    SettingsScreen(),
  ];

  // PNG 파일 경로 리스트
  final List<String> _unselectedIcons = const [
    'assets/main_moon.png', // Main (메인화면)
    'assets/constellation.png', // Sleep Report (수면 데이터)
    'assets/cloud.png', // Pillow Control (베개 케어)
    'assets/setting_moon.png', // Settings (설정)
  ];

  final List<String> _selectedIcons = const [
    'assets/main_moon.png', // Main
    'assets/constellation.png', // Sleep Report
    'assets/cloud.png', // Pillow Control
    'assets/setting_moon.png', // Settings
  ];

  final List<String> _labels = const [
    'Main',
    'Sleep Report',
    'Pillow Control',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: List.generate(_labels.length, (index) {
            final isSelected = _selectedIndex == index;
            final iconPath = isSelected
                ? _selectedIcons[index]
                : _unselectedIcons[index];

            return BottomNavigationBarItem(
              icon: Image.asset(
                iconPath,
                width: 70, // 아이콘 크기를 50x50으로 변경
                height: 70,
              ),
              label: _labels[index],
            );
          }),
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.secondaryText,
          backgroundColor: Theme.of(context).cardColor,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: AppTextStyles.bottomNavItemLabel,
          unselectedLabelStyle: AppTextStyles.bottomNavItemLabel,
        ),
      ),
    );
  }
}

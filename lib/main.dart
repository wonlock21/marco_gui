import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'gamepage.dart';
import 'services/connection_controller.dart';
import 'services/mission_controller.dart';
import 'services/telemetry_controller.dart';
import 'theme/agv_colors.dart';
import 'theme/agv_typography.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectionController.instance.init();
  TelemetryController.instance.init();
  MissionController.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(844, 390),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lift Ant Controller',
          theme: _buildTheme(),
          home: const GamePage(),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AgvColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AgvColors.accent,
        secondary: AgvColors.info,
        surface: AgvColors.surface,
        error: AgvColors.danger,
        onPrimary: AgvColors.background,
        onSecondary: AgvColors.textPrimary,
        onSurface: AgvColors.textPrimary,
        onError: AgvColors.textPrimary,
      ),
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: AgvColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AgvColors.textPrimary),
        titleTextStyle: AgvTypography.technical(
          size: 20,
          weight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AgvColors.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AgvColors.surfaceElevated,
        contentTextStyle: AgvTypography.body(
          color: AgvColors.textPrimary,
          weight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AgvColors.borderSubtle),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AgvColors.surfaceElevated,
        foregroundColor: AgvColors.textPrimary,
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AgvColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AgvColors.borderSubtle),
        ),
        titleTextStyle: AgvTypography.technical(
          size: 18,
          weight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AgvColors.textPrimary,
        ),
        contentTextStyle: AgvTypography.body(
          size: 14,
          color: AgvColors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AgvColors.accent
              : AgvColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AgvColors.accent.withValues(alpha: 0.4)
              : AgvColors.surfaceOverlay,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AgvColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AgvColors.textPrimary),
    );

    return base;
  }
}

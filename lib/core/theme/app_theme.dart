import 'package:flutter/material.dart';

import 'package:urbanogo/core/theme/app_colors.dart';

ThemeData appTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.ink,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: 'Roboto',
    splashColor: AppColors.sol.withValues(alpha: 0.12),
    highlightColor: AppColors.sol.withValues(alpha: 0.08),

    colorScheme: const ColorScheme.dark(
      primary: AppColors.cloud,
      onPrimary: AppColors.ink,
      secondary: AppColors.sol,
      onSecondary: AppColors.ink,
      surface: AppColors.slate,
      onSurface: AppColors.cloud,
      error: AppColors.danger,
      outline: AppColors.line,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.cloud),
      displayMedium: TextStyle(color: AppColors.cloud),
      displaySmall: TextStyle(color: AppColors.cloud),
      headlineLarge: TextStyle(color: AppColors.cloud, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: AppColors.cloud, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: AppColors.cloud, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: AppColors.cloud, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.cloud, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: AppColors.cloud),
      bodyMedium: TextStyle(color: AppColors.cloud),
      bodySmall: TextStyle(color: AppColors.mist),
      labelLarge: TextStyle(color: AppColors.cloud, fontWeight: FontWeight.w600),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.slate,
      labelStyle: const TextStyle(color: AppColors.mist),
      hintStyle: const TextStyle(color: AppColors.mist),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.sol),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cloud,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.mist,
        elevation: 0,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cloud,
        side: const BorderSide(color: AppColors.line),
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.mist),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.slate,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.slate,
      contentTextStyle: TextStyle(color: AppColors.cloud),
      actionTextColor: AppColors.sol,
      behavior: SnackBarBehavior.floating,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.sol,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.errorRed,
    ),

    // All text uses Inter/Barlow via AppTextStyles —
    // this just sets the base fallback
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: AppColors.textPrimary),

    // Dividers
    dividerColor: AppColors.border,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: InputBorder.none,
      hintStyle: TextStyle(color: AppColors.white38),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // Bottom sheets
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.errorRed.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.errorRed.withOpacity(0.5)),
      ),
    ),
  );
}

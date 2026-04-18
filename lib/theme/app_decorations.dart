import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  AppDecorations._();

  // Standard dark card
  static BoxDecoration card({
    double radius = 16,
    Color? borderColor,
  }) => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? AppColors.border),
  );

  // Surface card (slightly lighter)
  static BoxDecoration surface({double radius = 16}) => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.borderAlt),
  );

  // Glowing purple button
  static BoxDecoration accentButton({bool active = true}) => BoxDecoration(
    color: active ? AppColors.purple : AppColors.purpleDim.withOpacity(0.5),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: active ? AppColors.purple.withOpacity(0.8) : AppColors.border,
    ),
    boxShadow: active
        ? [BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 20)]
        : [],
  );

  // Input field container
  static BoxDecoration inputField({double radius = 10}) => BoxDecoration(
    color: AppColors.inputBg,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border),
  );

  // Active pill
  static BoxDecoration pillActive = BoxDecoration(
    color: AppColors.purple.withOpacity(0.25),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.purple, width: 1.5),
  );

  // Inactive pill
  static BoxDecoration pillInactive = BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border),
  );
}
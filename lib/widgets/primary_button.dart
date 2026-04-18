import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent.withOpacity(0.18),
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
}
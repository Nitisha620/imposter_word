import 'package:flutter/material.dart';
import 'package:word_imposter/theme/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final String label;
  final bool isImposter;
  const RoleBadge({required this.label, required this.isImposter});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: (isImposter ? AppColors.red : AppColors.accent).withOpacity(0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: (isImposter ? AppColors.red : AppColors.accent).withOpacity(
          0.35,
        ),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: isImposter ? AppColors.red : AppColors.accent,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );
}

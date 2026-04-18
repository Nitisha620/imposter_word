import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_imposter/theme/app_colors.dart';

class ErrorBox extends StatelessWidget {
  final String error;
  const ErrorBox({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.errorRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.inter(color: AppColors.errorRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

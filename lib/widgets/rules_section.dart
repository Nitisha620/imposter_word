import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rule.dart';
import '../theme/app_colors.dart';

class RuleSection extends StatelessWidget {
  final String label;
  final List<Rule> rules;

  const RuleSection({required this.label, required this.rules});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.barlow(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.white38,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...rules.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: GoogleFonts.barlow(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.desc,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

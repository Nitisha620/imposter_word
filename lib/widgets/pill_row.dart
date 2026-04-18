import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pill_item.dart';
import '../theme/app_colors.dart';

class PillRow extends StatelessWidget {
  final List<PillItem> items;
  final String selected;
  final bool enabled;
  final void Function(String) onTap;

  const PillRow({
    required this.items,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Pill(
          label: item.label,
          active: selected == item.value,
          enabled: enabled,
          onTap: () => onTap(item.value),
        );
      }).toList(),
    );
  }
}

/// Single pill button.
class Pill extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const Pill({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.purple.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.purple : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.barlow(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active
                ? Colors.white
                : enabled
                ? AppColors.white70
                : AppColors.white38,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

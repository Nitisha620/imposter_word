import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _purple = Color(0xFF7C6EF5);

class ActionButton extends StatelessWidget {
  final String label;
  final IconData suffix;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.suffix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _purple,
              letterSpacing: 0.8,
            ),
          ),
          Icon(suffix, color: _purple, ),
        ],
      ),
    );
  }
}

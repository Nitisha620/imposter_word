import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _purple = Color(0xFF7C6EF5);

class ActionButton extends StatelessWidget {
  final String label;
  final String suffix;
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label  $suffix',
            style: GoogleFonts.barlow(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _purple,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

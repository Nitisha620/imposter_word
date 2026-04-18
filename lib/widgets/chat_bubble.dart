import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Color color;

  const ChatBubble({
    required this.text,
    required this.isMe,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.purple.withOpacity(0.22)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 2),
          bottomRight: Radius.circular(isMe ? 2 : 12),
        ),
        border: Border.all(
          color: isMe ? AppColors.purple.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_imposter/theme/app_colors.dart';

import '../state/player_info.dart';

class KickBottomSheet extends StatelessWidget {
  final PlayerInfo player;
  final Color avatarColor;
  final VoidCallback onKick;
  final VoidCallback onCancel;

  const KickBottomSheet({
    required this.player,
    required this.avatarColor,
    required this.onKick,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131929),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Player info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: GoogleFonts.barlow(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: GoogleFonts.barlow(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Active player',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.white38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),

          // Kick option
          ListTile(
            onTap: onKick,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_remove_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            title: Text(
              'Remove from room',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            subtitle: Text(
              'They will be sent back to the home screen',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.white38),
            ),
          ),

          // Cancel option
          ListTile(
            onTap: onCancel,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white12,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.white70,
                size: 20,
              ),
            ),
            title: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white70,
              ),
            ),
          ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

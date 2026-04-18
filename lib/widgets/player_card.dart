import 'package:flutter/material.dart';

import '../state/player_info.dart';
import '../theme/app_colors.dart';

class PlayerCard extends StatelessWidget {
  final PlayerInfo player;
  final bool isMe, isHost, isReady;
  final Color avatarColor;
  const PlayerCard({
    required this.player,
    required this.isMe,
    required this.isHost,
    required this.isReady,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isMe
          ? AppColors.accentSoft.withOpacity(0.12)
          : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isMe ? AppColors.accent.withOpacity(0.4) : AppColors.border,
        width: 1.2,
      ),
    ),
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    child: Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor,
                ),
                child: Center(
                  child: Text(
                    player.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                isMe ? '${player.name} (You)' : player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              // Status chip
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReady ? AppColors.green : AppColors.amber,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isReady ? 'READY' : 'WAITING...',
                    style: TextStyle(
                      color: isReady ? AppColors.green : AppColors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // HOST badge
          if (isHost)
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
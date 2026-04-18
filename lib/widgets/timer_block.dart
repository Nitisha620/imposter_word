import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TimerBlock extends StatelessWidget {
  final int timeLeft;
  final bool urgent;
  const TimerBlock({required this.timeLeft, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final mins = timeLeft ~/ 60;
    final secs = timeLeft % 60;
    final color = urgent ? AppColors.red : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "$mins:${secs.toString().padLeft(2, '0')}",
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            urgent ? '⚡ SOON' : 'LEFT',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class AvatarCircle extends StatelessWidget {
  final String name;
  final Color color;
  final bool isEliminated;
  const AvatarCircle({
    required this.name,
    required this.color,
    required this.isEliminated,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isEliminated ? color.withOpacity(0.3) : color,
    ),
    child: Center(
      child: Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: isEliminated ? Colors.white.withOpacity(0.4) : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
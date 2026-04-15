import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameLoader extends StatefulWidget {
  final String message;
  const GameLoader({super.key, this.message = 'Loading…'});

  @override
  State<GameLoader> createState() => _GameLoaderState();
}

class _GameLoaderState extends State<GameLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _bars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Each bar is staggered by 150ms
    _bars = List.generate(4, (i) {
      final start = (i * 0.15).clamp(0.0, 1.0);
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F1A).withOpacity(0.75), // transparent overlay
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Bars ──────────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(4, (i) {
                  return AnimatedBuilder(
                    animation: _bars[i],
                    builder: (_, __) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 5,
                      height: 28 * _bars[i].value,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF7C6EF5,
                        ).withOpacity(_bars[i].value),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),
            // ── Label ─────────────────────────────────────────────────────
            Text(
              widget.message.toUpperCase(),
              style: GoogleFonts.barlow(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

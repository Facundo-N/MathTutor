import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedAurora extends StatefulWidget {
  final bool isDarkMode;
  final Widget child;

  const AnimatedAurora({
    super.key,
    required this.isDarkMode,
    required this.child,
  });

  @override
  State<AnimatedAurora> createState() => _AnimatedAuroraState();
}

class _AnimatedAuroraState extends State<AnimatedAurora>
    with SingleTickerProviderStateMixin {
  late AnimationController _auroraCtrl;

  @override
  void initState() {
    super.initState();
    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _auroraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _auroraCtrl,
      builder: (ctx, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _AuroraPainter(
                  t: _auroraCtrl.value,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t; // Animation tick 0..1 looping
  final bool isDarkMode;

  _AuroraPainter({required this.t, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Three orbs that move in slow lissajous-like paths
    final orbs = [
      _OrbConfig(
        baseX: 0.1,
        baseY: 0.05,
        ampX: 0.25,
        ampY: 0.18,
        freqX: 1.0,
        freqY: 0.7,
        radius: size.shortestSide * 0.65,
        darkColor: const Color(0x5E2563EB),
        lightColor: const Color(0x7793C5FD),
      ),
      _OrbConfig(
        baseX: 0.85,
        baseY: 0.55,
        ampX: 0.22,
        ampY: 0.20,
        freqX: 0.6,
        freqY: 1.1,
        radius: size.shortestSide * 0.55,
        darkColor: const Color(0x440EA5E9),
        lightColor: const Color(0x6638BDF8),
      ),
      _OrbConfig(
        baseX: 0.15,
        baseY: 0.88,
        ampX: 0.20,
        ampY: 0.15,
        freqX: 0.8,
        freqY: 0.5,
        radius: size.shortestSide * 0.70,
        darkColor: const Color(0x333B82F6),
        lightColor: const Color(0x5560A5FA),
      ),
    ];

    for (final orb in orbs) {
      final cx =
          size.width *
          (orb.baseX + orb.ampX * math.sin(2 * math.pi * t * orb.freqX));
      final cy =
          size.height *
          (orb.baseY + orb.ampY * math.cos(2 * math.pi * t * orb.freqY));
      final color = isDarkMode ? orb.darkColor : orb.lightColor;

      final paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80)
        ..color = color;
      canvas.drawCircle(Offset(cx, cy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.isDarkMode != isDarkMode;
}

class _OrbConfig {
  final double baseX, baseY, ampX, ampY, freqX, freqY, radius;
  final Color darkColor, lightColor;
  const _OrbConfig({
    required this.baseX,
    required this.baseY,
    required this.ampX,
    required this.ampY,
    required this.freqX,
    required this.freqY,
    required this.radius,
    required this.darkColor,
    required this.lightColor,
  });
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedBunny extends StatefulWidget {
  final double width;
  final double height;
  final bool isSpeaking;

  const AnimatedBunny({
    super.key,
    this.width = 350,
    this.height = 350,
    this.isSpeaking = false,
  });

  @override
  State<AnimatedBunny> createState() => AnimatedBunnyState();
}

class AnimatedBunnyState extends State<AnimatedBunny>
    with TickerProviderStateMixin {
  int _eyeIndex = 1;
  int _mouthIndex = 1;
  Timer? _blinkTimer;
  Timer? _talkTimer;

  late AnimationController _armController;
  late AnimationController _flipController;
  bool _isGreeting = false;
  bool _isFlipping = false;

  // Canvas original del PSD (2000x1116)
  static const double _svgW = 2000;
  static const double _svgH = 1116;

  // Posición exacta del birrete extraída de bunny_combined.svg:
  // Capa 23: transform(838, 300) + Carpeta-1 offset (17, 31.5)
  static const double _gorraL = 750;
  static const double _gorraT = 217;
  static const double _gorraW = 460;
  static const double _gorraH = 223;

  void greet() {
    setState(() {
      _eyeIndex = 3;
      _isGreeting = true;
    });
    _armController.forward(from: 0).then((_) {
      _armController.reverse().then((_) {
        _armController.forward().then((_) {
          _armController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _eyeIndex = 1;
                _isGreeting = false;
              });
            }
          });
        });
      });
    });
  }

  /// Efecto varita mágica: giro 3D en Y
  void doMagicFlip() {
    if (_isFlipping) return;
    setState(() => _isFlipping = true);
    _flipController.forward(from: 0).then((_) {
      if (mounted) setState(() => _isFlipping = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _startBlinkCycle();
    if (widget.isSpeaking) _startTalkCycle();
  }

  @override
  void didUpdateWidget(AnimatedBunny oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _startTalkCycle();
      } else {
        _talkTimer?.cancel();
        setState(() => _mouthIndex = 1);
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _talkTimer?.cancel();
    _armController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _startBlinkCycle() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(
      Duration(milliseconds: 2000 + Random().nextInt(3000)),
      () async {
        if (!mounted) return;
        setState(() => _eyeIndex = 2);
        await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        setState(() => _eyeIndex = 1);
        _startBlinkCycle();
      },
    );
  }

  void _startTalkCycle() {
    _talkTimer?.cancel();
    _talkTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      setState(() => _mouthIndex = _mouthIndex == 1 ? 2 : 1);
    });
  }

  /// Loads an SVG layer from the bunny_svg assets folder.
  /// All SVGs share the same 2000×1116 viewBox so Positioned.fill aligns correctly.
  Widget _svgLayer(String name) {
    return SvgPicture.asset(
      'assets/images/bunny_svg/$name.svg',
      width: _svgW,
      height: _svgH,
      fit: BoxFit.fill,
      placeholderBuilder: (context) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bunnyWidget = SizedBox(
          width: widget.width,
          height: widget.height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _svgW,
              height: _svgH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _svgLayer('oreja izquierda')),
                  Positioned.fill(child: _svgLayer('oreja derecha')),
                  Positioned.fill(child: _svgLayer('pie izquierdo')),
                  Positioned.fill(child: _svgLayer('pie derecho')),
                  Positioned.fill(child: _svgLayer('brazo derecho')),
                  Positioned.fill(child: _svgLayer('torso')),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _armController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _isGreeting ? -0.35 * _armController.value : 0,
                          alignment: const Alignment(-0.25, 0.42),
                          child: child,
                        );
                      },
                      child: _svgLayer('brazo izquierdo'),
                    ),
                  ),
                  Positioned.fill(child: _svgLayer('cabeza')),
                  Positioned.fill(child: _svgLayer('ojos $_eyeIndex')),
                  Positioned.fill(child: _svgLayer('boca $_mouthIndex')),
                  Positioned.fill(child: _svgLayer('anteojos')),
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(0, -28),
                      child: _svgLayer('colgante gorra 1'),
                    ),
                  ),
                  Positioned(
                    left: _gorraL,
                    top: _gorraT,
                    width: _gorraW,
                    height: _gorraH,
                    child: Image.asset(
                      'assets/images/bunny_svg/gorra.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -10, duration: 2500.ms, curve: Curves.easeInOut);

    if (!_isFlipping) return bunnyWidget;

    // Aplica perspectiva 3D en Y mientras se hace el flip
    return AnimatedBuilder(
      animation: _flipController,
      builder: (context, child) {
        final angle = _flipController.value * 2 * 3.14159; // 0 → 2π
        final scale = 1.0 + 0.2 * (1 - ((_flipController.value - 0.5).abs() * 2));
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspectiva
            ..rotateY(angle)
            ..scale(scale),
          child: child,
        );
      },
      child: bunnyWidget,
    );
  }
}

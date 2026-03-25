import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicLoadingScreen extends StatefulWidget {
  final String topicId;
  final VoidCallback onComplete;

  const TopicLoadingScreen({
    super.key,
    required this.topicId,
    required this.onComplete,
  });

  @override
  State<TopicLoadingScreen> createState() => _TopicLoadingScreenState();
}

class _TopicLoadingScreenState extends State<TopicLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progressAnim;

  static const _kDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _kDuration)..forward();

    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _topicName => switch (widget.topicId) {
        'linear' => 'Ecuaciones Lineales',
        'distributive' => 'Propiedad Distributiva',
        'factorization' => 'Factorización',
        'quadratic' => 'Ecuaciones Cuadráticas',
        'cubic' => 'Ecuaciones Cúbicas',
        _ => 'Matemáticas',
      };

  String get _topicIcon => switch (widget.topicId) {
        'linear' => 'x',
        'distributive' => 'a(b+c)',
        'factorization' => '(x-a)(x-b)',
        'quadratic' => 'x²',
        'cubic' => 'x³',
        _ => '∞',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Ícono del tema (Estático) ────────────────────────────────────
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withAlpha(120),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _topicIcon,
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 44),

              // ── Textos ────────────────────────────────────────────────────
              Text(
                'Preparando tu aventura de',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  color: Colors.blueGrey[300],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _topicName,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ── Barra de progreso animada ─────────────────────────────────
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: _progressAnim.value,
                        minHeight: 6,
                        backgroundColor: Colors.white.withAlpha(20),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF38BDF8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Puntos animados
                    _DotIndicator(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatefulWidget {
  @override
  State<_DotIndicator> createState() => _DotIndicatorState();
}

class _DotIndicatorState extends State<_DotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _dotCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
          ..repeat();
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCtrl,
      builder: (context, child) {
        int dotCount = ((_dotCtrl.value * 3) % 4).floor();
        String dots = '.' * dotCount;
        return Text(
          'Seleccionando el mejor ejercicio para ti$dots',
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: const Color(0xFF38BDF8),
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}

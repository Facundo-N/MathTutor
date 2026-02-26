import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/math_engine_service.dart';

/// Widget con animación de escritura progresiva para soluciones matemáticas
class MathSolutionWidget extends StatefulWidget {
  final MathSolution solution;

  const MathSolutionWidget({super.key, required this.solution});

  @override
  State<MathSolutionWidget> createState() => _MathSolutionWidgetState();
}

class _MathSolutionWidgetState extends State<MathSolutionWidget> {
  int _currentStep = 0;
  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();
    _animateSteps();
  }

  void _animateSteps() async {
    setState(() => _isAnimating = true);

    for (int i = 0; i < widget.solution.steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _currentStep = i);
    }

    setState(() => _isAnimating = false);
  }

  void _skipAnimation() {
    setState(() {
      _currentStep = widget.solution.steps.length - 1;
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solución paso a paso',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      widget.solution.expression,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAnimating)
                TextButton.icon(
                  onPressed: _skipAnimation,
                  icon: const Icon(Icons.fast_forward, size: 16),
                  label: const Text('Saltar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Pasos animados
          ...List.generate(_currentStep + 1, (index) {
            final step = widget.solution.steps[index];
            final isLast = index == widget.solution.steps.length - 1;
            final isVisible = index <= _currentStep;

            return AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: _buildAnimatedStep(step, isLast, index),
            );
          }),

          // Indicador de progreso
          if (_isAnimating &&
              _currentStep < widget.solution.steps.length - 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blue[600]),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Calculando siguiente paso...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedStep(MathStep step, bool isLast, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número de paso
          Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLast
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isLast ? Colors.green : Colors.blue).withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: isLast
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '${step.stepNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              )
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(
                duration: 600.ms,
                color: Colors.white.withValues(alpha: 0.5),
              ),

          const SizedBox(width: 16),

          // Contenido del paso
          Expanded(
            child:
                Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLast ? Colors.green[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLast
                              ? Colors.green[300]!
                              : Colors.blue[200]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Expresión matemática con efecto typewriter
                          _TypewriterText(
                            text: step.expression,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: isLast
                                  ? Colors.green[900]
                                  : Colors.blue[900],
                            ),
                            duration: const Duration(milliseconds: 800),
                          ),

                          const SizedBox(height: 8),

                          // Explicación con efecto typewriter
                          _TypewriterText(
                            text: step.explanation,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.2, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}

/// Widget de texto con efecto de escritura (typewriter)
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;

  const _TypewriterText({
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.delay = Duration.zero,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _charCount = StepTween(
      begin: 0,
      end: widget.text.length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, child) {
        final text = widget.text.substring(0, _charCount.value);
        return Text(text, style: widget.style);
      },
    );
  }
}

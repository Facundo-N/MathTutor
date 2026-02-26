import 'package:flutter/material.dart';
import '../services/math_engine_service.dart';
import '../widgets/equation_graph_widget.dart';

/// Widget que muestra la solución escribiéndose en tiempo real (efecto typewriter)
class MathSolutionWidget extends StatefulWidget {
  final MathSolution solution;

  const MathSolutionWidget({super.key, required this.solution});

  @override
  State<MathSolutionWidget> createState() => _MathSolutionWidgetState();
}

class _MathSolutionWidgetState extends State<MathSolutionWidget> {
  String _displayedText = '';
  bool _isTyping = false;
  bool _shouldStop = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _shouldStop = true;
    super.dispose();
  }

  void _startTyping() async {
    if (_shouldStop || !mounted) return;

    setState(() => _isTyping = true);

    // Escribir cada paso
    for (
      int stepIndex = 0;
      stepIndex < widget.solution.steps.length;
      stepIndex++
    ) {
      if (_shouldStop || !mounted) return;

      final step = widget.solution.steps[stepIndex];

      // Título del paso
      final stepTitle = '\n\nPaso ${step.stepNumber}: ';
      await _typeText(stepTitle, speed: 30);
      if (_shouldStop || !mounted) return;

      // Expresión matemática
      await _typeText('${step.expression}\n', speed: 40);
      if (_shouldStop || !mounted) return;

      // Explicación
      await _typeText(step.explanation, speed: 25);
      if (_shouldStop || !mounted) return;

      // Pausa entre pasos
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (_shouldStop || !mounted) return;

    // Resultado final
    await _typeText('\n\n✅ Solución Final: ', speed: 30);
    if (_shouldStop || !mounted) return;

    await _typeText(widget.solution.solution, speed: 50);
    if (_shouldStop || !mounted) return;

    if (mounted) {
      setState(() => _isTyping = false);
    }
  }

  Future<void> _typeText(String text, {int speed = 30}) async {
    for (int i = 0; i < text.length; i++) {
      if (_shouldStop || !mounted) return;

      if (mounted) {
        setState(() {
          _displayedText += text[i];
        });
      }

      await Future.delayed(Duration(milliseconds: speed));
    }
  }

  void _skipTyping() {
    if (!mounted) return;

    _shouldStop = true;

    final fullText = StringBuffer();

    for (final step in widget.solution.steps) {
      fullText.write('\n\nPaso ${step.stepNumber}: ');
      fullText.write('${step.expression}\n');
      fullText.write(step.explanation);
    }

    fullText.write('\n\n✅ Solución Final: ${widget.solution.solution}');

    if (mounted) {
      setState(() {
        _displayedText = fullText.toString();
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resolviendo...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      widget.solution.expression,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTyping)
                TextButton.icon(
                  onPressed: _skipTyping,
                  icon: const Icon(Icons.fast_forward, size: 18),
                  label: const Text('Saltar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                ),
            ],
          ),

          const Divider(height: 32, thickness: 1),

          // Área de texto con efecto typewriter
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200),
            child: SelectableText(
              _displayedText,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[800],
                fontFamily: 'monospace',
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Cursor parpadeante cuando está escribiendo
          if (_isTyping) ...[const SizedBox(height: 8), _BlinkingCursor()],

          // ✅ DEBUG: Información de gráficos
          Builder(
            builder: (context) {
              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              debugPrint('🔍 DEBUG GRÁFICOS:');
              debugPrint('_isTyping: $_isTyping');
              debugPrint(
                'graphData == null: ${widget.solution.graphData == null}',
              );

              if (widget.solution.graphData != null) {
                debugPrint('✅ graphData existe');
                debugPrint('canGraph: ${widget.solution.graphData!.canGraph}');
                debugPrint('equation: ${widget.solution.graphData!.equation}');
                debugPrint(
                  'xValues.length: ${widget.solution.graphData!.xValues.length}',
                );
                debugPrint(
                  'yValues.length: ${widget.solution.graphData!.yValues.length}',
                );
                if (widget.solution.graphData!.error != null) {
                  debugPrint('❌ error: ${widget.solution.graphData!.error}');
                }
              } else {
                debugPrint('❌ graphData es NULL');
              }
              debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

              return const SizedBox.shrink();
            },
          ),

          // ✅ Botón para ver gráfico
          if (!_isTyping &&
              widget.solution.graphData != null &&
              widget.solution.graphData!.canGraph) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                          maxHeight: 500,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '📊 Gráfico de la Ecuación',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[900],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: EquationGraphWidget(
                                graphData: widget.solution.graphData!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.show_chart, size: 24),
                label: const Text(
                  '📊 ¿Quieres ver el gráfico?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cursor parpadeante para el efecto typewriter
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.blue[700],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

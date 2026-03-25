// lib/widgets/exercise_templates/tap_destroy_template.dart

import 'package:flutter/material.dart';
import '../../models/ai_exercise_model.dart';
import 'dart:math' as math;

class TapDestroyTemplate extends StatefulWidget {
  final AIExercise exercise;
  final bool isDarkMode;
  final Function(bool, String) onSolved;

  const TapDestroyTemplate({
    super.key,
    required this.exercise,
    required this.isDarkMode,
    required this.onSolved,
  });

  @override
  State<TapDestroyTemplate> createState() => _TapDestroyTemplateState();
}

class _TapDestroyTemplateState extends State<TapDestroyTemplate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _positions = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < widget.exercise.pieces.length; i++) {
      _positions.add(
        Offset(
          _random.nextDouble() * 200 - 100,
          _random.nextDouble() * 200 - 100,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.exercise.storyContext,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: List.generate(widget.exercise.pieces.length, (
                    index,
                  ) {
                    final piece = widget.exercise.pieces[index];
                    final baseOffset = _positions[index];

                    // Add some movement
                    final dx =
                        baseOffset.dx +
                        math.sin(_controller.value * 2 * math.pi + index) * 20;
                    final dy =
                        baseOffset.dy +
                        math.cos(_controller.value * 2 * math.pi + index) * 20;

                    return Positioned(
                      left: 150 + dx,
                      top: 130 + dy,
                      child: GestureDetector(
                        onTap: () => widget.onSolved(
                          piece == widget.exercise.correctAnswer,
                          piece == widget.exercise.correctAnswer
                              ? "¡BOOM! Respuesta correcta destruida con éxito."
                              : "¡Ops! Esa no era. Sigue intentando.",
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: piece == widget.exercise.correctAnswer
                                  ? [Colors.orange, Colors.red]
                                  : [Colors.blue, Colors.purple],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (piece == widget.exercise.correctAnswer
                                            ? Colors.orange
                                            : Colors.blue)
                                        .withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              piece,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "¡Toca la burbuja correcta para avanzar!",
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

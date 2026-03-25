// lib/widgets/exercise_templates/drag_drop_template.dart

import 'package:flutter/material.dart';
import '../../models/ai_exercise_model.dart';

class DragDropTemplate extends StatefulWidget {
  final AIExercise exercise;
  final bool isDarkMode;
  final Function(bool, String) onSolved;

  const DragDropTemplate({
    super.key,
    required this.exercise,
    required this.isDarkMode,
    required this.onSolved,
  });

  @override
  State<DragDropTemplate> createState() => _DragDropTemplateState();
}

class _DragDropTemplateState extends State<DragDropTemplate> {
  String? _droppedValue;

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
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sources
              Column(
                children: widget.exercise.pieces.map((piece) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Draggable<String>(
                      data: piece,
                      feedback: Material(
                        type: MaterialType.transparency,
                        child: _buildPiece(piece, isDragging: true),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: _buildPiece(piece),
                      ),
                      child: _buildPiece(piece),
                    ),
                  );
                }).toList(),
              ),

              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.blueAccent,
                size: 32,
              ),

              // Target
              DragTarget<String>(
                onWillAcceptWithDetails: (details) => _droppedValue == null,
                onAcceptWithDetails: (details) {
                  final value = details.data;
                  setState(() => _droppedValue = value);
                  widget.onSolved(
                    value == widget.exercise.correctAnswer,
                    value == widget.exercise.correctAnswer
                        ? "¡Perfecto! El elemento encaja perfectamente."
                        : "Eso no parece ir ahí. Intenta con otro.",
                  );
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: candidateData.isNotEmpty
                            ? Colors.blueAccent
                            : (widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.black26),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: _droppedValue != null
                          ? _buildPiece(_droppedValue!)
                          : Icon(
                              Icons.add_rounded,
                              color: widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.black26,
                              size: 40,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Arrastra el bloque correcto al espacio vacío",
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white60 : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiece(String text, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

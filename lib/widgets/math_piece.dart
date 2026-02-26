import 'package:flutter/material.dart';
import '../models/math_node.dart';

class MathPieceWidget extends StatelessWidget {
  final MathNode node;

  const MathPieceWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    if (node is TermNode) {
      final term = node as TermNode;
      return Draggable<MathNode>(
        data: node,
        feedback: _buildPiece(term, isDragging: true),
        childWhenDragging: Opacity(
          opacity: 0.2, // Fantasma del bloque original
          child: _buildPiece(term),
        ),
        child: _buildPiece(term),
      );
    }
    return const SizedBox(); // Operadores u otros nodos por ahora no arrastrables
  }

  Widget _buildPiece(TermNode term, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: term.sign == '+' ? Colors.blue.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ]
              : [],
          border: Border.all(
            color: term.sign == '+'
                ? Colors.blue.shade400
                : Colors.red.shade400,
            width: 2,
          ),
        ),
        child: Text(
          term.toDisplayString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: term.sign == '+'
                ? Colors.blue.shade900
                : Colors.red.shade900,
          ),
        ),
      ),
    );
  }
}

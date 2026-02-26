import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/math_node.dart';
import '../providers/equation_provider.dart';
import 'math_piece.dart';

class EquationDropZone extends ConsumerWidget {
  final List<MathNode> nodes;
  final TargetSide side;

  const EquationDropZone({super.key, required this.nodes, required this.side});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<MathNode>(
      onAcceptWithDetails: (DragTargetDetails<MathNode> details) {
        final draggedNode = details.data;
        // Lanzamos la acción a la Física Matemática
        ref
            .read(equationProvider.notifier)
            .moveNodeToSide(draggedNode.id, side);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 150, // Temporal, después será responsivo
          height: 100,
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Colors.blue
                  : Colors.grey.shade300,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: nodes.map((n) {
                if (n is TermNode) {
                  return MathPieceWidget(node: n);
                }
                // Si es un operador u otro, se renderiza simple
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    n.type == 'operator' ? (n as OperatorNode).symbol : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

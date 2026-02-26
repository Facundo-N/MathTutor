import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equation_state.dart';
import '../models/math_node.dart';

final equationProvider = NotifierProvider<EquationNotifier, EquationState>(() {
  return EquationNotifier();
});

enum TargetSide { left, right }

class EquationNotifier extends Notifier<EquationState> {
  @override
  EquationState build() {
    return EquationState(
      leftSide: [
        TermNode(id: 't1', coefficient: 2, variable: 'x', sign: '+'),
        TermNode(id: 't2', coefficient: 5, sign: '+'),
      ],
      rightSide: [TermNode(id: 't3', coefficient: 15, sign: '+')],
    );
  }

  void moveNodeToSide(String nodeId, TargetSide toSide) {
    List<MathNode> newLeft = List.from(state.leftSide);
    List<MathNode> newRight = List.from(state.rightSide);

    MathNode? nodeToMove;
    bool wasOnLeft = false;

    // Buscar en la izquierda
    var indexLeft = newLeft.indexWhere((n) => n.id == nodeId);
    if (indexLeft != -1) {
      nodeToMove = newLeft.removeAt(indexLeft);
      wasOnLeft = true;
    } else {
      // Buscar en la derecha
      var indexRight = newRight.indexWhere((n) => n.id == nodeId);
      if (indexRight != -1) {
        nodeToMove = newRight.removeAt(indexRight);
      }
    }

    if (nodeToMove == null) return;

    // Lógica de "Cruzar el igual" -> Invertir signo
    if ((wasOnLeft && toSide == TargetSide.right) ||
        (!wasOnLeft && toSide == TargetSide.left)) {
      if (nodeToMove is TermNode) {
        // Invertimos signo algebraico
        String newSign = nodeToMove.sign == '+' ? '-' : '+';
        nodeToMove = nodeToMove.copyWith(sign: newSign);
      }
    }

    // Agregar al nuevo lado
    if (toSide == TargetSide.left) {
      newLeft.add(nodeToMove);
    } else {
      newRight.add(nodeToMove);
    }

    state = state.copyWith(leftSide: newLeft, rightSide: newRight);
  }

  void mergeNodes(String sourceId, String targetId) {
    // Aquí implementaremos la lógica de chocar bloques:
    // 1. Buscar ambos nodos.
    // 2. Verificar si son "compatibles" (ej: ambos números solos, o ambos con 'x').
    // 3. Crear el nuevo nodo fusionado sumando restando matemáticamente.
    // 4. Actualizar el estado eliminando los viejos y metiendo el nuevo.
    // Por ahora, dejamos el esqueleto para la Fase 1 avanzada.
  }
}

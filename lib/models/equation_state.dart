import 'math_node.dart';

class EquationState {
  final List<MathNode> leftSide;
  final List<MathNode> rightSide;

  EquationState({required this.leftSide, required this.rightSide});

  EquationState copyWith({
    List<MathNode>? leftSide,
    List<MathNode>? rightSide,
  }) {
    return EquationState(
      leftSide: leftSide ?? this.leftSide,
      rightSide: rightSide ?? this.rightSide,
    );
  }

  // Calculate generic logic weight for the left side
  double get leftWeight => _calculateWeight(leftSide);

  // Calculate generic logic weight for the right side
  double get rightWeight => _calculateWeight(rightSide);

  // Helper method to assign a generic physical "weight" to nodes for balance animation
  double _calculateWeight(List<MathNode> nodes) {
    double weight = 0;
    for (var node in nodes) {
      if (node is TermNode) {
        // Variables weigh slightly differently than constants just for physical distinction
        double baseWeight = node.variable != null ? 10.0 : 5.0;
        double modifier = (node.coefficient * baseWeight).abs();
        weight += node.sign == '+' ? modifier : -modifier;
      }
    }
    return weight;
  }

  // Método auxiliar para ayudar a buscar la posición original de un nodo
  bool containsNode(String id) {
    return leftSide.any((n) => n.id == id) || rightSide.any((n) => n.id == id);
  }
}

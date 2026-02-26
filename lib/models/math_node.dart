abstract class MathNode {
  final String id;
  final String type;

  MathNode({required this.id, required this.type});

  MathNode copyWith({String? id});
}

class TermNode extends MathNode {
  final int coefficient;
  final String? variable;
  final String sign;
  final bool isDivisor;

  TermNode({
    required super.id,
    required this.coefficient,
    this.variable,
    this.sign = '+',
    this.isDivisor = false,
  }) : super(type: 'term');

  @override
  TermNode copyWith({
    String? id,
    int? coefficient,
    String? variable,
    String? sign,
    bool? isDivisor,
  }) {
    return TermNode(
      id: id ?? this.id,
      coefficient: coefficient ?? this.coefficient,
      variable: variable ?? this.variable,
      sign: sign ?? this.sign,
      isDivisor: isDivisor ?? this.isDivisor,
    );
  }

  // Helper para mostrarlo como string fácilmente en UI
  String toDisplayString() {
    String displaySign = sign == '+'
        ? ''
        : '-'; // No mostramos el + inicial si no queremos, pero por ahora lo dejamos simple.
    String displayVar = variable ?? '';
    return '$displaySign$coefficient$displayVar';
  }
}

class OperatorNode extends MathNode {
  final String symbol; // '+', '-', '=', '/'

  OperatorNode({required super.id, required this.symbol})
    : super(type: 'operator');

  @override
  OperatorNode copyWith({String? id, String? symbol}) {
    return OperatorNode(id: id ?? this.id, symbol: symbol ?? this.symbol);
  }
}

class MathSolution {
  final String expression;
  final String solution;
  final List<MathStep> steps;
  final List<String> hints;
  final List<String>? latexSteps;
  final Map<String, dynamic>? graphData;

  MathSolution({
    required this.expression,
    required this.solution,
    required this.steps,
    required this.hints,
    this.latexSteps,
    this.graphData,
  });

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    return MathSolution(
      expression: json['expression'] ?? '',
      solution: json['solution'] ?? '',
      steps:
          (json['steps'] as List?)
              ?.map((step) => MathStep.fromJson(step))
              .toList() ??
          [],
      hints: List<String>.from(json['hints'] ?? []),
      latexSteps: json['latex_steps'] != null
          ? List<String>.from(json['latex_steps'])
          : null,
      graphData: json['graph_data'],
    );
  }
}

class MathStep {
  final int stepNumber;
  final String expression;
  final String explanation;
  final String? latex;

  MathStep({
    required this.stepNumber,
    required this.expression,
    required this.explanation,
    this.latex,
  });

  factory MathStep.fromJson(Map<String, dynamic> json) {
    return MathStep(
      stepNumber: json['step_number'] ?? 0,
      expression: json['expression'] ?? '',
      explanation: json['explanation'] ?? '',
      latex: json['latex'],
    );
  }
}

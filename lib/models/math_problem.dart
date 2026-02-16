// lib/models/math_problem.dart

class MathProblem {
  final String expression;
  final List<String> steps;
  final String answer;
  final String topic;

  const MathProblem({
    required this.expression,
    required this.steps,
    required this.answer,
    this.topic = 'general',
  });

  factory MathProblem.fromJson(Map<String, dynamic> json) {
    return MathProblem(
      expression: json['expression'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      answer: json['answer'] ?? '',
      topic: json['topic'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'steps': steps,
      'answer': answer,
      'topic': topic,
    };
  }
}

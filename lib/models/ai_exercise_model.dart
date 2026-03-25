// lib/models/ai_exercise_model.dart

class AIExercise {
  final String
  exerciseType; // drag_drop, tap_destroy, fill_blank, multiple_choice
  final String equation;
  final String storyContext;
  final List<String> pieces;
  final String correctAnswer;
  final String? hint;
  final Map<String, dynamic>? uiConfig; // Configuración extra opcional

  AIExercise({
    required this.exerciseType,
    required this.equation,
    required this.storyContext,
    required this.pieces,
    required this.correctAnswer,
    this.hint,
    this.uiConfig,
  });

  factory AIExercise.fromJson(Map<String, dynamic> json) {
    // Capturar campos extra en uiConfig
    final Map<String, dynamic> extra = {};
    json.forEach((key, value) {
      if (!['exercise_type', 'equation', 'story_context', 'pieces', 'correct_answer', 'hint', 'ui_config'].contains(key)) {
        extra[key] = value;
      }
    });

    return AIExercise(
      exerciseType: json['exercise_type'] ?? 'multiple_choice',
      equation: json['equation'] ?? '',
      storyContext: json['story_context'] ?? '',
      pieces: List<String>.from(json['pieces'] ?? []),
      correctAnswer: json['correct_answer'] ?? '',
      hint: json['hint'],
      uiConfig: json['ui_config'] != null 
          ? {...(json['ui_config'] as Map<String, dynamic>), ...extra}
          : (extra.isNotEmpty ? extra : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_type': exerciseType,
      'equation': equation,
      'story_context': storyContext,
      'pieces': pieces,
      'correct_answer': correctAnswer,
      'hint': hint,
      'ui_config': uiConfig,
    };
  }
}

// lib/models/tutor_action.dart

class TutorAction {
  final String type; // "socratic_question", "guided_example", "subtle_visual_cue"
  final String speech; // Texto que Banny va a decir
  final VisualCue? visualCue;
  final String? followup; // Pregunta de seguimiento
  final String? action; // "change_to_portrait", "highlight_relevant_part"
  final double? intensity; // 0.0-1.0
  final double? struggleprobability; // Probabilidad de confusión

  const TutorAction({
    required this.type,
    required this.speech,
    this.visualCue,
    this.followup,
    this.action,
    this.intensity,
    this.struggleprobability,
  });

  factory TutorAction.fromJson(Map<String, dynamic> json) {
    return TutorAction(
      type: json['type'] ?? 'socratic_question',
      speech: json['speech'] ?? '',
      visualCue: json['visual_cue'] != null 
          ? VisualCue.fromJson(json['visual_cue']) 
          : null,
      followup: json['followup'],
      action: json['action'],
      intensity: json['intensity']?.toDouble(),
      struggleprobability: json['struggle_probability']?.toDouble(),
    );
  }
}

class VisualCue {
  final String type; // "highlight", "step", "animation", "celebration"
  final String timing; // "immediate", "after_pause"
  
  const VisualCue({
    required this.type,
    required this.timing,
  });

  factory VisualCue.fromJson(Map<String, dynamic> json) {
    return VisualCue(
      type: json['type'] ?? 'step',
      timing: json['timing'] ?? 'immediate',
    );
  }
}

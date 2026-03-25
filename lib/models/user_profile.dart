// lib/models/user_profile.dart

class UserProfile {
  final String userId;
  final List<String> selectedContexts;
  final String preferredVisualStyle;
  final String? manualStyleOverride;

  // ⭐ Deep Personalization Axes
  final String learningObjective; // 'aprobar', 'entender', 'rapido'
  final String preferredTone; // 'serio', 'amigable', 'humor', 'sin_historia'
  final String scaffoldingLevel; // 'alto', 'medio', 'bajo'
  final List<String> specificInterests; // ej. ['Queen', 'The Office']
  final String difficultyLevel; // 'bajo', 'medio', 'alto'

  UserProfile({
    required this.userId,
    this.selectedContexts = const [],
    this.preferredVisualStyle = 'balanced',
    this.manualStyleOverride,
    this.learningObjective = 'entender',
    this.preferredTone = 'amigable',
    this.scaffoldingLevel = 'medio',
    this.specificInterests = const [],
    this.difficultyLevel = 'medio',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      selectedContexts: List<String>.from(json['selected_contexts'] ?? []),
      preferredVisualStyle: json['preferred_visual_style'] ?? 'balanced',
      manualStyleOverride: json['manual_style_override'],
      learningObjective: json['learning_objective'] ?? 'entender',
      preferredTone: json['preferred_tone'] ?? 'amigable',
      scaffoldingLevel: json['scaffolding_level'] ?? 'medio',
      specificInterests: List<String>.from(json['specific_interests'] ?? []),
      difficultyLevel: json['difficulty_level'] ?? 'medio',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'selected_contexts': selectedContexts,
      'preferred_visual_style': preferredVisualStyle,
      'manual_style_override': manualStyleOverride,
      'learning_objective': learningObjective,
      'preferred_tone': preferredTone,
      'scaffolding_level': scaffoldingLevel,
      'specific_interests': specificInterests,
      'difficulty_level': difficultyLevel,
    };
  }

  UserProfile copyWith({
    String? userId,
    List<String>? selectedContexts,
    String? preferredVisualStyle,
    String? manualStyleOverride,
    String? learningObjective,
    String? preferredTone,
    String? scaffoldingLevel,
    List<String>? specificInterests,
    String? difficultyLevel,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      selectedContexts: selectedContexts ?? this.selectedContexts,
      preferredVisualStyle: preferredVisualStyle ?? this.preferredVisualStyle,
      manualStyleOverride: manualStyleOverride ?? this.manualStyleOverride,
      learningObjective: learningObjective ?? this.learningObjective,
      preferredTone: preferredTone ?? this.preferredTone,
      scaffoldingLevel: scaffoldingLevel ?? this.scaffoldingLevel,
      specificInterests: specificInterests ?? this.specificInterests,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }
}

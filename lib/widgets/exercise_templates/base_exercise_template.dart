// lib/widgets/exercise_templates/base_exercise_template.dart

import 'package:flutter/material.dart';
import '../../models/ai_exercise_model.dart';

abstract class BaseExerciseTemplate extends StatelessWidget {
  final AIExercise exercise;
  final bool isDarkMode;
  final Function(bool isCorrect, String feedback) onSolved;

  const BaseExerciseTemplate({
    super.key,
    required this.exercise,
    required this.isDarkMode,
    required this.onSolved,
  });

  // Estilo común de glassmorphism para los contenedores de los templates
  BoxDecoration get glassDecoration => BoxDecoration(
    color: isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: isDarkMode
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
    ),
  );
}

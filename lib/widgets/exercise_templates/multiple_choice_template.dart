// lib/widgets/exercise_templates/multiple_choice_template.dart

import 'package:flutter/material.dart';
import 'base_exercise_template.dart';

class MultipleChoiceTemplate extends BaseExerciseTemplate {
  const MultipleChoiceTemplate({
    super.key,
    required super.exercise,
    required super.isDarkMode,
    required super.onSolved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: glassDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            exercise.storyContext,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...exercise.pieces.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => onSolved(
                  option == exercise.correctAnswer,
                  option == exercise.correctAnswer
                      ? "¡Excelente!"
                      : "Casi, intenta de nuevo.",
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

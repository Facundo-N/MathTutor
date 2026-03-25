// lib/widgets/exercise_templates/fill_blank_template.dart

import 'package:flutter/material.dart';
import '../../models/ai_exercise_model.dart';

class FillBlankTemplate extends StatefulWidget {
  final AIExercise exercise;
  final bool isDarkMode;
  final Function(bool, String) onSolved;

  const FillBlankTemplate({
    super.key,
    required this.exercise,
    required this.isDarkMode,
    required this.onSolved,
  });

  @override
  State<FillBlankTemplate> createState() => _FillBlankTemplateState();
}

class _FillBlankTemplateState extends State<FillBlankTemplate> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    // Assuming storyContext has placeholders like [[...]]
    final matches = RegExp(
      r'\[\[(.*?)\]\]',
    ).allMatches(widget.exercise.storyContext);
    for (int i = 0; i < matches.length; i++) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkAnswers() {
    final matches = RegExp(
      r'\[\[(.*?)\]\]',
    ).allMatches(widget.exercise.storyContext).toList();
    bool allCorrect = true;

    for (int i = 0; i < matches.length; i++) {
      final expected = matches[i].group(1)?.trim().toLowerCase();
      final actual = _controllers[i].text.trim().toLowerCase();
      if (actual != expected) {
        allCorrect = false;
        break;
      }
    }

    widget.onSolved(
      allCorrect,
      allCorrect
          ? "¡Lo lograste! Completaste la ecuación correctamente."
          : "Revisa los espacios en blanco, algo no cuadra.",
    );
  }

  @override
  Widget build(BuildContext context) {
    // Split text into parts
    final text = widget.exercise.storyContext;
    final regex = RegExp(r'\[\[.*?\]\]');
    final parts = text.split(regex);

    List<Widget> children = [];
    for (int i = 0; i < parts.length; i++) {
      children.add(
        Text(
          parts[i],
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      );

      if (i < _controllers.length) {
        children.add(
          Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _controllers[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.isDarkMode ? Colors.white30 : Colors.black26,
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.edit_note_rounded,
            color: Colors.blueAccent,
            size: 40,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _checkAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("Verificar Respuesta"),
          ),
        ],
      ),
    );
  }
}

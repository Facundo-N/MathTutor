// lib/models/guided_exercise_model.dart

import 'tutorial_scene_model.dart';

class GuidedBlock {
  final String id;
  final String value;
  final String type;
  final String side;

  GuidedBlock({
    required this.id,
    required this.value,
    required this.type,
    required this.side,
  });

  factory GuidedBlock.fromJson(Map<String, dynamic> json) {
    return GuidedBlock(
      id: json['id'] as String,
      value: json['value'] as String,
      type: json['type'] as String,
      side: json['side'] as String,
    );
  }

  MathBlock toMathBlock() {
    // Normalizar superíndices para renderizado
    final String displayValue = value
        .replaceAll('^2', '²')
        .replaceAll('^3', '³');

    MathBlockType blockType;
    switch (type) {
      case 'operator':
        blockType = MathBlockType.operator;
        break;
      case 'blockDark':
        blockType = MathBlockType.blockDark;
        break;
      case 'blockGreen':
        blockType = MathBlockType.blockGreen;
        break;
      case 'blockGreenGlow':
        blockType = MathBlockType.blockGreenGlow;
        break;
      default:
        blockType = MathBlockType.blockGreen;
    }

    return MathBlock(
      id: id,
      value: displayValue,
      type: blockType,
    );
  }
}

class GuidedStep {
  final String instruction;
  final String ttsText;
  final String? targetBlockId;
  final String? expectedSide;
  final List<GuidedBlock> blocksBefore; // ← NUEVO: estado inicial visible en pantalla
  final List<GuidedBlock> blocksAfter;
  final String successMessage;
  final String errorMessage;
  final BunnyAction bunnyAction;

  GuidedStep({
    required this.instruction,
    required this.ttsText,
    this.targetBlockId,
    this.expectedSide,
    required this.blocksBefore,
    required this.blocksAfter,
    required this.successMessage,
    required this.errorMessage,
    required this.bunnyAction,
  });

  factory GuidedStep.fromJson(Map<String, dynamic> json) {
    BunnyAction action = BunnyAction.startTalking;
    if (json['bunny_action'] != null) {
      final actionStr = json['bunny_action'].toString().toLowerCase();
      if (actionStr == 'celebrate') {
        action = BunnyAction.celebrate;
      } else if (actionStr == 'think' || actionStr == 'explain') {
        action = BunnyAction.startTalking;
      } else if (actionStr == 'flip') {
        action = BunnyAction.magicFlip;
      }
    }

    return GuidedStep(
      instruction: json['instruction'] as String,
      ttsText: json['tts_text'] as String,
      targetBlockId: json['target_block_id'] as String?,
      expectedSide: json['expected_side'] as String?,
      blocksBefore: json['blocks_before'] != null
          ? (json['blocks_before'] as List).map((e) => GuidedBlock.fromJson(e)).toList()
          : [], // Si no viene del backend, lista vacía (usará blocksAfter del paso previo)
      blocksAfter: (json['blocks_after'] as List)
          .map((e) => GuidedBlock.fromJson(e))
          .toList(),
      successMessage: json['success_message'] as String,
      errorMessage: json['error_message'] as String,
      bunnyAction: action,
    );
  }
}

class GuidedExercise {
  final String equation;
  final String answer;
  final List<GuidedStep> steps;

  GuidedExercise({
    required this.equation,
    required this.answer,
    required this.steps,
  });

  factory GuidedExercise.fromJson(Map<String, dynamic> json) {
    return GuidedExercise(
      equation: json['equation'] as String,
      answer: json['answer'] as String,
      steps: (json['steps'] as List)
          .map((e) => GuidedStep.fromJson(e))
          .toList(),
    );
  }
}

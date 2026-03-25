// lib/models/board_state.dart

import 'package:flutter/material.dart';
import 'math_element.dart';

/// Estado completo de la pizarra interactiva
class BoardState {
  // Ecuación original
  String originalEquation; // "2x + 4 = 10"

  // Elementos en cada lado del =
  List<MathElement> leftSide;
  List<MathElement> rightSide;

  // Elemento del signo =
  MathElement? equalsElement;

  // Paso actual en la resolución
  int currentStep;

  // Historial de acciones del usuario
  List<BoardAction> history;

  // Sistema de spotlight (IA coach)
  String? spotlightElementId; // ID del elemento iluminado
  String? hintText; // Pista de Banny

  // Contexto temático (historia)
  String? storyContext;

  // Estado de validación
  bool isCurrentActionValid;
  String? errorMessage;

  BoardState({
    required this.originalEquation,
    required this.leftSide,
    required this.rightSide,
    this.equalsElement,
    this.currentStep = 0,
    List<BoardAction>? history,
    this.spotlightElementId,
    this.hintText,
    this.storyContext,
    this.isCurrentActionValid = true,
    this.errorMessage,
  }) : history = history ?? [];

  /// Obtener todos los elementos (ambos lados + igual)
  List<MathElement> get allElements {
    final all = <MathElement>[...leftSide, ...rightSide];
    if (equalsElement != null) all.add(equalsElement!);
    return all;
  }

  /// Buscar elemento por ID
  MathElement? findElement(String id) {
    try {
      return allElements.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Agregar acción al historial
  void addAction(BoardAction action) {
    history.add(action);
    currentStep++;
  }

  /// Deshacer última acción
  BoardAction? undoLastAction() {
    if (history.isEmpty) return null;
    final action = history.removeLast();
    currentStep--;
    return action;
  }

  /// Verificar si la ecuación está resuelta
  bool get isSolved {
    // Resuelto si solo queda variable = número
    if (leftSide.length != 1 || rightSide.length != 1) return false;

    final left = leftSide.first;
    final right = rightSide.first;

    return (left.type == ElementType.variable &&
            right.type == ElementType.number) ||
        (right.type == ElementType.variable && left.type == ElementType.number);
  }

  /// Convertir a string legible
  String get currentEquation {
    final leftStr = leftSide.map((e) => e.toString()).join(' ');
    final rightStr = rightSide.map((e) => e.toString()).join(' ');
    return '$leftStr = $rightStr';
  }

  /// Clonar estado
  BoardState clone() {
    return BoardState(
      originalEquation: originalEquation,
      leftSide: leftSide.map((e) => e.clone()).toList(),
      rightSide: rightSide.map((e) => e.clone()).toList(),
      equalsElement: equalsElement?.clone(),
      currentStep: currentStep,
      history: List.from(history),
      spotlightElementId: spotlightElementId,
      hintText: hintText,
      isCurrentActionValid: isCurrentActionValid,
      errorMessage: errorMessage,
    );
  }
}

/// Tipos de acciones que el usuario puede hacer
enum ActionType {
  drag, // Arrastrar elemento
  split, // Dividir número (pellizco)
  merge, // Fusionar términos semejantes
  slash, // Cortar términos opuestos
  substitute, // Sustituir variable por valor
  distribute, // Aplicar distributiva (ducha)
}

/// Representa una acción del usuario en la pizarra
class BoardAction {
  final String id;
  final ActionType type;
  final String elementId;
  final DateTime timestamp;

  // Metadata específica por tipo de acción
  final Map<String, dynamic>? metadata;

  BoardAction({
    String? id,
    required this.type,
    required this.elementId,
    DateTime? timestamp,
    this.metadata,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  /// Crear acción de arrastre
  factory BoardAction.drag({
    required String elementId,
    required Offset from,
    required Offset to,
    required EquationSide fromSide,
    required EquationSide toSide,
  }) {
    return BoardAction(
      type: ActionType.drag,
      elementId: elementId,
      metadata: {
        'from': {'x': from.dx, 'y': from.dy},
        'to': {'x': to.dx, 'y': to.dy},
        'fromSide': fromSide.toString(),
        'toSide': toSide.toString(),
      },
    );
  }

  /// Crear acción de fusión
  factory BoardAction.merge({
    required String elementId1,
    required String elementId2,
    required String resultElementId,
  }) {
    return BoardAction(
      type: ActionType.merge,
      elementId: elementId1,
      metadata: {'element2': elementId2, 'result': resultElementId},
    );
  }

  /// Crear acción de corte (slash)
  factory BoardAction.slash({
    required List<String> elementIds,
    required Offset slashStart,
    required Offset slashEnd,
  }) {
    return BoardAction(
      type: ActionType.slash,
      elementId: elementIds.first,
      metadata: {
        'elements': elementIds,
        'slashStart': {'x': slashStart.dx, 'y': slashStart.dy},
        'slashEnd': {'x': slashEnd.dx, 'y': slashEnd.dy},
      },
    );
  }

  @override
  String toString() {
    return 'BoardAction(${type.toString()}, element: $elementId, time: ${timestamp.toIso8601String()})';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'elementId': elementId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

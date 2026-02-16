// lib/models/math_element.dart

import 'package:flutter/material.dart';

/// Tipos de elementos matemáticos en la pizarra
enum ElementType {
  number, // Números: 4, -2, 3.5
  variable, // Variables: x, y, z
  operator, // Operadores: +, -, *, /
  equals, // Signo igual: =
  parenthesis, // Paréntesis: (, )
}

/// Estados visuales del elemento durante interacción
enum ElementState {
  idle, // Reposo, sin interacción
  dragging, // Siendo arrastrado
  hovering, // Sobre una zona de drop
  locked, // No se puede mover (parte del resultado)
  error, // Operación inválida
  glowing, // Resaltado por IA (spotlight)
}

/// Representa un elemento matemático individual en la pizarra
class MathElement {
  final String id;
  final ElementType type;

  // Valor del elemento
  dynamic value; // int, double, o String para variables

  // Estado actual
  ElementState state;

  // Posición en la pizarra
  Offset position;

  // Para variables: cual variable representa
  String? linkedVariable; // 'x', 'y', 'z'

  // Propiedades visuales
  Color color;
  double size;

  // Flags de interacción
  bool canDrag;
  bool canCrossEquals; // Solo números y variables pueden cruzar el =

  // Propiedades de animación
  bool isVibrating;
  bool isGlowing;
  double elevation;

  // Lado de la ecuación (izquierda o derecha del =)
  EquationSide side;

  MathElement({
    required this.id,
    required this.type,
    required this.value,
    this.state = ElementState.idle,
    this.position = Offset.zero,
    this.linkedVariable,
    this.color = Colors.blue,
    this.size = 60.0,
    this.canDrag = true,
    this.canCrossEquals = false,
    this.isVibrating = false,
    this.isGlowing = false,
    this.elevation = 2.0,
    this.side = EquationSide.left,
  }) {
    // Auto-configurar según tipo
    _configure();
  }

  void _configure() {
    switch (type) {
      case ElementType.number:
      case ElementType.variable:
        canCrossEquals = true;
        color = Colors.blue.shade600;
        break;

      case ElementType.operator:
        canCrossEquals = false;
        color = Colors.grey.shade700;
        size = 50.0;
        break;

      case ElementType.equals:
        canDrag = false;
        canCrossEquals = false;
        color = Colors.black;
        size = 50.0;
        break;

      case ElementType.parenthesis:
        canCrossEquals = false;
        color = Colors.purple.shade400;
        size = 55.0;
        break;
    }
  }

  /// Cambiar signo (para cruzar el portal del =)
  void flipSign() {
    if (type == ElementType.number && value is num) {
      value = -(value as num);

      // Cambiar color visual
      if (side == EquationSide.left) {
        color = Colors.red.shade600; // Ahora está del otro lado
      } else {
        color = Colors.blue.shade600;
      }
    }
  }

  /// Cambiar de lado de la ecuación
  void switchSide() {
    side = side == EquationSide.left ? EquationSide.right : EquationSide.left;
  }

  /// Clonar elemento (para ducha distributiva)
  MathElement clone({String? newId}) {
    return MathElement(
      id: newId ?? '${id}_clone',
      type: type,
      value: value,
      state: state,
      position: position,
      linkedVariable: linkedVariable,
      color: color,
      size: size,
      canDrag: canDrag,
      canCrossEquals: canCrossEquals,
      isVibrating: isVibrating,
      isGlowing: isGlowing,
      elevation: elevation,
      side: side,
    );
  }

  /// Verificar si puede fusionar con otro elemento
  bool canMergeWith(MathElement other) {
    // Solo términos semejantes: misma variable o ambos números
    if (type != other.type) return false;

    if (type == ElementType.variable) {
      return linkedVariable == other.linkedVariable;
    }

    if (type == ElementType.number) {
      return true; // Números siempre se pueden sumar
    }

    return false;
  }

  /// Convertir a string legible
  @override
  String toString() {
    switch (type) {
      case ElementType.variable:
        return linkedVariable ?? 'x';
      case ElementType.operator:
      case ElementType.equals:
      case ElementType.parenthesis:
        return value.toString();
      case ElementType.number:
        final numValue = value as num;
        if (numValue >= 0) {
          return numValue.toString();
        } else {
          return numValue.toString(); // Ya tiene el signo -
        }
    }
  }

  /// Convertir a representación compacta
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'value': value,
      'position': {'x': position.dx, 'y': position.dy},
      'side': side.toString(),
    };
  }
}

/// Lado de la ecuación
enum EquationSide {
  left, // Izquierda del =
  right, // Derecha del =
}

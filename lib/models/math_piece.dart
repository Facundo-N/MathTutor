// lib/models/math_piece.dart
import 'package:flutter/material.dart'; // ← FALTABA ESTE IMPORT

class MathPiece {
  final String id;
  final MathPieceType type;
  final String displayValue; // Lo que muestra: "2x", "+3", "="
  final dynamic rawValue; // Valor real: 2, 3, 'x'
  Offset position;
  bool isLocked; // No se puede mover
  bool isHighlighted; // Glow/pulse activo
  String? dropZoneId; // En qué zona está

  MathPiece({
    required this.id,
    required this.type,
    required this.displayValue,
    required this.rawValue,
    this.position = Offset.zero,
    this.isLocked = false,
    this.isHighlighted = false,
    this.dropZoneId,
  });

  MathPiece copyWith({
    Offset? position,
    bool? isLocked,
    bool? isHighlighted,
    String? dropZoneId,
  }) {
    return MathPiece(
      id: id,
      type: type,
      displayValue: displayValue,
      rawValue: rawValue,
      position: position ?? this.position,
      isLocked: isLocked ?? this.isLocked,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      dropZoneId: dropZoneId ?? this.dropZoneId,
    );
  }
}

enum MathPieceType {
  number, // 3, -5, 7
  variable, // x, y
  coefficient, // 2x, 3y
  operator, // +, -, ×, ÷
  fraction, // 1/2, 1/4
  equals, // =
}

// Zona donde se pueden soltar piezas
class DropZone {
  final String id;
  final String label; // "Lado Izquierdo", "Lado Derecho"
  final Rect bounds; // Área de drop
  final List<MathPieceType> acceptedTypes; // Qué piezas acepta
  bool isActive; // Si está resaltada
  List<MathPiece> pieces; // Piezas dentro

  DropZone({
    required this.id,
    required this.label,
    required this.bounds,
    required this.acceptedTypes,
    this.isActive = false,
    this.pieces = const [],
  });

  bool canAccept(MathPiece piece) {
    return acceptedTypes.contains(piece.type);
  }
}

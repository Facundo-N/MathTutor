// lib/providers/board_provider.dart

import 'package:flutter/material.dart';
import '../models/math_element.dart';
import '../models/board_state.dart';
import '../services/math_api_service.dart';

class BoardProvider with ChangeNotifier {
  BoardState? _currentBoard;

  // Configuración de feedback visual
  final Color _validActionColor = Colors.green;
  final Color _invalidActionColor = Colors.red;

  BoardState? get currentBoard => _currentBoard;

  /// Inicializar pizarra con una ecuación
  void initializeBoard(String equation) {
    debugPrint('🎨 Inicializando pizarra con: $equation');

    // Parsear ecuación simple: "2x + 4 = 10"
    final equationParts = _parseEquation(equation);

    _currentBoard = BoardState(
      originalEquation: equation,
      leftSide: equationParts['left']!,
      rightSide: equationParts['right']!,
      equalsElement: equationParts['equals']!.first,
    );

    notifyListeners();
  }

  /// Cargar ejercicio adaptativo desde el backend
  Future<void> loadAdaptiveProblem(String userId) async {
    debugPrint('🤖 Solicitando ejercicio adaptativo para: $userId');

    try {
      final response = await MathApiService.generateAdaptiveProblem(
        userId: userId,
      );

      final equation = response['expression'] as String;
      final storyContext = response['story_context'] as String?;

      // Inicializar pizarra
      initializeBoard(equation);

      // Agregar contexto de historia
      if (_currentBoard != null) {
        _currentBoard!.storyContext = storyContext;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error cargando ejercicio adaptativo: $e');
      // Fallback a un ejercicio seguro si el backend falla o devuelve basura
      initializeBoard('x + 10 = 20');
      if (_currentBoard != null) {
        _currentBoard!.storyContext =
            'Hubo un problema sincronizando con la IA, pero aquí tienes un desafío de práctica:';
        notifyListeners();
      }
    }
  }

  /// Parser simple de ecuaciones
  Map<String, List<MathElement>> _parseEquation(String equation) {
    // Remover espacios
    final clean = equation.replaceAll(' ', '');

    // Dividir por = (Máxima resiliencia)
    var sides = clean.split('=');

    if (sides.length == 1) {
      // Si no hay =, asumimos que es una expresión para igualar a cero o incógnita
      debugPrint('⚠️ Ecuación sin "=" detectada. Agregando "= 0" implícito.');
      sides = [sides[0], '0'];
    } else if (sides.length > 2) {
      // Si hay varios =, tomamos los dos primeros y avisamos
      debugPrint('⚠️ Ecuación con múltiples "=" detectada. Simplificando.');
      sides = [sides[0], sides[1]];
    }

    if (sides[0].isEmpty) sides[0] = 'x';
    if (sides[1].isEmpty) sides[1] = '0';

    // Parsear cada lado
    final leftElements = _parseSide(sides[0], EquationSide.left);
    final rightElements = _parseSide(sides[1], EquationSide.right);

    // Crear elemento del =
    final equalsEl = MathElement(
      id: 'equals_0',
      type: ElementType.equals,
      value: '=',
      position: const Offset(0, 0), // Se posicionará en el centro
      canDrag: false,
    );

    return {
      'left': leftElements,
      'right': rightElements,
      'equals': [equalsEl],
    };
  }

  /// Parsear un lado de la ecuación
  List<MathElement> _parseSide(String side, EquationSide equationSide) {
    final elements = <MathElement>[];
    var currentNumber = '';
    var elementIndex = 0;

    for (var i = 0; i < side.length; i++) {
      final char = side[i];

      if (char == 'x' || char == 'y' || char == 'z') {
        // Variable encontrada
        if (currentNumber.isNotEmpty) {
          // Hay un coeficiente antes
          final coef = int.tryParse(currentNumber) ?? 1;
          if (coef != 1) {
            elements.add(
              MathElement(
                id: '${equationSide}_num_$elementIndex',
                type: ElementType.number,
                value: coef,
                side: equationSide,
                position: Offset(100.0 * elementIndex, 200),
              ),
            );
            elementIndex++;

            // Agregar operador implícito *
            elements.add(
              MathElement(
                id: '${equationSide}_op_$elementIndex',
                type: ElementType.operator,
                value: '*',
                side: equationSide,
                position: Offset(100.0 * elementIndex, 200),
              ),
            );
            elementIndex++;
          }
          currentNumber = '';
        }

        // Agregar variable
        elements.add(
          MathElement(
            id: '${equationSide}_var_$elementIndex',
            type: ElementType.variable,
            value: 1,
            linkedVariable: char,
            side: equationSide,
            position: Offset(100.0 * elementIndex, 200),
          ),
        );
        elementIndex++;
      } else if (char == '+' || char == '-') {
        // Operador encontrado
        if (currentNumber.isNotEmpty) {
          elements.add(
            MathElement(
              id: '${equationSide}_num_$elementIndex',
              type: ElementType.number,
              value: int.parse(currentNumber),
              side: equationSide,
              position: Offset(100.0 * elementIndex, 200),
            ),
          );
          elementIndex++;
          currentNumber = '';
        }

        // Agregar operador
        elements.add(
          MathElement(
            id: '${equationSide}_op_$elementIndex',
            type: ElementType.operator,
            value: char,
            side: equationSide,
            position: Offset(100.0 * elementIndex, 200),
          ),
        );
        elementIndex++;
      } else if (char.contains(RegExp(r'[0-9]'))) {
        // Dígito
        currentNumber += char;
      }
    }

    // Agregar último número si existe
    if (currentNumber.isNotEmpty) {
      elements.add(
        MathElement(
          id: '${equationSide}_num_$elementIndex',
          type: ElementType.number,
          value: int.parse(currentNumber),
          side: equationSide,
          position: Offset(100.0 * elementIndex, 200),
        ),
      );
    }

    return elements;
  }

  /// MECÁNICA: Portal del = (Cambio de Signo)
  /// Devuelve si el elemento puede cruzar el portal + feedback visual
  bool canCrossEqualsPortal(MathElement element) {
    if (_currentBoard == null) return false;

    // Solo números y variables pueden cruzar
    return element.canCrossEquals;
  }

  /// Obtener color de feedback visual durante hover sobre el portal
  Color getPortalFeedbackColor(MathElement element) {
    if (canCrossEqualsPortal(element)) {
      return _validActionColor; // Verde: acción válida
    } else {
      return _invalidActionColor; // Rojo: acción inválida
    }
  }

  /// Cruzar elemento por el portal del =
  void crossEqualsPortal(String elementId) {
    if (_currentBoard == null) return;

    final element = _currentBoard!.findElement(elementId);
    if (element == null || !canCrossEqualsPortal(element)) {
      debugPrint('❌ Elemento $elementId no puede cruzar el portal');
      _currentBoard!.isCurrentActionValid = false;
      _currentBoard!.errorMessage =
          'Solo números y variables pueden cruzar el =';
      notifyListeners();
      return;
    }

    debugPrint('✅ Elemento $elementId cruzando portal del =');

    // Cambiar signo
    element.flipSign();

    // Mover al otro lado
    if (element.side == EquationSide.left) {
      _currentBoard!.leftSide.remove(element);
      element.switchSide();
      _currentBoard!.rightSide.add(element);
    } else {
      _currentBoard!.rightSide.remove(element);
      element.switchSide();
      _currentBoard!.leftSide.add(element);
    }

    // Registrar acción
    final action = BoardAction.drag(
      elementId: elementId,
      from: element.position,
      to: element.position,
      fromSide: element.side == EquationSide.left
          ? EquationSide.right
          : EquationSide.left,
      toSide: element.side,
    );
    _currentBoard!.addAction(action);

    // Confirmar acción válida
    _currentBoard!.isCurrentActionValid = true;
    _currentBoard!.errorMessage = null;

    notifyListeners();
  }

  /// Actualizar posición de un elemento
  void updateElementPosition(String elementId, Offset newPosition) {
    if (_currentBoard == null) return;

    final element = _currentBoard!.findElement(elementId);
    if (element != null) {
      element.position = newPosition;
      notifyListeners();
    }
  }

  /// Cambiar estado de un elemento
  void setElementState(String elementId, ElementState newState) {
    if (_currentBoard == null) return;

    final element = _currentBoard!.findElement(elementId);
    if (element != null) {
      element.state = newState;
      notifyListeners();
    }
  }

  /// Activar vibración en un elemento
  void setElementVibrating(String elementId, bool vibrating) {
    if (_currentBoard == null) return;

    final element = _currentBoard!.findElement(elementId);
    if (element != null) {
      element.isVibrating = vibrating;
      notifyListeners();
    }
  }

  /// Sistema de Spotlight (IA Coach)
  void setSpotlight(String? elementId, String? hint) {
    if (_currentBoard == null) return;

    _currentBoard!.spotlightElementId = elementId;
    _currentBoard!.hintText = hint;

    // Activar glow en el elemento
    if (elementId != null) {
      final element = _currentBoard!.findElement(elementId);
      if (element != null) {
        element.isGlowing = true;
      }
    }

    notifyListeners();
  }

  /// Limpiar spotlight
  void clearSpotlight() {
    if (_currentBoard == null) return;

    // Desactivar glow
    if (_currentBoard!.spotlightElementId != null) {
      final element = _currentBoard!.findElement(
        _currentBoard!.spotlightElementId!,
      );
      if (element != null) {
        element.isGlowing = false;
      }
    }

    _currentBoard!.spotlightElementId = null;
    _currentBoard!.hintText = null;
    notifyListeners();
  }

  /// Deshacer última acción
  void undo() {
    if (_currentBoard == null || _currentBoard!.history.isEmpty) {
      debugPrint('⚠️ No hay acciones para deshacer');
      return;
    }

    // Por ahora, reconstruir desde el principio
    // TODO: Implementar undo más inteligente
    final lastAction = _currentBoard!.undoLastAction();
    debugPrint('↩️ Deshaciendo acción: ${lastAction?.type}');

    notifyListeners();
  }

  /// Limpiar pizarra
  void clearBoard() {
    _currentBoard = null;
    notifyListeners();
  }

  /// Obtener historial de pasos en formato legible para UI
  List<String> getStepsHistory() {
    if (_currentBoard == null || _currentBoard!.history.isEmpty) {
      return [];
    }

    return _currentBoard!.history.map((action) {
      switch (action.type) {
        case ActionType.drag:
          final metadata = action.metadata ?? {};
          final fromSide =
              metadata['fromSide']?.toString().contains('left') == true
              ? 'izquierda'
              : 'derecha';
          final toSide = metadata['toSide']?.toString().contains('left') == true
              ? 'izquierda'
              : 'derecha';
          if (fromSide != toSide) {
            return 'Elemento cruzó el = desde $fromSide a $toSide';
          }
          return 'Elemento movido en el lado $fromSide';

        case ActionType.merge:
          return 'Elementos fusionados';

        case ActionType.split:
          return 'Número dividido mediante pellizco';

        case ActionType.slash:
          return 'Términos opuestos eliminados';

        case ActionType.substitute:
          return 'Variable sustituida por valor';

        case ActionType.distribute:
          return 'Distributiva aplicada';
      }
    }).toList();
  }
}

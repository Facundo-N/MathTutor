import 'package:flutter_test/flutter_test.dart';
import 'package:demo_33_v2/models/math_element.dart';
import 'package:demo_33_v2/models/board_state.dart';
import 'package:demo_33_v2/providers/board_provider.dart';

void main() {
  group('BoardProvider - Portal del = Tests', () {
    late BoardProvider provider;

    setUp(() {
      provider = BoardProvider();
    });

    test('Parsear ecuación simple correctamente', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard;
      expect(board, isNotNull);
      expect(board!.originalEquation, '2x+4=10');

      // Lado izquierdo: 2, *, x, +, 4
      expect(board.leftSide.length, greaterThan(2));

      // Lado derecho: 10
      expect(board.rightSide.length, greaterThan(0));
    });

    test('Elementos numéricos pueden cruzar el portal', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number,
      );

      expect(provider.canCrossEqualsPortal(numberElement), isTrue);
    });

    test('Operadores NO pueden cruzar el portal', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final operatorElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.operator,
        orElse: () =>
            board.rightSide.firstWhere((e) => e.type == ElementType.operator),
      );

      expect(provider.canCrossEqualsPortal(operatorElement), isFalse);
    });

    test('Color verde para elementos válidos', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number,
      );

      final color = provider.getPortalFeedbackColor(numberElement);
      expect(color.value, equals(0xFF4CAF50)); // Verde
    });

    test('Color rojo para elementos inválidos', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final operatorElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.operator,
      );

      final color = provider.getPortalFeedbackColor(operatorElement);
      expect(color.value, equals(0xFFF44336)); // Rojo
    });

    test('Cruzar portal cambia signo del número', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number && e.value == 4,
      );

      final originalValue = numberElement.value as num;
      provider.crossEqualsPortal(numberElement.id);

      expect(numberElement.value, equals(-originalValue));
    });

    test('Cruzar portal mueve elemento al otro lado', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final initialLeftCount = board.leftSide.length;
      final initialRightCount = board.rightSide.length;

      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number,
      );

      provider.crossEqualsPortal(numberElement.id);

      expect(board.leftSide.length, equals(initialLeftCount - 1));
      expect(board.rightSide.length, equals(initialRightCount + 1));
    });

    test('Historial registra acción de cruzar portal', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number,
      );

      provider.crossEqualsPortal(numberElement.id);

      expect(board.history.length, equals(1));
      expect(board.history.first.type, equals(ActionType.drag));
    });

    test('Estado de validación actualiza correctamente', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number,
      );

      // Acción válida
      provider.crossEqualsPortal(numberElement.id);
      expect(board.isCurrentActionValid, isTrue);
      expect(board.errorMessage, isNull);

      // Acción inválida
      final operatorElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.operator,
        orElse: () =>
            board.rightSide.firstWhere((e) => e.type == ElementType.operator),
      );
      provider.crossEqualsPortal(operatorElement.id);
      expect(board.isCurrentActionValid, isFalse);
      expect(board.errorMessage, isNotNull);
    });

    test('Undo deshace última acción', () {
      provider.initializeBoard('2x+4=10');

      final board = provider.currentBoard!;
      final initialHistoryLength = board.history.length;

      final numberElement = board.leftSide.firstWhere(
        (e) => e.type == ElementType.number,
      );

      provider.crossEqualsPortal(numberElement.id);
      expect(board.history.length, equals(initialHistoryLength + 1));

      provider.undo();
      expect(board.history.length, equals(initialHistoryLength));
    });
  });
}

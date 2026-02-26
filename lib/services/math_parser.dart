import 'package:flutter/foundation.dart';
// services/math_parser.dart
// Parser matemático mejorado para MathTutor

import 'dart:math' as math;

class MathProblem {
  final String expression;
  final String operation;
  final dynamic num1;
  final dynamic num2;
  final dynamic answer;
  final String visualType;
  final List<String> steps;
  final String difficulty; // 'primaria', 'secundaria'

  MathProblem({
    required this.expression,
    required this.operation,
    required this.num1,
    required this.num2,
    required this.answer,
    required this.visualType,
    required this.steps,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'expression': expression,
    'operation': operation,
    'num1': num1,
    'num2': num2,
    'answer': answer,
    'visualType': visualType,
    'steps': steps,
    'difficulty': difficulty,
  };
}

class AdvancedMathParser {
  // ============================================
  // PARSER PRINCIPAL
  // ============================================

  static MathProblem? parse(String text) {
    text = text.replaceAll(' ', '').replaceAll(',', '.').trim();
    // ignore: avoid_print
    debugPrint('📝 Parseando: $text');

    // Intentar operaciones básicas primero
    MathProblem? result;

    result = _parseSuma(text);
    if (result != null) return result;

    result = _parseResta(text);
    if (result != null) return result;

    result = _parseMultiplicacion(text);
    if (result != null) return result;

    result = _parseDivision(text);
    if (result != null) return result;

    result = _parsePotencia(text);
    if (result != null) return result;

    result = _parseRaiz(text);
    if (result != null) return result;

    result = _parseEcuacionLineal(text);
    if (result != null) return result;

    // ignore: avoid_print
    debugPrint('❌ No se detectó operación matemática');
    return null;
  }

  // ============================================
  // OPERACIONES BÁSICAS (PRIMARIA)
  // ============================================

  static MathProblem? _parseSuma(String text) {
    final regex = RegExp(r'^(\d+)\+(\d+)$');
    final match = regex.firstMatch(text);

    if (match != null) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final num1Str = match.group(1);
      final num2Str = match.group(2);

      if (num1Str == null || num2Str == null) return null;

      final num1 = int.parse(num1Str);
      final num2 = int.parse(num2Str);
      final answer = num1 + num2;

      return MathProblem(
        expression: '$num1+$num2',
        operation: '+',
        num1: num1,
        num2: num2,
        answer: answer,
        visualType: 'sum',
        steps: ['Sumamos $num1 + $num2', 'Resultado: $answer'],
        difficulty: 'primaria',
      );
    }
    return null;
  }

  static MathProblem? _parseResta(String text) {
    final regex = RegExp(r'^(\d+)-(\d+)$');
    final match = regex.firstMatch(text);

    if (match != null) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final num1Str = match.group(1);
      final num2Str = match.group(2);

      if (num1Str == null || num2Str == null) return null;

      final num1 = int.parse(num1Str);
      final num2 = int.parse(num2Str);
      final answer = num1 - num2;

      return MathProblem(
        expression: '$num1-$num2',
        operation: '-',
        num1: num1,
        num2: num2,
        answer: answer,
        visualType: 'subtract',
        steps: ['Restamos $num1 - $num2', 'Resultado: $answer'],
        difficulty: 'primaria',
      );
    }
    return null;
  }

  static MathProblem? _parseMultiplicacion(String text) {
    // Soporta: 7*8, 7x8, 7×8
    final regex = RegExp(r'^(\d+)[*x×](\d+)$');
    final match = regex.firstMatch(text);

    if (match != null) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final num1Str = match.group(1);
      final num2Str = match.group(2);

      if (num1Str == null || num2Str == null) return null;

      final num1 = int.parse(num1Str);
      final num2 = int.parse(num2Str);
      final answer = num1 * num2;

      return MathProblem(
        expression: '$num1×$num2',
        operation: '×',
        num1: num1,
        num2: num2,
        answer: answer,
        visualType: 'multiply',
        steps: [
          'Multiplicamos $num1 × $num2',
          'Esto es lo mismo que sumar $num1, $num2 veces',
          'Resultado: $answer',
        ],
        difficulty: 'primaria',
      );
    }
    return null;
  }

  static MathProblem? _parseDivision(String text) {
    // Soporta: 20/4, 20÷4
    final regex = RegExp(r'^(\d+)[/÷](\d+)$');
    final match = regex.firstMatch(text);

    if (match != null) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final num1Str = match.group(1);
      final num2Str = match.group(2);

      if (num1Str == null || num2Str == null) return null;

      final num1 = int.parse(num1Str);
      final num2 = int.parse(num2Str);

      if (num2 == 0) {
        return MathProblem(
          expression: '$num1÷0',
          operation: '÷',
          num1: num1,
          num2: 0,
          answer: 'indefinido',
          visualType: 'error',
          steps: ['No se puede dividir por 0'],
          difficulty: 'primaria',
        );
      }

      final cociente = num1 ~/ num2;
      final resto = num1 % num2;

      final answer = resto == 0
          ? cociente.toString()
          : '$cociente (resto $resto)';

      return MathProblem(
        expression: '$num1÷$num2',
        operation: '÷',
        num1: num1,
        num2: num2,
        answer: answer,
        visualType: 'divide',
        steps: [
          'Dividimos $num1 ÷ $num2',
          '¿Cuántas veces entra $num2 en $num1?',
          'Cociente: $cociente',
          if (resto > 0) 'Resto: $resto',
        ],
        difficulty: 'primaria',
      );
    }
    return null;
  }

  // ============================================
  // OPERACIONES INTERMEDIAS (SECUNDARIA)
  // ============================================

  static MathProblem? _parsePotencia(String text) {
    // Soporta: 2^3, 2**3
    final regex = RegExp(r'^(\d+)[\^*]+\*?(\d+)$');
    final match = regex.firstMatch(text);

    if (match != null) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final baseStr = match.group(1);
      final exponenteStr = match.group(2);

      if (baseStr == null || exponenteStr == null) return null;

      final base = int.parse(baseStr);
      final exponente = int.parse(exponenteStr);
      final answer = math.pow(base, exponente);

      return MathProblem(
        expression: '$base^$exponente',
        operation: '^',
        num1: base,
        num2: exponente,
        answer: answer,
        visualType: 'power',
        steps: [
          'Calculamos $base^$exponente',
          'Esto es: $base × $base × ... ($exponente veces)',
          'Resultado: $answer',
        ],
        difficulty: 'secundaria',
      );
    }
    return null;
  }

  static MathProblem? _parseRaiz(String text) {
    // Soporta: √16, sqrt(16)
    final regex = RegExp(r'^[√]?(sqrt)?\(?(\d+)\)?$');
    final match = regex.firstMatch(text);

    if (match != null && (text.contains('√') || text.contains('sqrt'))) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final numStr = match.group(2);

      if (numStr == null) return null;

      final num = int.parse(numStr);
      final answer = math.sqrt(num);
      final esExacta = answer == answer.toInt();

      return MathProblem(
        expression: '√$num',
        operation: '√',
        num1: num,
        num2: 0,
        answer: esExacta ? answer.toInt() : answer.toStringAsFixed(2),
        visualType: 'sqrt',
        steps: [
          'Calculamos √$num',
          '¿Qué número multiplicado por sí mismo da $num?',
          'Resultado: ${esExacta ? answer.toInt() : answer.toStringAsFixed(2)}',
        ],
        difficulty: 'secundaria',
      );
    }
    return null;
  }

  static MathProblem? _parseEcuacionLineal(String text) {
    // Soporta: 2x+3=7, 5x-2=13
    final regex = RegExp(r'^(\d+)x([+-])(\d+)=(\d+)$');
    final match = regex.firstMatch(text);

    if (match != null) {
      // ✅ NULL SAFETY: Verificar antes de usar
      final aStr = match.group(1);
      final operador = match.group(2);
      final bStr = match.group(3);
      final cStr = match.group(4);

      if (aStr == null || operador == null || bStr == null || cStr == null) {
        return null;
      }

      final a = int.parse(aStr);
      final b = int.parse(bStr);
      final c = int.parse(cStr);

      final bConSigno = operador == '+' ? b : -b;
      final x = (c - bConSigno) / a;

      return MathProblem(
        expression: '${a}x$operador$b=$c',
        operation: 'ecuacion_lineal',
        num1: a,
        num2: bConSigno,
        answer: x.toStringAsFixed(2),
        visualType: 'equation',
        steps: [
          'Ecuación: ${a}x$operador$b=$c',
          'Paso 1: Despejamos x',
          'Restamos $bConSigno de ambos lados: ${a}x = ${c - bConSigno}',
          'Dividimos por $a: x = ${(c - bConSigno) / a}',
          'Solución: x = ${x.toStringAsFixed(2)}',
        ],
        difficulty: 'secundaria',
      );
    }
    return null;
  }

  // ============================================
  // EVALUADOR DE EXPRESIONES CON PARÉNTESIS
  // ============================================

  static double? evaluarExpresion(String expr) {
    try {
      expr = expr.replaceAll(' ', '');
      // Implementación simplificada - para casos complejos usar un parser real
      // Por ahora evalúa expresiones básicas sin paréntesis

      // Orden de operaciones: *, / antes que +, -
      final tokens = _tokenize(expr);
      return _evaluate(tokens);
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error al evaluar: $e');
      return null;
    }
  }

  static List<String> _tokenize(String expr) {
    final tokens = <String>[];
    var currentNum = '';

    for (var i = 0; i < expr.length; i++) {
      final char = expr[i];
      if (RegExp(r'[0-9.]').hasMatch(char)) {
        currentNum += char;
      } else if (RegExp(r'[+\-*/^]').hasMatch(char)) {
        if (currentNum.isNotEmpty) {
          tokens.add(currentNum);
          currentNum = '';
        }
        tokens.add(char);
      }
    }

    if (currentNum.isNotEmpty) {
      tokens.add(currentNum);
    }

    return tokens;
  }

  static double? _evaluate(List<String> tokens) {
    if (tokens.isEmpty) return null;

    // Procesar multiplicación y división primero
    var i = 0;
    while (i < tokens.length) {
      if (i > 0 && i < tokens.length - 1) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          final left = double.parse(tokens[i - 1]);
          final right = double.parse(tokens[i + 1]);
          final result = tokens[i] == '*' ? left * right : left / right;

          tokens.removeRange(i - 1, i + 2);
          tokens.insert(i - 1, result.toString());
          i = 0;
          continue;
        }
      }
      i++;
    }

    // Procesar suma y resta
    i = 0;
    while (i < tokens.length) {
      if (i > 0 && i < tokens.length - 1) {
        if (tokens[i] == '+' || tokens[i] == '-') {
          final left = double.parse(tokens[i - 1]);
          final right = double.parse(tokens[i + 1]);
          final result = tokens[i] == '+' ? left + right : left - right;

          tokens.removeRange(i - 1, i + 2);
          tokens.insert(i - 1, result.toString());
          i = 0;
          continue;
        }
      }
      i++;
    }

    return tokens.length == 1 ? double.parse(tokens[0]) : null;
  }

  // ============================================
  // UTILIDADES
  // ============================================

  static String getDifficultyLevel(String expression) {
    if (expression.contains('x') || expression.contains('^')) {
      return 'secundaria';
    }
    return 'primaria';
  }

  static List<String> getHintsForOperation(String operation) {
    switch (operation) {
      case '+':
        return ['Contá hacia adelante', 'Podés usar tus dedos'];
      case '-':
        return ['Contá hacia atrás', 'Pensá en quitar objetos'];
      case '×':
        return ['Usá la tabla de multiplicar', 'Es una suma repetida'];
      case '÷':
        return ['¿Cuántas veces entra?', 'Usá la multiplicación al revés'];
      case '^':
        return ['Multiplicá el número por sí mismo', 'Ej: 2³ = 2×2×2'];
      case '√':
        return ['¿Qué número al cuadrado da este?', 'Probá algunos números'];
      default:
        return ['Seguí los pasos', 'Andá de a poco'];
    }
  }
}

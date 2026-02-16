// lib/services/answer_validator.dart
// Validador inteligente de respuestas matemáticas

class AnswerValidationResult {
  final bool isCorrect;
  final String normalizedAnswer;
  final String? expectedAnswer;
  final String? feedback;

  AnswerValidationResult.correct(
    this.normalizedAnswer, {
    this.feedback,
  })  : isCorrect = true,
        expectedAnswer = null;

  AnswerValidationResult.incorrect(
    this.normalizedAnswer,
    this.expectedAnswer, {
    this.feedback,
  }) : isCorrect = false;

  AnswerValidationResult.invalid(
    this.normalizedAnswer, {
    this.feedback,
  })  : isCorrect = false,
        expectedAnswer = null;
}

class AnswerValidator {
  /// Valida respuesta del usuario contra la respuesta esperada
  static AnswerValidationResult validate(String userInput, dynamic expectedAnswer) {
    // Limpiar input básico
    String cleaned = userInput.trim().toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(',', '.');

    if (cleaned.isEmpty) {
      return AnswerValidationResult.invalid(
        '',
        feedback: 'La respuesta está vacía',
      );
    }

    // Intentar diferentes formatos

    // 1. NÚMERO ENTERO
    final intResult = _tryParseInt(cleaned, expectedAnswer);
    if (intResult != null) return intResult;

    // 2. NÚMERO DECIMAL
    final doubleResult = _tryParseDouble(cleaned, expectedAnswer);
    if (doubleResult != null) return doubleResult;

    // 3. FORMATO "x = valor"
    final equationResult = _tryParseEquation(cleaned, expectedAnswer);
    if (equationResult != null) return equationResult;

    // 4. FRACCIÓN "a/b"
    final fractionResult = _tryParseFraction(cleaned, expectedAnswer);
    if (fractionResult != null) return fractionResult;

    // 5. PORCENTAJE "50%"
    final percentResult = _tryParsePercent(cleaned, expectedAnswer);
    if (percentResult != null) return percentResult;

    // 6. RESPUESTA TEXTUAL (sí/no, verdadero/falso)
    final textResult = _tryParseText(cleaned, expectedAnswer);
    if (textResult != null) return textResult;

    // No se pudo parsear
    return AnswerValidationResult.incorrect(
      cleaned,
      expectedAnswer.toString(),
      feedback: 'No reconozco ese formato. Probá con un número.',
    );
  }

  // ============================================
  // PARSEADORES ESPECÍFICOS
  // ============================================

  /// Intentar parsear como entero
  static AnswerValidationResult? _tryParseInt(String input, dynamic expected) {
    final value = int.tryParse(input);
    if (value == null) return null;

    // Comparar con diferentes tipos
    if (expected is int && value == expected) {
      return AnswerValidationResult.correct(value.toString());
    } else if (expected is double && value.toDouble() == expected) {
      return AnswerValidationResult.correct(value.toString());
    } else if (expected is String && value.toString() == expected) {
      return AnswerValidationResult.correct(value.toString());
    }

    return AnswerValidationResult.incorrect(
      value.toString(),
      expected.toString(),
    );
  }

  /// Intentar parsear como decimal
  static AnswerValidationResult? _tryParseDouble(String input, dynamic expected) {
    final value = double.tryParse(input);
    if (value == null) return null;

    const epsilon = 0.01; // Tolerancia para decimales

    // Comparar según tipo de expected
    if (expected is int) {
      final diff = (value - expected.toDouble()).abs();
      if (diff < epsilon) {
        return AnswerValidationResult.correct(
          value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''),
        );
      }
    } else if (expected is double) {
      final diff = (value - expected).abs();
      if (diff < epsilon) {
        return AnswerValidationResult.correct(
          value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), ''),
        );
      }
    } else if (expected is String) {
      final expectedNum = double.tryParse(expected);
      if (expectedNum != null && (value - expectedNum).abs() < epsilon) {
        return AnswerValidationResult.correct(value.toString());
      }
    }

    return AnswerValidationResult.incorrect(
      value.toString(),
      expected.toString(),
    );
  }

  /// Intentar parsear ecuación "x=2" o "x = 2.5"
  static AnswerValidationResult? _tryParseEquation(String input, dynamic expected) {
    // Regex: x = número
    final regex = RegExp(r'^x=([\d.+-]+)$');
    final match = regex.firstMatch(input);

    if (match == null) return null;

    final valueStr = match.group(1);
    if (valueStr == null) return null;

    final value = double.tryParse(valueStr);
    if (value == null) return null;

    const epsilon = 0.01;

    // Comparar según tipo
    if (expected is int) {
      if ((value - expected.toDouble()).abs() < epsilon) {
        return AnswerValidationResult.correct('x = $value');
      }
    } else if (expected is double) {
      if ((value - expected).abs() < epsilon) {
        return AnswerValidationResult.correct('x = $value');
      }
    }

    return AnswerValidationResult.incorrect(
      'x = $value',
      'x = $expected',
    );
  }

  /// Intentar parsear fracción "3/4"
  static AnswerValidationResult? _tryParseFraction(String input, dynamic expected) {
    final regex = RegExp(r'^(\d+)/(\d+)$');
    final match = regex.firstMatch(input);

    if (match == null) return null;

    final numStr = match.group(1);
    final denStr = match.group(2);

    if (numStr == null || denStr == null) return null;

    final numerator = int.tryParse(numStr);
    final denominator = int.tryParse(denStr);

    if (numerator == null || denominator == null || denominator == 0) return null;

    final decimal = numerator / denominator;
    const epsilon = 0.01;

    // Comparar según tipo
    if (expected is int) {
      if ((decimal - expected.toDouble()).abs() < epsilon) {
        return AnswerValidationResult.correct(
          '$numerator/$denominator',
          feedback: 'Correcto! ($numerator/$denominator = ${decimal.toStringAsFixed(2)})',
        );
      }
    } else if (expected is double) {
      if ((decimal - expected).abs() < epsilon) {
        return AnswerValidationResult.correct(
          '$numerator/$denominator',
          feedback: 'Correcto! ($numerator/$denominator = ${decimal.toStringAsFixed(2)})',
        );
      }
    } else if (expected is String) {
      // Comparar como fracciones
      if (expected == input) {
        return AnswerValidationResult.correct('$numerator/$denominator');
      }
    }

    return AnswerValidationResult.incorrect(
      '$numerator/$denominator',
      expected.toString(),
    );
  }

  /// Intentar parsear porcentaje "50%"
  static AnswerValidationResult? _tryParsePercent(String input, dynamic expected) {
    final regex = RegExp(r'^(\d+(?:\.\d+)?)%$');
    final match = regex.firstMatch(input);

    if (match == null) return null;

    final valueStr = match.group(1);
    if (valueStr == null) return null;

    final percent = double.tryParse(valueStr);
    if (percent == null) return null;

    final decimal = percent / 100;
    const epsilon = 0.01;

    // Comparar según tipo
    if (expected is int || expected is double) {
      final expectedDouble = expected is int ? expected.toDouble() : expected as double;

      // Si esperamos decimal (0.5) y escriben "50%"
      if ((decimal - expectedDouble).abs() < epsilon) {
        return AnswerValidationResult.correct(
          '$percent%',
          feedback: 'Correcto! $percent% = $decimal',
        );
      }
      // Si esperamos porcentaje (50) y escriben "50%"
      if ((percent - expectedDouble).abs() < epsilon) {
        return AnswerValidationResult.correct('$percent%');
      }
    }

    return AnswerValidationResult.incorrect(
      '$percent%',
      expected.toString(),
    );
  }

  /// Intentar parsear texto (sí/no, verdadero/falso)
  static AnswerValidationResult? _tryParseText(String input, dynamic expected) {
    final positiveWords = ['si', 'sí', 'yes', 'verdadero', 'true', 'correcto'];
    final negativeWords = ['no', 'falso', 'false', 'incorrecto'];

    if (!positiveWords.contains(input) && !negativeWords.contains(input)) {
      return null;
    }

    final userSaysYes = positiveWords.contains(input);

    if (expected is bool) {
      if (userSaysYes == expected) {
        return AnswerValidationResult.correct(userSaysYes ? 'Sí' : 'No');
      }
      return AnswerValidationResult.incorrect(
        userSaysYes ? 'Sí' : 'No',
        expected ? 'Sí' : 'No',
      );
    }

    return null;
  }

  // ============================================
  // UTILIDADES
  // ============================================

  /// Normalizar respuesta para mostrar
  static String normalizeForDisplay(dynamic answer) {
    if (answer is int) return answer.toString();
    if (answer is double) {
      // Eliminar .0 si es entero
      if (answer == answer.toInt()) {
        return answer.toInt().toString();
      }
      return answer.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
    return answer.toString();
  }

  /// Detectar si la respuesta del usuario está "cerca"
  static bool isClose(String userInput, dynamic expectedAnswer, {double tolerance = 0.1}) {
    final userNum = double.tryParse(userInput.replaceAll(',', '.'));

    if (userNum == null) return false;

    if (expectedAnswer is int || expectedAnswer is double) {
      final expectedDouble = expectedAnswer is int 
          ? expectedAnswer.toDouble() 
          : expectedAnswer as double;
      final diff = (userNum - expectedDouble).abs();
      final maxDiff = expectedDouble.abs() * tolerance;
      return diff <= maxDiff;
    }

    return false;
  }
}

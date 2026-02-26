import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Modelos para la API
class MathStep {
  final int stepNumber;
  final String expression;
  final String explanation;
  final String? latex;

  MathStep({
    required this.stepNumber,
    required this.expression,
    required this.explanation,
    this.latex,
  });

  factory MathStep.fromJson(Map<String, dynamic> json) {
    return MathStep(
      stepNumber: json['step_number'],
      expression: json['expression'],
      explanation: json['explanation'],
      latex: json['latex'],
    );
  }
}

// ✅ Modelo para punto en el gráfico
class GraphPoint {
  final double x;
  final double y;

  GraphPoint({required this.x, required this.y});

  factory GraphPoint.fromJson(Map<String, dynamic> json) {
    return GraphPoint(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
    );
  }
}

// ✅ Modelo para datos del gráfico
class GraphData {
  final bool canGraph;
  final List<double> xValues;
  final List<double> yValues;
  final GraphPoint? solutionPoint;
  final String equation;
  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
  final String? error;

  GraphData({
    required this.canGraph,
    this.xValues = const [],
    this.yValues = const [],
    this.solutionPoint,
    this.equation = '',
    this.xMin = -10,
    this.xMax = 10,
    this.yMin = -10,
    this.yMax = 10,
    this.error,
  });

  factory GraphData.fromJson(Map<String, dynamic> json) {
    debugPrint('🔧 Parseando GraphData...');
    debugPrint('   can_graph: ${json['can_graph']}');
    debugPrint('   x_values length: ${json['x_values']?.length ?? 0}');
    debugPrint('   y_values length: ${json['y_values']?.length ?? 0}');

    return GraphData(
      canGraph: json['can_graph'] ?? false,
      xValues: json['x_values'] != null
          ? List<double>.from(json['x_values'].map((x) => x.toDouble()))
          : [],
      yValues: json['y_values'] != null
          ? List<double>.from(json['y_values'].map((y) => y.toDouble()))
          : [],
      solutionPoint: json['solution_point'] != null
          ? GraphPoint.fromJson(json['solution_point'])
          : null,
      equation: json['equation'] ?? '',
      xMin: (json['x_min'] ?? -10).toDouble(),
      xMax: (json['x_max'] ?? 10).toDouble(),
      yMin: (json['y_min'] ?? -10).toDouble(),
      yMax: (json['y_max'] ?? 10).toDouble(),
      error: json['error'],
    );
  }
}

// ✅ MathSolution con graphData
class MathSolution {
  final String expression;
  final String solution;
  final List<MathStep> steps;
  final List<String> hints;
  final List<String>? latexSteps;
  final GraphData? graphData;

  MathSolution({
    required this.expression,
    required this.solution,
    required this.steps,
    required this.hints,
    this.latexSteps,
    this.graphData,
  });

  factory MathSolution.fromJson(Map<String, dynamic> json) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📦 PARSEANDO MathSolution');
    debugPrint('📋 JSON keys recibidas: ${json.keys.toList()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // ✅ Parsear graphData con debug detallado
    GraphData? graphData;
    if (json['graph_data'] != null) {
      debugPrint('✅ graph_data EXISTE en JSON');
      debugPrint('   Tipo: ${json['graph_data'].runtimeType}');
      debugPrint('   Contenido: ${json['graph_data']}');

      try {
        graphData = GraphData.fromJson(json['graph_data']);
        debugPrint('✅ GraphData parseado exitosamente');
        debugPrint('   canGraph: ${graphData.canGraph}');
        debugPrint('   xValues.length: ${graphData.xValues.length}');
        debugPrint('   yValues.length: ${graphData.yValues.length}');
      } catch (e) {
        debugPrint('❌ ERROR parseando GraphData: $e');
      }
    } else {
      debugPrint('❌ graph_data NO EXISTE en JSON');
      debugPrint('   JSON completo: $json');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    return MathSolution(
      expression: json['expression'],
      solution: json['solution'],
      steps: (json['steps'] as List)
          .map((step) => MathStep.fromJson(step))
          .toList(),
      hints: List<String>.from(json['hints']),
      latexSteps: json['latex_steps'] != null
          ? List<String>.from(json['latex_steps'])
          : null,
      graphData: graphData,
    );
  }
}

/// Servicio para comunicarse con el backend Python
class MathEngineService {
  // URL del servidor
  // Para emulador Android: http://10.0.2.2:8000
  // Para dispositivo físico: http://TU_IP_LOCAL:8000
  static const String baseUrl = 'http://10.0.2.2:8000';

  static final http.Client _client = http.Client();

  /// Resuelve una expresión matemática con pasos
  static Future<MathSolution> solveMath({
    required String expression,
    bool showSteps = true,
  }) async {
    try {
      debugPrint('📤 Enviando al backend: $expression');

      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/solve'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'expression': expression,
              'showsteps':
                  showSteps, // ✅ CORREGIDO: sin guión bajo (como espera el backend)
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception('Timeout - El servidor no respondió'),
          );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint(
        '📥 Response body (primeros 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final solution = MathSolution.fromJson(jsonData);

        debugPrint('✅ Solución parseada: ${solution.solution}');
        debugPrint('✅ GraphData disponible: ${solution.graphData != null}');

        if (solution.graphData != null) {
          debugPrint('📊 Gráfico canGraph: ${solution.graphData!.canGraph}');
          if (solution.graphData!.canGraph) {
            debugPrint('📊 Ecuación: ${solution.graphData!.equation}');
            debugPrint('📊 Puntos: ${solution.graphData!.xValues.length}');
          } else if (solution.graphData!.error != null) {
            debugPrint('❌ Error en gráfico: ${solution.graphData!.error}');
          }
        }

        return solution;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error en solveMath: $e');
      rethrow;
    }
  }

  /// Obtiene pistas progresivas
  static Future<List<String>> getHints({
    required String expression,
    int level = 0,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/hints'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'expression': expression, 'level': level}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return List<String>.from(jsonData['hints']);
      } else {
        throw Exception('Error al obtener pistas');
      }
    } catch (e) {
      debugPrint('❌ Error en getHints: $e');
      rethrow;
    }
  }

  /// Verifica conexión con el servidor
  static Future<bool> checkConnection() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Sin conexión con el servidor: $e');
      return false;
    }
  }
}

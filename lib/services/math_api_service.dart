import 'package:flutter/foundation.dart';
// lib/services/math_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/guided_exercise_model.dart';
import '../models/tutorial_scene_model.dart';

class MathApiService {
  // ✅ URL de tu backend local (misma IP que SignalCollector)
  // ✅ URL de tu backend unificada
  static const String baseUrl = 'https://TU_URL_NGROK.ngrok-free.dev';

  /// Cabeceras comunes para todas las peticiones (incluye bypass de Ngrok)
  static Map<String, String> get commonHeaders => {
    'Content-Type': 'application/json',
  };

  /// Genera automáticamente la URL del WebSocket basada en el baseUrl
  static String get wsBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl.replaceFirst('https://', 'wss://');
    } else {
      return baseUrl.replaceFirst('http://', 'ws://');
    }
  }

  /// Resuelve una expresión matemática
  static Future<Map<String, dynamic>> solveMath({
    required String expression,
    bool showSteps = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/solve');

      final response = await http.post(
        url,
        headers: commonHeaders,
        body: jsonEncode({'expression': expression, 'show_steps': showSteps}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene pistas para una expresión
  static Future<Map<String, dynamic>> getHints({
    required String expression,
    int level = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/hints');

      final response = await http.post(
        url,
        headers: commonHeaders,
        body: jsonEncode({'expression': expression, 'level': level}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// ⭐ NUEVO: Valida una acción matemática (MVP hiperpersonalización)
  static Future<Map<String, dynamic>> validarAccion({
    required String ecuacionActual,
    required String accionTexto,
    String? errorType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/problem/validar-paso');

      final response = await http.post(
        url,
        headers: commonHeaders,
        body: jsonEncode({
          'ecuacion_actual': ecuacionActual,
          'accion_texto': accionTexto,
          if (errorType != null) 'error_type': errorType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error validando acción: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  /// ⭐ NUEVO: Genera problema adaptativo con OpenAI
  static Future<Map<String, dynamic>> generateAdaptiveProblem({
    required String userId,
    String topic = 'linear_equations',
    String difficulty = 'medium',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/problem/generate/adaptive');

      debugPrint('🤖 Generando problema adaptativo para $userId...');
      debugPrint('   Tema: $topic, Dificultad: $difficulty');

      final response = await http
          .post(
            url,
            headers: commonHeaders,
            body: jsonEncode({
              'user_id': userId,
              'topic': topic,
              'difficulty': difficulty,
            }),
          )
          .timeout(
            const Duration(seconds: 15), // OpenAI puede tardar más
            onTimeout: () {
              throw Exception('Timeout generando problema (15s)');
            },
          );

      if (response.statusCode == 200) {
        final problem = jsonDecode(response.body);
        debugPrint('✅ Problema generado: ${problem['expression']}');
        debugPrint('   Generado por: ${problem['generated_by']}');
        return problem;
      } else if (response.statusCode == 503) {
        throw Exception('Generación con IA no disponible. Backend sin OpenAI.');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error generando problema adaptativo: $e');
      rethrow;
    }
  }

  /// ⭐ NUEVO: Genera un ejercicio guiado interactivo vía IA
  static Future<GuidedExercise> generateGuidedExercise({
    required String userId,
    required String topicId,
    String? tutorialEquation,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/problem/guided-exercise/generate');

      final response = await http
          .post(
            url,
            headers: commonHeaders,
            body: jsonEncode({
              'user_id': userId,
              'topic_id': topicId,
              if (tutorialEquation != null) 'tutorial_equation': tutorialEquation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return GuidedExercise.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error CRÍTICO generando ejercicio guiado: $e');
      
      final fallbackEq = tutorialEquation ?? "2x = 6";
      debugPrint('⚠️ Ecuación original solicitada: $fallbackEq');
      
      String eqType = "Lineal";
      if (fallbackEq.contains('^2') || fallbackEq.contains('**2')) {
        eqType = "Cuadrática";
      } else if (fallbackEq.contains('^3') || fallbackEq.contains('**3')) {
        eqType = "Cúbica";
      } else if (fallbackEq.contains('(')) {
        eqType = "Distributiva";
      }
      debugPrint('📌 Detectado tipo de ecuación: $eqType');

      final parts = fallbackEq.split('=');
      final leftPart = parts[0].trim();
      final rightPart = parts.length > 1 ? parts[1].trim() : "0";

      return GuidedExercise(
        equation: fallbackEq,
        answer: "x = ?",
        steps: [
          GuidedStep(
            instruction: "Resuelve paso a paso ($eqType).",
            ttsText: "Intenta resolver esta ecuación interactuando con los bloques.",
            targetBlockId: null,
            expectedSide: "right",
            successMessage: "¡Bien hecho!",
            errorMessage: "Sigue intentando.",
            bunnyAction: BunnyAction.celebrate,
            blocksBefore: [
              GuidedBlock(id: "left", value: leftPart, type: "blockDark", side: "left"),
              GuidedBlock(id: "eq", value: "=", type: "operator", side: "center"),
              GuidedBlock(id: "right", value: rightPart, type: "blockGreen", side: "right"),
            ],
            blocksAfter: [
              GuidedBlock(id: "left_ans", value: "x", type: "blockDark", side: "left"),
              GuidedBlock(id: "eq", value: "=", type: "operator", side: "center"),
              GuidedBlock(id: "right_ans", value: "?", type: "blockGreen", side: "right"),
            ],
          ),
        ],
      );
    }
  }

  /// ⭐ NUEVO: Genera problema legacy (sin IA, random)
  static Future<Map<String, dynamic>> generateProblemLegacy({
    String topic = 'arithmetic',
    String difficulty = 'easy',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/problem/generate');

      final response = await http.post(
        url,
        headers: commonHeaders,
        body: jsonEncode({
          'topic': topic,
          'difficulty': difficulty,
          'count': 1,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Verifica que el backend esté funcionando
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      debugPrint('🔍 Checking backend health at: $url');
      final response = await http.get(url, headers: commonHeaders).timeout(const Duration(seconds: 5));
      debugPrint(
        '📡 Health response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final health = jsonDecode(response.body);

        // ⭐ Mostrar estado de OpenAI
        if (health['components'] != null) {
          final openaiStatus = health['components']['openai_generator'];
          debugPrint('🤖 OpenAI Generator: $openaiStatus');
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Backend health check failed: $e');
      return false;
    }
  }

  /// ⭐ NUEVO: Verifica si la generación con IA está disponible
  static Future<bool> isAIGenerationAvailable() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url, headers: commonHeaders).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final health = jsonDecode(response.body);
        final openaiStatus = health['components']?['openai_generator'];
        return openaiStatus == 'ready';
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error verificando AI generation: $e');
      return false;
    }
  }

  /// ⭐ NUEVO: Selecciona template aleatorio desde el backend (Anti-repetición)
  static Future<Map<String, dynamic>> selectTemplate({
    required String userId,
    required String topicId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/template/select');
      final response = await http
          .post(
            url,
            headers: commonHeaders,
            body: jsonEncode({'user_id': userId, 'topic_id': topicId}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error seleccionando template: $e');
      rethrow;
    }
  }

  /// ⭐ NUEVO: Descompone una ecuación en bloques para el minijuego
  static Future<Map<String, dynamic>> decomposeEquation({
    required String equation,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/equation/decompose');
      
      debugPrint('🔍 Descomponiendo ecuación: $equation');
      
      final response = await http.post(
        url,
        headers: commonHeaders,
        body: jsonEncode({'equation': equation}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error descomponiendo ecuación: $e');
      rethrow;
    }
  }
}

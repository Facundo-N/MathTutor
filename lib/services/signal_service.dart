// lib/services/signal_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class SignalService {
  // URL del backend (cambia según tu setup)
  static const String baseUrl = 'http://192.168.0.11:8000/api/signals';
  
  // Session ID (genera uno al inicio de la app)
  static String? _sessionId;
  static String get sessionId {
    _sessionId ??= const Uuid().v4();
    return _sessionId!;
  }
  
  // User ID (hardcodeado por ahora, después usa auth real)
  static const String userId = 'user_demo_001';
  
  /// Envía una señal individual al backend
  static Future<bool> sendSignal({
    required String signalType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_id': sessionId,
          'user_id': userId,
          'signal_type': signalType,
          'metadata': metadata ?? {},
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error enviando señal: $e');
      return false;
    }
  }
  
  /// Captura señal de problema completado
  static Future<void> problemComplete({
    required String expression,
    required int timeSpent,
    required bool correct,
  }) async {
    await sendSignal(
      signalType: 'problem_complete',
      metadata: {
        'expression': expression,
        'time_spent_seconds': timeSpent,
        'correct': correct,
      },
    );
  }
  
  /// Captura señal de error
  static Future<void> problemError({
    required String expression,
    required String errorType,
  }) async {
    await sendSignal(
      signalType: 'error',
      metadata: {
        'expression': expression,
        'error_type': errorType,
      },
    );
  }
  
  /// Captura señal de solicitud de pista
  static Future<void> hintRequest({
    required String expression,
    required int step,
  }) async {
    await sendSignal(
      signalType: 'hint_request',
      metadata: {
        'expression': expression,
        'step': step,
      },
    );
  }
  
  /// Captura método de input usado
  static Future<void> inputMethod(String method) async {
    await sendSignal(
      signalType: 'input_method',
      metadata: {'method': method}, // 'voice', 'text', 'camera'
    );
  }
}

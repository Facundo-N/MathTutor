// lib/services/signal_collector.dart (ACTUALIZADO CON RESILENCIA)

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/user_signal.dart';

class SignalCollector {
  // Backend URL
  static const String baseUrl = 'http://192.168.0.11:8000';
  static const int bufferMaxSize = 50;
  static const Duration flushInterval = Duration(seconds: 5);
  
  // ⭐ NUEVA: Configuración de resilencia
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxBufferHistory = 100; // Máximo de señales almacenadas

  final String userId;
  final String sessionId = const Uuid().v4();
  final List<UserSignal> buffer = [];
  DateTime? lastFlush;
  DateTime sessionStart = DateTime.now();
  
  // ⭐ NUEVA: Tracking de intentos fallidos
  int failedAttempts = 0;
  bool isDisposed = false;
  Timer? flushTimer;

  SignalCollector({required this.userId}) {
    lastFlush = DateTime.now();
    debugPrint('✅ SignalCollector iniciado: userId=$userId, sessionId=$sessionId');
    
    // ⭐ NUEVA: Iniciar timer de flush automático (desacoplado)
    _startAutoFlushTimer();
  }

  // ⭐ NUEVA: Timer de flush automático en background
  void _startAutoFlushTimer() {
    flushTimer = Timer.periodic(flushInterval, (_) {
      if (!isDisposed && buffer.isNotEmpty) {
        debugPrint('⏰ Auto-flush triggered by timer');
        flushToBackend();
      }
    });
  }

  // ==================== MÉTODOS ESPECÍFICOS (YA EXISTÍAN) ====================

  void trackProblemStart(String problemExpression, String topic) {
    addSignal(UserSignal(
      type: 'problem_start',
      timestamp: DateTime.now(),
      metadata: {
        'expression': problemExpression,
        'topic': topic,
      },
    ));
  }

  void trackProblemComplete(
    String problemExpression,
    int errorCount,
    Duration timeSpent,
  ) {
    addSignal(UserSignal(
      type: 'problem_complete',
      timestamp: DateTime.now(),
      metadata: {
        'expression': problemExpression,
        'error_count': errorCount,
        'time_spent_seconds': timeSpent.inSeconds,
      },
    ));
  }

  void trackInputMethod(String method) {
    addSignal(UserSignal(
      type: 'input_method',
      timestamp: DateTime.now(),
      metadata: {'method': method},
    ));
  }

  void trackError(String errorType, String context) {
    addSignal(UserSignal(
      type: 'error',
      timestamp: DateTime.now(),
      metadata: {
        'error_type': errorType,
        'context': context,
      },
    ));
  }

  void trackHintRequest() {
    addSignal(UserSignal(
      type: 'hint_request',
      timestamp: DateTime.now(),
      metadata: {},
    ));
  }

  // ⭐ NUEVO: MÉTODO GENÉRICO (MÁS FLEXIBLE)
  void trackEvent(String type, Map<String, dynamic> metadata) {
    addSignal(UserSignal(
      type: type,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  // ==================== GESTIÓN DE BUFFER ====================

  void addSignal(UserSignal signal) {
    try {
      if (isDisposed) {
        debugPrint('⚠️ SignalCollector dispuesto, ignorando señal: ${signal.type}');
        return;
      }

      buffer.add(signal);
      debugPrint('📊 Signal capturada: ${signal.type} (total buffer: ${buffer.length}/$maxBufferHistory)');

      // ⭐ NUEVA: Validar límite de buffer
      if (buffer.length > maxBufferHistory) {
        debugPrint('⚠️ Buffer excedió límite, removiendo señales antiguas');
        buffer.removeRange(0, buffer.length - maxBufferHistory);
      }

      // Flush automático si buffer lleno
      if (buffer.length >= bufferMaxSize) {
        debugPrint('⏰ Buffer lleno: ${buffer.length} >= $bufferMaxSize');
        flushToBackend();
      }
    } catch (e) {
      debugPrint('❌ Error en addSignal: $e');
    }
  }

  // ⭐ NUEVA: Retry con backoff exponencial
  Future<void> flushToBackend({int attempt = 1}) async {
    try {
      if (isDisposed) {
        debugPrint('⚠️ SignalCollector dispuesto, abortando flush');
        return;
      }

      if (buffer.isEmpty) {
        debugPrint('⚠️ Skip flush: buffer vacío');
        failedAttempts = 0; // Reset en éxito
        return;
      }

      final signalsToSend = List<UserSignal>.from(buffer);
      
      final sessionSignals = SessionSignals(
        sessionId: sessionId,
        userId: userId,
        sessionStart: sessionStart,
        signals: signalsToSend,
      );

      debugPrint('📤 [Intento $attempt/$maxRetries] Enviando ${signalsToSend.length} señales a $baseUrl/api/signals/ingest...');

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/signals/ingest'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(sessionSignals.toJson()),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint('✅ Señales enviadas correctamente en intento $attempt');
          buffer.clear();
          lastFlush = DateTime.now();
          failedAttempts = 0; // ⭐ NUEVO: Reset contador en éxito
          return; // ✅ Éxito - NO reintentar
        } else if (response.statusCode == 404) {
          // ⭐ NUEVA: Error 404 = endpoint no existe, no reintentar
          debugPrint('❌ Error 404: Endpoint /api/signals/ingest no existe. Descartando buffer.');
          buffer.clear();
          failedAttempts = maxRetries; // Marcar como agotado
          return;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } on TimeoutException catch (_) {
        debugPrint('⏱️ Timeout en intento $attempt');
        throw Exception('timeout');
      }
    } catch (e) {
      debugPrint('⚠️ Error en intento $attempt: $e');
      failedAttempts++;

      // ⭐ NUEVA: Reintentar si no excedió máximo
      if (attempt < maxRetries) {
        final backoffDelay = Duration(
          seconds: retryDelay.inSeconds * (1 << (attempt - 1)), // Exponencial: 2s, 4s, 8s
        );
        debugPrint('⏳ Reintentando en ${backoffDelay.inSeconds}s...');
        
        await Future.delayed(backoffDelay);
        await flushToBackend(attempt: attempt + 1);
      } else {
        debugPrint('❌ Agotados $maxRetries intentos. Buffer (${buffer.length} señales) se mantiene en memoria.');
        // ⭐ NO limpiar buffer = datos persisten para reintentar después
      }
    }
  }

  // Llamar al cerrar sesión (FUERZA envío inmediato con reintentos)
  Future<void> endSession() async {
    debugPrint('👋 Finalizando sesión y enviando señales pendientes...');
    await flushToBackend();
  }

  // Flush manual (para debug)
  Future<void> forceFlush() async {
    debugPrint('🔧 Flush forzado manualmente');
    await flushToBackend();
  }

  // ⭐ NUEVA: Cleanup seguro
  void dispose() {
    try {
      isDisposed = true;
      flushTimer?.cancel();
      debugPrint('✅ SignalCollector dispuesto. Buffer final: ${buffer.length} señales.');
    } catch (e) {
      debugPrint('⚠️ Error en dispose: $e');
    }
  }
}

// ⭐ NUEVO: Helper class para serializar SessionSignals
class SessionSignals {
  final String sessionId;
  final String userId;
  final DateTime sessionStart;
  final List<UserSignal> signals;

  SessionSignals({
    required this.sessionId,
    required this.userId,
    required this.sessionStart,
    required this.signals,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'sessionStart': sessionStart.toIso8601String(),
      'signals': signals.map((s) => s.toJson()).toList(),
    };
  }
}


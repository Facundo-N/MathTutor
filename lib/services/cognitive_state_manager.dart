// lib/services/cognitive_state_manager.dart

import 'dart:collection';

/// Estados cognitivos del estudiante
enum CognitiveState {
  exploracion,   // Descubriendo, necesita más visual y guía
  construccion,  // Construyendo comprensión, necesita pasos
  fluidez        // Domina el concepto, puede ir más rápido
}

/// Métricas de la sesión actual
class SessionMetrics {
  // Respuestas recientes (true = correcto, false = incorrecto)
  final Queue<bool> recentAnswers = Queue();

  // Tiempos de respuesta recientes
  final Queue<Duration> responseTimes = Queue();

  // Señales de confusión detectadas
  final List<String> confusionSignals = [];

  // Contadores
  int consecutiveErrors = 0;
  int consecutiveCorrects = 0;
  int totalAnswers = 0;
  int totalCorrect = 0;

  // Timestamp del último registro
  DateTime? lastAnswerTime;

  /// Registrar una respuesta
  void recordAnswer(bool correct, Duration responseTime) {
    // Agregar a historial (mantener últimas 10)
    recentAnswers.add(correct);
    if (recentAnswers.length > 10) {
      recentAnswers.removeFirst();
    }

    responseTimes.add(responseTime);
    if (responseTimes.length > 10) {
      responseTimes.removeFirst();
    }

    // Actualizar contadores
    totalAnswers++;
    if (correct) {
      totalCorrect++;
      consecutiveCorrects++;
      consecutiveErrors = 0;
    } else {
      consecutiveErrors++;
      consecutiveCorrects = 0;
    }

    lastAnswerTime = DateTime.now();
  }

  /// Registrar señal de confusión
  void recordConfusionSignal(String signal) {
    confusionSignals.add(signal);
    // Mantener solo las últimas 5
    if (confusionSignals.length > 5) {
      confusionSignals.removeAt(0);
    }
  }

  /// Calcular tasa de aciertos reciente
  double get recentSuccessRate {
    if (recentAnswers.isEmpty) return 0.5; // Neutral al inicio
    final correct = recentAnswers.where((x) => x).length;
    return correct / recentAnswers.length;
  }

  /// Calcular tiempo de respuesta promedio en segundos
  double get averageResponseTime {
    if (responseTimes.isEmpty) return 10.0;
    final total = responseTimes.fold<int>(0, (sum, duration) => sum + duration.inSeconds);
    return total / responseTimes.length;
  }

  /// Detectar si hay confusión reciente
  bool get hasRecentConfusion => confusionSignals.isNotEmpty;

  /// Limpiar métricas (nuevo problema)
  void reset() {
    recentAnswers.clear();
    responseTimes.clear();
    confusionSignals.clear();
    consecutiveErrors = 0;
    consecutiveCorrects = 0;
    lastAnswerTime = null;
  }
}

/// Gestor del estado cognitivo del estudiante
class CognitiveStateManager {
  CognitiveState _currentState = CognitiveState.exploracion;
  final SessionMetrics metrics = SessionMetrics();

  // Historial de transiciones para debugging
  final List<Map<String, dynamic>> transitionLog = [];

  // ✅ Callback para notificar cambios de estado
  final void Function(CognitiveState newState)? onStateChanged;

  CognitiveStateManager({this.onStateChanged});

  CognitiveState get currentState => _currentState;

  // ==================== MÉTODOS PÚBLICOS (CON PARÁMETROS NOMBRADOS) ====================

  /// ✅ NUEVO: Método principal con parámetros nombrados
  void recordAnswer({
    required bool isCorrect,
    required int responseTime,
    String? confusionSignal,
  }) {
    // Registrar respuesta
    metrics.recordAnswer(isCorrect, Duration(seconds: responseTime));

    // Registrar señal de confusión si existe
    if (confusionSignal != null && confusionSignal.isNotEmpty) {
      metrics.recordConfusionSignal(confusionSignal);
    }

    // Actualizar estado
    _updateState();
  }

  /// ✅ NUEVO: Método alternativo con Duration (para compatibilidad)
  void recordAnswerWithDuration({
    required bool isCorrect,
    required Duration responseTime,
    String? confusionSignal,
  }) {
    metrics.recordAnswer(isCorrect, responseTime);

    if (confusionSignal != null && confusionSignal.isNotEmpty) {
      metrics.recordConfusionSignal(confusionSignal);
    }

    _updateState();
  }

  /// ✅ NUEVO: Método simplificado para respuestas rápidas
  void recordQuickAnswer(bool isCorrect) {
    recordAnswer(
      isCorrect: isCorrect,
      responseTime: 5, // Default 5 segundos
    );
  }

  /// Registrar solo señal de confusión (sin respuesta)
  void recordConfusionSignal(String signal) {
    metrics.recordConfusionSignal(signal);
    _updateState();
  }

  // ==================== LÓGICA INTERNA ====================

  /// Lógica de transición entre estados
  void _updateState() {
    final oldState = _currentState;

    // REGLAS DE TRANSICIÓN
    
    // 1. Si hay 2+ errores consecutivos → EXPLORACIÓN
    if (metrics.consecutiveErrors >= 2) {
      _currentState = CognitiveState.exploracion;
    }
    // 2. Si hay confusión reciente → EXPLORACIÓN
    else if (metrics.hasRecentConfusion) {
      _currentState = CognitiveState.exploracion;
    }
    // 3. Si está en EXPLORACIÓN y tiene 2-3 correctos consecutivos → CONSTRUCCIÓN
    else if (_currentState == CognitiveState.exploracion && 
             metrics.consecutiveCorrects >= 2) {
      _currentState = CognitiveState.construccion;
    }
    // 4. Si está en CONSTRUCCIÓN y tiene 3+ correctos consecutivos → FLUIDEZ
    else if (_currentState == CognitiveState.construccion && 
             metrics.consecutiveCorrects >= 3) {
      _currentState = CognitiveState.fluidez;
    }
    // 5. Si está en FLUIDEZ pero la tasa de aciertos baja < 70% → CONSTRUCCIÓN
    else if (_currentState == CognitiveState.fluidez && 
             metrics.recentSuccessRate < 0.7) {
      _currentState = CognitiveState.construccion;
    }

    // Registrar transición si cambió
    if (oldState != _currentState) {
      _logTransition(oldState, _currentState);
      
      // Notificar cambio (si hay callback)
      onStateChanged?.call(_currentState);
    }
  }

  // ==================== CONFIGURACIÓN ====================

  /// Obtener configuración según el estado actual
  Map<String, dynamic> getStateConfig() {
    switch (_currentState) {
      case CognitiveState.exploracion:
        return {
          'visualIntensity': 0.9,           // Mucho visual
          'stepDetail': 'alto',             // Pasos muy detallados
          'responseWaitTime': 15,           // Esperar más tiempo
          'encouragementFrequency': 0.8,    // Celebrar casi todo
          'hintsEnabled': true,
          'analogiesEnabled': true,
          'tone': 'patient',                // ✅ NUEVO: tono paciente
          'exampleCount': 3,                // ✅ NUEVO: 3 ejemplos
        };

      case CognitiveState.construccion:
        return {
          'visualIntensity': 0.5,           // Menos visual, más texto
          'stepDetail': 'medio',            // Pasos normales
          'responseWaitTime': 10,
          'encouragementFrequency': 0.5,    // Celebrar logros importantes
          'hintsEnabled': true,
          'analogiesEnabled': false,
          'tone': 'neutral',                // ✅ NUEVO
          'exampleCount': 1,                // ✅ NUEVO
        };

      case CognitiveState.fluidez:
        return {
          'visualIntensity': 0.2,           // Mínimo visual
          'stepDetail': 'bajo',             // Solo resultado
          'responseWaitTime': 8,            // Respuesta rápida
          'encouragementFrequency': 0.3,    // Celebrar solo grandes logros
          'hintsEnabled': false,
          'analogiesEnabled': false,
          'tone': 'direct',                 // ✅ NUEVO: tono directo
          'exampleCount': 0,                // ✅ NUEVO: sin ejemplos
        };
    }
  }

  /// Obtener descripción del estado actual para debugging
  String getStateDescription() {
    switch (_currentState) {
      case CognitiveState.exploracion:
        return 'Explorando: necesita más guía visual y pasos pequeños';
      case CognitiveState.construccion:
        return 'Construyendo: conectando conceptos y razonando';
      case CognitiveState.fluidez:
        return 'Fluidez: domina el concepto, puede ir más rápido';
    }
  }

  // ==================== DEBUGGING ====================

  /// Registrar transición para debugging
  void _logTransition(CognitiveState from, CognitiveState to) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'from': from.name,
      'to': to.name,
      'consecutiveCorrects': metrics.consecutiveCorrects,
      'consecutiveErrors': metrics.consecutiveErrors,
      'successRate': metrics.recentSuccessRate,
    };

    transitionLog.add(log);

    // ignore: avoid_print
    print('🔄 Estado cognitivo: ${from.name} → ${to.name}');
    // ignore: avoid_print
    print('   Correctos: ${metrics.consecutiveCorrects}, Errores: ${metrics.consecutiveErrors}');
    // ignore: avoid_print
    print('   Tasa éxito: ${(metrics.recentSuccessRate * 100).toStringAsFixed(0)}%');
  }

  /// Obtener log de transiciones para debugging/analytics
  List<Map<String, dynamic>> getTransitionLog() {
    return List.unmodifiable(transitionLog);
  }

  /// ✅ NUEVO: Obtener estado actual en formato JSON
  Map<String, dynamic> toJson() {
    return {
      'currentState': _currentState.name,
      'consecutiveCorrects': metrics.consecutiveCorrects,
      'consecutiveErrors': metrics.consecutiveErrors,
      'totalAnswers': metrics.totalAnswers,
      'totalCorrect': metrics.totalCorrect,
      'successRate': metrics.recentSuccessRate,
      'averageResponseTime': metrics.averageResponseTime,
      'hasConfusion': metrics.hasRecentConfusion,
      'config': getStateConfig(),
    };
  }

  // ==================== RESET ====================

  /// Reiniciar para nuevo problema (mantiene estado pero resetea métricas)
  void resetForNewProblem() {
    metrics.reset();
    // No cambiar el estado, mantenerlo para continuidad
  }

  /// Reiniciar completamente (nueva sesión)
  void resetCompletely() {
    _currentState = CognitiveState.exploracion;
    metrics.reset();
    transitionLog.clear();
  }
}

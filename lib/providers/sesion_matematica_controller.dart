import 'package:flutter/foundation.dart';

/// Controlador que mantiene el estado cognitivo de una sesión de resolución de ejercicios.
/// Registra las equivocaciones por tipo (antipatrón) para brindar ayuda escalonada.
class SesionMatematicaController extends ChangeNotifier {
  // Mapa de tipo de error a cantidad de veces que se ha cometido en esta sesión
  final Map<String, int> _errorCounts = {};
  
  // Total de errores en el ejercicio actual
  int _totalErrors = 0;

  Map<String, int> get errorCounts => _errorCounts;
  int get totalErrors => _totalErrors;

  /// Registra un error y devuelve cuántas veces se ha cometido ese error en particular
  int registrarError(String errorType) {
    if (errorType.isEmpty) return 0;
    
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    _totalErrors++;
    
    notifyListeners();
    return _errorCounts[errorType]!;
  }

  /// Devuelve el nivel de ayuda que debería mostrarse para un tipo de error
  /// Nivel 1: Sutil
  /// Nivel 2: Tooltip/Explicación
  /// Nivel 3: Asistencia agresiva / Intervención
  int getNivelAyuda(String errorType) {
    final count = _errorCounts[errorType] ?? 0;
    if (count == 0) return 0;
    if (count == 1) return 1;
    if (count == 2) return 2;
    return 3; 
  }

  /// Limpia los contadores. Debería llamarse al iniciar un nuevo ejercicio o nivel.
  void reiniciarSesion() {
    _errorCounts.clear();
    _totalErrors = 0;
    notifyListeners();
  }

  /// Verifica si algún tipo de error se convirtió en un "blocker" (patrón persistente)
  bool necesitaPlantillaRefuerzo() {
    // Si un error se cometió 3 veces o más, el usuario tiene debilidad en ese concepto
    return _errorCounts.values.any((count) => count >= 3);
  }

  /// Devuelve el antipatrón más recurrente, o nulo si no hay suficientes errores
  String? obtenerAntipatronPrincipal() {
    if (_errorCounts.isEmpty) return null;
    
    String? topError;
    int maxCount = 0;
    
    _errorCounts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        topError = key;
      }
    });

    // Solo lo consideramos un "patrón" si se equivocó al menos 2 veces
    if (maxCount >= 2) {
      return topError;
    }
    return null;
  }
}

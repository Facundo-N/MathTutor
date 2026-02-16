// lib/models/user_behavior.dart
class UserBehavior {
  int tapsPerMinute = 0;
  double avgTimePerStep = 0; // segundos
  double voiceUsagePercent = 0; // 0-100
  int exploratoryTaps = 0; // taps sin objetivo claro
  double sessionDuration = 0; // minutos
  int errorsPerProblem = 0;
  int hintsRequested = 0;
  String preferredInputMethod = ''; // 'voice', 'text', 'camera'
  
  // Calcular estilo sugerido
  VisualStyle calculateSuggestedStyle() {
    int playfulScore = 0;
    int balancedScore = 0;
    int minimalScore = 0;
    
    // Velocidad de interacción
    if (tapsPerMinute > 30) playfulScore += 3;
    else if (tapsPerMinute > 15) balancedScore += 3;
    else minimalScore += 3;
    
    // Tiempo de respuesta
    if (avgTimePerStep < 5) playfulScore += 2;
    else if (avgTimePerStep < 10) balancedScore += 2;
    else minimalScore += 2;
    
    // Uso de voz
    if (voiceUsagePercent > 70) playfulScore += 3;
    else if (voiceUsagePercent > 30) balancedScore += 2;
    else minimalScore += 2;
    
    // Taps exploratorios
    if (exploratoryTaps > 10) playfulScore += 2;
    else if (exploratoryTaps > 5) balancedScore += 2;
    else minimalScore += 1;
    
    // Duración de sesión
    if (sessionDuration < 10) playfulScore += 2;
    else if (sessionDuration < 25) balancedScore += 2;
    else minimalScore += 2;
    
    // Peticiones de ayuda
    if (hintsRequested > 5) playfulScore += 3;
    else if (hintsRequested > 2) balancedScore += 2;
    else minimalScore += 2;
    
    // Determinar ganador
    if (playfulScore > balancedScore && playfulScore > minimalScore) {
      return VisualStyle.playful;
    } else if (minimalScore > balancedScore && minimalScore > playfulScore) {
      return VisualStyle.minimal;
    }
    return VisualStyle.balanced;
  }
}

enum VisualStyle { playful, balanced, minimal }

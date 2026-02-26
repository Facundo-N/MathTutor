// lib/models/session_types.dart

/// Orientación de la sesión (NO controlada por el usuario)
enum SessionOrientation {
  portrait, // Vertical (avatar grande + sub-barra)
  landscape, // Horizontal (visual grande + panel tutor)
}

/// Fases de la sesión tutora
enum SessionPhase {
  greeting, // Saludo inicial (portrait)
  processing, // Procesando foto (portrait)
  working, // Resolviendo ejercicio (landscape)
  clarifying, // Micro-pregunta por confusión (portrait)
  finished, // Ejercicio terminado (portrait)
}

/// Modo de interacción actual
enum InteractionMode {
  idle, // Sin actividad
  listening, // Escuchando voz del usuario
  speaking, // Avatar hablando
  capturingPhoto, // Capturando foto con cámara
}

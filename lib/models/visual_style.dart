// lib/models/visual_style.dart

import 'package:flutter/material.dart';

/// Los 3 estilos visuales disponibles
enum VisualStyle {
  playful,    // Divertido: colores brillantes, animaciones bouncy
  balanced,   // Balanceado: neutral, elegante
  minimal,    // Minimalista: sobrio, directo
}

/// Configuración visual completa para cada estilo
class VisualStyleConfig {
  // ===== TAMAÑOS =====
  final double cubeSize;           // Tamaño de cubitos/piezas manipulables
  final double avatarSize;         // Tamaño del avatar en landscape
  final double spacing;            // Espaciado entre elementos
  final double buttonHeight;       // Altura de botones
  final double fontSize;           // Tamaño de texto base
  final double titleFontSize;      // Tamaño de títulos

  // ===== COLORES =====
  final Color primaryColor;        // Color principal
  final Color secondaryColor;      // Color secundario
  final Color backgroundColor;     // Fondo de containers
  final Color errorColor;          // Color de errores
  final Color successColor;        // Color de aciertos

  // ===== ANIMACIONES =====
  final String animationStyle;     // 'bouncy', 'smooth', 'fade'
  final int animationDurationMs;   // Duración en milisegundos
  final Curve animationCurve;      // Curva de animación

  // ===== COPY/TONO =====
  final String copyTone;           // 'fun', 'neutral', 'formal'
  final bool useEmojis;            // Si usa emojis o no
  final bool showCelebrations;     // Si muestra confetti/celebraciones

  // ===== SONIDOS =====
  final bool enableSounds;         // Si reproduce sonidos
  final String soundPack;          // 'cheerful', 'subtle', 'minimal'

  // ===== TIPOGRAFÍA =====
  final FontWeight fontWeight;
  final double letterSpacing;

  const VisualStyleConfig({
    required this.cubeSize,
    required this.avatarSize,
    required this.spacing,
    required this.buttonHeight,
    required this.fontSize,
    required this.titleFontSize,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.errorColor,
    required this.successColor,
    required this.animationStyle,
    required this.animationDurationMs,
    required this.animationCurve,
    required this.copyTone,
    required this.useEmojis,
    required this.showCelebrations,
    required this.enableSounds,
    required this.soundPack,
    required this.fontWeight,
    required this.letterSpacing,
  });

  // ==================== ESTILO PLAYFUL ====================
  static VisualStyleConfig playful() {
    return const VisualStyleConfig(
      // Tamaños: grandes, espaciados
      cubeSize: 80,
      avatarSize: 180,
      spacing: 50,
      buttonHeight: 48,
      fontSize: 18,
      titleFontSize: 28,

      // Colores: brillantes, RGB puro
      primaryColor: Color(0xFF2196F3),      // Azul brillante
      secondaryColor: Color(0xFFFF9800),    // Naranja vibrante
      backgroundColor: Color(0xFFF3F4FF),   // Azul muy claro
      errorColor: Color(0xFFFF5252),        // Rojo brillante
      successColor: Color(0xFF4CAF50),      // Verde brillante

      // Animaciones: bouncy, largas
      animationStyle: 'bouncy',
      animationDurationMs: 600,
      animationCurve: Curves.elasticOut,

      // Copy: divertido, con emojis
      copyTone: 'fun',
      useEmojis: true,
      showCelebrations: true,

      // Sonidos: alegres
      enableSounds: true,
      soundPack: 'cheerful',

      // Tipografía: redondeada, espaciada
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  // ==================== ESTILO BALANCED ====================
  static VisualStyleConfig balanced() {
    return const VisualStyleConfig(
      // Tamaños: medianos, estándar
      cubeSize: 60,
      avatarSize: 120,
      spacing: 32,
      buttonHeight: 44,
      fontSize: 16,
      titleFontSize: 22,

      // Colores: secundarios, suaves
      primaryColor: Color(0xFF1976D2),      // Azul marino
      secondaryColor: Color(0xFF00897B),    // Verde agua
      backgroundColor: Color(0xFFFAFAFA),   // Gris muy claro
      errorColor: Color(0xFFE57373),        // Rojo suave
      successColor: Color(0xFF81C784),      // Verde suave

      // Animaciones: smooth, medias
      animationStyle: 'smooth',
      animationDurationMs: 400,
      animationCurve: Curves.easeOut,

      // Copy: neutro, sin emojis
      copyTone: 'neutral',
      useEmojis: false,
      showCelebrations: false,

      // Sonidos: sutiles
      enableSounds: true,
      soundPack: 'subtle',

      // Tipografía: normal
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    );
  }

  // ==================== ESTILO MINIMAL ====================
  static VisualStyleConfig minimal() {
    return const VisualStyleConfig(
      // Tamaños: pequeños, densos
      cubeSize: 50,
      avatarSize: 80,
      spacing: 24,
      buttonHeight: 40,
      fontSize: 14,
      titleFontSize: 18,

      // Colores: neutros, profesionales
      primaryColor: Color(0xFF37474F),      // Gris azulado oscuro
      secondaryColor: Color(0xFF546E7A),    // Gris medio
      backgroundColor: Color(0xFFFFFFF),    // Blanco puro
      errorColor: Color(0xFFB71C1C),        // Rojo oscuro
      successColor: Color(0xFF388E3C),      // Verde oscuro

      // Animaciones: fade rápido
      animationStyle: 'fade',
      animationDurationMs: 200,
      animationCurve: Curves.easeInOut,

      // Copy: formal, directo
      copyTone: 'formal',
      useEmojis: false,
      showCelebrations: false,

      // Sonidos: desactivados
      enableSounds: false,
      soundPack: 'minimal',

      // Tipografía: monospace, compacta
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
    );
  }

  // ==================== HELPERS ====================

  /// Obtiene el copy según el tono para diferentes situaciones
  String getCopy(String situation) {
    switch (copyTone) {
      case 'fun':
        return _getFunCopy(situation);
      case 'neutral':
        return _getNeutralCopy(situation);
      case 'formal':
        return _getFormalCopy(situation);
      default:
        return _getNeutralCopy(situation);
    }
  }

  String _getFunCopy(String situation) {
    switch (situation) {
      case 'correct':
        return '¡Excelente! 🎉';
      case 'incorrect':
        return 'Casi casi... probá de nuevo 💪';
      case 'hint':
        return 'Te doy una pista 💡';
      case 'start':
        return '¡Dale, empecemos! 🚀';
      case 'finish':
        return '¡Lo lograste! ¡Sos un crack! ⭐';
      default:
        return '¡Genial!';
    }
  }

  String _getNeutralCopy(String situation) {
    switch (situation) {
      case 'correct':
        return 'Correcto';
      case 'incorrect':
        return 'No es correcto, intentá de nuevo';
      case 'hint':
        return 'Pista';
      case 'start':
        return 'Empecemos';
      case 'finish':
        return 'Completado';
      default:
        return 'Bien';
    }
  }

  String _getFormalCopy(String situation) {
    switch (situation) {
      case 'correct':
        return 'Correcto.';
      case 'incorrect':
        return 'Incorrecto. Revisá tu respuesta.';
      case 'hint':
        return 'Sugerencia:';
      case 'start':
        return 'Comenzar';
      case 'finish':
        return 'Ejercicio completado.';
      default:
        return 'Listo.';
    }
  }

  /// Duración de animación como Duration
  Duration get animationDuration => Duration(milliseconds: animationDurationMs);
}

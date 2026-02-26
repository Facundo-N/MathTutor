// lib/services/visual_style_provider.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visual_style.dart';

/// Provider que gestiona el estilo visual actual de la app
/// y lo persiste para futuras sesiones
class VisualStyleProvider with ChangeNotifier {
  // Estado actual
  VisualStyle _currentStyle = VisualStyle.balanced; // Default
  bool _autoAdapt = true; // Si ajusta automáticamente según comportamiento
  bool _hasCompletedOnboarding = false;

  // Keys para SharedPreferences
  static const String _keyStyle = 'visual_style';
  static const String _keyAutoAdapt = 'auto_adapt';
  static const String _keyOnboarding = 'has_completed_onboarding';

  VisualStyleProvider() {
    _loadFromPreferences();
  }

  // ==================== GETTERS ====================

  /// Estilo actual seleccionado
  VisualStyle get currentStyle => _currentStyle;

  /// Configuración completa del estilo actual
  VisualStyleConfig get config {
    switch (_currentStyle) {
      case VisualStyle.playful:
        return VisualStyleConfig.playful();
      case VisualStyle.balanced:
        return VisualStyleConfig.balanced();
      case VisualStyle.minimal:
        return VisualStyleConfig.minimal();
    }
  }

  /// Si el sistema puede adaptar automáticamente
  bool get autoAdapt => _autoAdapt;

  /// Si completó el onboarding de selección de estilo
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  // ==================== SETTERS ====================

  /// Cambia el estilo visual
  ///
  /// [style] - Nuevo estilo a aplicar
  /// [manual] - Si true, desactiva auto-adapt (el usuario lo eligió manualmente)
  /// [saveToPrefs] - Si guarda en SharedPreferences (default: true)
  Future<void> setStyle(
    VisualStyle style, {
    bool manual = false,
    bool saveToPrefs = true,
  }) async {
    if (_currentStyle == style) return;

    debugPrint(
      '🎨 Cambiando estilo: $_currentStyle → $style (manual: $manual)',
    );

    _currentStyle = style;

    // Si el usuario lo eligió manualmente, desactivar auto-adapt
    if (manual) {
      _autoAdapt = false;
      debugPrint('🔒 Auto-adapt desactivado (elección manual)');
    }

    notifyListeners();

    if (saveToPrefs) {
      await _saveToPreferences();
    }
  }

  /// Activa/desactiva la adaptación automática
  Future<void> setAutoAdapt(bool enabled) async {
    if (_autoAdapt == enabled) return;

    debugPrint('🤖 Auto-adapt: $enabled');

    _autoAdapt = enabled;
    notifyListeners();

    await _saveToPreferences();
  }

  /// Marca que completó el onboarding
  Future<void> completeOnboarding(VisualStyle chosenStyle) async {
    debugPrint('✅ Onboarding completado con estilo: $chosenStyle');

    _currentStyle = chosenStyle;
    _hasCompletedOnboarding = true;
    _autoAdapt = true; // Por default, permitir adaptación

    notifyListeners();

    await _saveToPreferences();
  }

  /// Resetea a valores por default (útil para testing)
  Future<void> reset() async {
    debugPrint('🔄 Reseteando VisualStyleProvider');

    _currentStyle = VisualStyle.balanced;
    _autoAdapt = true;
    _hasCompletedOnboarding = false;

    notifyListeners();

    await _saveToPreferences();
  }

  // ==================== PERSISTENCIA ====================

  /// Carga preferencias guardadas
  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar estilo
      final styleString = prefs.getString(_keyStyle);
      if (styleString != null) {
        _currentStyle = VisualStyle.values.firstWhere(
          (e) => e.name == styleString,
          orElse: () => VisualStyle.balanced,
        );
      }

      // Cargar auto-adapt
      _autoAdapt = prefs.getBool(_keyAutoAdapt) ?? true;

      // Cargar onboarding
      _hasCompletedOnboarding = prefs.getBool(_keyOnboarding) ?? false;

      debugPrint(
        '📂 Cargado: estilo=$_currentStyle, autoAdapt=$_autoAdapt, onboarding=$_hasCompletedOnboarding',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error cargando preferencias: $e');
    }
  }

  /// Guarda preferencias
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyStyle, _currentStyle.name);
      await prefs.setBool(_keyAutoAdapt, _autoAdapt);
      await prefs.setBool(_keyOnboarding, _hasCompletedOnboarding);

      debugPrint('💾 Guardado: estilo=$_currentStyle, autoAdapt=$_autoAdapt');
    } catch (e) {
      debugPrint('❌ Error guardando preferencias: $e');
    }
  }

  // ==================== HELPERS ====================

  /// Obtiene el nombre legible del estilo actual
  String get styleDisplayName {
    switch (_currentStyle) {
      case VisualStyle.playful:
        return 'Divertido';
      case VisualStyle.balanced:
        return 'Balanceado';
      case VisualStyle.minimal:
        return 'Minimalista';
    }
  }

  /// Obtiene descripción del estilo actual
  String get styleDescription {
    switch (_currentStyle) {
      case VisualStyle.playful:
        return 'Colores brillantes y animaciones alegres';
      case VisualStyle.balanced:
        return 'Equilibrio entre visual y funcionalidad';
      case VisualStyle.minimal:
        return 'Diseño sobrio y directo';
    }
  }

  /// Obtiene el ícono del estilo actual
  String get styleIcon {
    switch (_currentStyle) {
      case VisualStyle.playful:
        return '🎨';
      case VisualStyle.balanced:
        return '⚖️';
      case VisualStyle.minimal:
        return '▫️';
    }
  }
}

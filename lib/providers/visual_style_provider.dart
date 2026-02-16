// lib/providers/visual_style_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/visual_styles.dart';

class VisualStyleProvider extends ChangeNotifier {
  VisualStyle _currentStyle = VisualStyle.balanced;
  VisualStyleConfig _config = balancedStyle;

  VisualStyle get currentStyle => _currentStyle;
  VisualStyleConfig get config => _config;

  VisualStyleProvider() {
    _loadSavedStyle();
  }

  // Cargar estilo guardado
  Future<void> _loadSavedStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStyleIndex = prefs.getInt('visual_style') ?? 1; // Default: balanced
      
      _currentStyle = VisualStyle.values[savedStyleIndex];
      _config = getStyleConfig(_currentStyle);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading style: $e');
    }
  }

  // Cambiar estilo
  Future<void> setStyle(VisualStyle newStyle) async {
    if (_currentStyle == newStyle) return;
    
    _currentStyle = newStyle;
    _config = getStyleConfig(newStyle);
    
    // Guardar en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('visual_style', newStyle.index);
    } catch (e) {
      debugPrint('Error saving style: $e');
    }
    
    notifyListeners();
  }

  // Helper: Auto-seleccionar estilo según edad
  Future<void> setStyleByAge(int age) async {
    VisualStyle style;
    
    if (age <= 11) {
      style = VisualStyle.playful;
    } else if (age <= 17) {
      style = VisualStyle.balanced;
    } else {
      style = VisualStyle.minimal;
    }
    
    await setStyle(style);
  }
}

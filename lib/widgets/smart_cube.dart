// lib/widgets/smart_cube.dart
import 'package:flutter/material.dart';
import '../utils/visual_styles.dart';

class SmartCube extends StatelessWidget {
  final String content;
  final VisualStyleConfig config;
  final bool isActive;
  final VoidCallback? onTap;

  const SmartCube({
    super.key,
    required this.content,
    required this.config,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Si no es 3D, usamos versión plana
    if (!config.cubeIs3D) {
      return _buildFlatCube();
    }

    // Si es 3D, usamos versión con gradiente/sombra
    return _build3DCube();
  }

  Widget _build3DCube() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: config.cubeSize,
        height: config.cubeSize,
        decoration: BoxDecoration(
          gradient: config.buttonHasGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isActive ? config.accentColor : config.primaryColor,
                    isActive
                        ? config.accentColor.withValues(alpha: 0.6)
                        : config.primaryColor.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: config.buttonHasGradient
              ? null
              : (isActive ? config.accentColor : config.primaryColor),
          borderRadius: BorderRadius.circular(config.cubeBorderRadius),
          boxShadow: [
            BoxShadow(
              color: (isActive ? config.accentColor : config.primaryColor)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            content,
            style: TextStyle(
              color: Colors.white,
              fontSize: config.headingSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildFlatCube() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: config.cubeSize,
        height: config.cubeSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? config.accentColor : config.secondaryColor,
            width: config.cubeBorderWidth,
          ),
          borderRadius: BorderRadius.circular(config.cubeBorderRadius),
        ),
        child: Center(
          child: Text(
            content,
            style: TextStyle(
              color: isActive ? config.accentColor : config.primaryColor,
              fontSize: config.headingSize,
              fontWeight: config.fontWeight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

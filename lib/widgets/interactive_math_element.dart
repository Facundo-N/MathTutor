// lib/widgets/interactive_math_element.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/math_element.dart';
import '../providers/board_provider.dart';

/// Widget arrastrable para un elemento matemático con soporte para Portal del =
class InteractiveMathElement extends StatefulWidget {
  final MathElement element;

  const InteractiveMathElement({Key? key, required this.element})
    : super(key: key);

  @override
  State<InteractiveMathElement> createState() => _InteractiveMathElementState();
}

class _InteractiveMathElementState extends State<InteractiveMathElement>
    with SingleTickerProviderStateMixin {
  late AnimationController _vibrationController;
  late Animation<double> _vibrationAnimation;

  @override
  void initState() {
    super.initState();

    // Setup vibración
    _vibrationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _vibrationAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _vibrationController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(InteractiveMathElement oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Iniciar/detener vibración según estado
    if (widget.element.isVibrating && !_vibrationController.isAnimating) {
      _vibrationController.repeat(reverse: true);
    } else if (!widget.element.isVibrating &&
        _vibrationController.isAnimating) {
      _vibrationController.stop();
    }
  }

  @override
  void dispose() {
    _vibrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardProvider = context.watch<BoardProvider>();
    final element = widget.element;

    // Configuración visual según estado
    Color backgroundColor = element.color;
    double elevation = element.elevation;
    double scale = 1.0;

    switch (element.state) {
      case ElementState.idle:
        backgroundColor = element.color;
        elevation = 2.0;
        scale = 1.0;
        break;

      case ElementState.dragging:
        backgroundColor = element.color.withOpacity(0.8);
        elevation = 8.0;
        scale = 1.1;
        break;

      case ElementState.hovering:
        backgroundColor = element.color;
        elevation = 4.0;
        scale = 1.05;
        break;

      case ElementState.locked:
        backgroundColor = Colors.grey.shade400;
        elevation = 1.0;
        scale = 0.95;
        break;

      case ElementState.error:
        backgroundColor = Colors.red.shade300;
        elevation = 2.0;
        scale = 0.9;
        break;

      case ElementState.glowing:
        backgroundColor = Colors.amber.shade300;
        elevation = 6.0;
        scale = 1.15;
        break;
    }

    // Glow effect para spotlight
    final glowDecoration = element.isGlowing
        ? BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          )
        : null;

    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: AnimatedBuilder(
        animation: _vibrationAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: element.isVibrating
                ? Offset(_vibrationAnimation.value, 0)
                : Offset.zero,
            child: child,
          );
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Container(
            decoration: glowDecoration,
            child: element.canDrag
                ? _buildDraggable(
                    context,
                    boardProvider,
                    element,
                    backgroundColor,
                    elevation,
                  )
                : _buildStaticPiece(element, backgroundColor, elevation),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggable(
    BuildContext context,
    BoardProvider boardProvider,
    MathElement element,
    Color backgroundColor,
    double elevation,
  ) {
    return LongPressDraggable<MathElement>(
      data: element,
      feedback: _buildPiece(
        element,
        backgroundColor.withOpacity(0.7),
        elevation + 4,
        true,
      ),
      childWhenDragging: _buildPiece(
        element,
        backgroundColor.withOpacity(0.3),
        0,
        false,
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        boardProvider.setElementState(element.id, ElementState.dragging);
      },
      onDragEnd: (details) {
        boardProvider.setElementState(element.id, ElementState.idle);
        boardProvider.updateElementPosition(element.id, details.offset);
      },
      child: _buildPiece(element, backgroundColor, elevation, false),
    );
  }

  Widget _buildStaticPiece(
    MathElement element,
    Color backgroundColor,
    double elevation,
  ) {
    return _buildPiece(element, backgroundColor, elevation, false);
  }

  Widget _buildPiece(
    MathElement element,
    Color backgroundColor,
    double elevation,
    bool isFeedback,
  ) {
    return Material(
      color: backgroundColor,
      elevation: elevation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: element.size,
        height: element.size,
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            element.toString(),
            style: TextStyle(
              fontSize:
                  element.type == ElementType.number ||
                      element.type == ElementType.variable
                  ? 24
                  : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

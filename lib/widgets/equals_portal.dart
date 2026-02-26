// lib/widgets/equals_portal.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/math_element.dart';
import '../providers/board_provider.dart';

/// Widget del Portal del = - Zona de drop que cambia el signo
class EqualsPortal extends StatefulWidget {
  final MathElement equalsElement;
  final double portalWidth;

  const EqualsPortal({
    super.key,
    required this.equalsElement,
    this.portalWidth = 80.0,
  });

  @override
  State<EqualsPortal> createState() => _EqualsPortalState();
}

class _EqualsPortalState extends State<EqualsPortal>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  Color _feedbackColor = Colors.transparent;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardProvider = context.watch<BoardProvider>();

    return Positioned(
      left: widget.equalsElement.position.dx,
      top: widget.equalsElement.position.dy,
      child: DragTarget<MathElement>(
        onWillAcceptWithDetails: (details) {
          final element = details.data;
          final canCross = boardProvider.canCrossEqualsPortal(element);

          setState(() {
            _isHovering = true;
            _feedbackColor = boardProvider.getPortalFeedbackColor(element);
          });

          // Vibrar el elemento mientras está sobre el portal
          if (canCross) {
            boardProvider.setElementVibrating(element.id, true);
          }

          return canCross;
        },
        onLeave: (element) {
          setState(() {
            _isHovering = false;
            _feedbackColor = Colors.transparent;
          });

          if (element != null) {
            boardProvider.setElementVibrating(element.id, false);
          }
        },
        onAcceptWithDetails: (details) {
          final element = details.data;

          // Feedback háptico
          HapticFeedback.heavyImpact();

          // Acción válida: verde + animación
          setState(() {
            _feedbackColor = Colors.green;
          });

          _pulseController.forward().then((_) {
            _pulseController.reverse();
          });

          // Cruzar el portal (cambiar signo)
          boardProvider.crossEqualsPortal(element.id);
          boardProvider.setElementVibrating(element.id, false);

          // Limpiar feedback
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              setState(() {
                _isHovering = false;
                _feedbackColor = Colors.transparent;
              });
            }
          });
        },
        builder: (context, candidateData, rejectedData) {
          return ScaleTransition(
            scale: _pulseAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.portalWidth,
              height: widget.equalsElement.size,
              decoration: BoxDecoration(
                color: _isHovering
                    ? _feedbackColor.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                border: Border.all(
                  color: _isHovering ? _feedbackColor : Colors.black45,
                  width: _isHovering ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isHovering
                    ? [
                        BoxShadow(
                          color: _feedbackColor.withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.equalsElement.value.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isHovering ? _feedbackColor : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

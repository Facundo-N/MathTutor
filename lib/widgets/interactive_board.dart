// lib/widgets/interactive_board.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visual_style.dart';
import '../services/math_parser.dart';
import '../services/visual_style_provider.dart';
import 'math_expression_display.dart';

class InteractiveBoard extends StatefulWidget {
  final MathProblem problem;

  const InteractiveBoard({
    super.key,
    required this.problem,
  });

  @override
  State<InteractiveBoard> createState() => _InteractiveBoardState();
}

class _InteractiveBoardState extends State<InteractiveBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisualStyleProvider>(
      builder: (context, styleProvider, _) {
        final config = styleProvider.config;

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(config.spacing),
          decoration: BoxDecoration(
            color: config.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título del problema
                  Text(
                    "Problema detectado",
                    style: TextStyle(
                      fontSize: config.fontSize,
                      color: config.primaryColor,
                      fontWeight: config.fontWeight,
                      letterSpacing: config.letterSpacing,
                    ),
                  ),
                  SizedBox(height: config.spacing),

                  // Ecuación principal
                  FadeTransition(
                    opacity: _animController,
                    child: MathExpressionDisplay(
                      expression: widget.problem.expression,
                      config: config,
                    ),
                  ),

                  SizedBox(height: config.spacing * 2),

                  // Área para futuros pasos/interacción
                  if (_currentStep > 0) _buildStepIndicator(config),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(VisualStyleConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Paso $_currentStep de ${widget.problem.steps.length}",
        style: TextStyle(
          fontSize: config.fontSize * 0.9,
          color: config.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

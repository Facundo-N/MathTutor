// lib/widgets/animated_math_board.dart (NUEVO ARCHIVO COMPLETO)

import 'package:flutter/material.dart';

class AnimatedMathBoard extends StatefulWidget {
  final String operation;
  final List<String> steps;
  final Function(String)? onStepComplete;

  const AnimatedMathBoard({
    super.key,
    required this.operation,
    required this.steps,
    this.onStepComplete,
  });

  @override
  State<AnimatedMathBoard> createState() => _AnimatedMathBoardState();
}

class _AnimatedMathBoardState extends State<AnimatedMathBoard>
    with TickerProviderStateMixin {
  List<MathElement> elements = [];
  int currentStep = 0;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _parseOperation();
    _startAnimation();
  }

  void _parseOperation() {
    // Parsear "2 + 2" o "6 - 5" o "2x + 2 = 4"
    final operation = widget.operation.trim();

    // Detectar tipo de operación
    if (operation.contains('x') || operation.contains('X')) {
      _parseEquation(operation);
    } else {
      _parseArithmetic(operation);
    }
  }

  void _parseArithmetic(String operation) {
    // Ejemplo: "2 + 2" o "6 - 5"
    final regex = RegExp(r'(\d+)\s*([\+\-\*\/])\s*(\d+)');
    final match = regex.firstMatch(operation);

    if (match != null) {
      final num1 = match.group(1)!;
      final operator = match.group(2)!;
      final num2 = match.group(3)!;

      elements.add(
        MathElement(
          id: 'num1',
          value: num1,
          position: const Offset(80, 150),
          scale: 1.0,
          opacity: 1.0,
          color: const Color(0xFF6B5CE7),
        ),
      );

      elements.add(
        MathElement(
          id: 'operator',
          value: operator,
          position: const Offset(150, 150),
          scale: 1.0,
          opacity: 1.0,
          color: Colors.grey,
        ),
      );

      elements.add(
        MathElement(
          id: 'num2',
          value: num2,
          position: const Offset(220, 150),
          scale: 1.0,
          opacity: 1.0,
          color: const Color(0xFF8B7CE8),
        ),
      );
    }

    setState(() {});
  }

  void _parseEquation(String equation) {
    // Ejemplo: "2x + 2 = 4"
    // Separar por el signo igual
    final parts = equation.split('=');
    if (parts.length != 2) return;

    final leftSide = parts[0].trim();
    final rightSide = parts[1].trim();

    double xPos = 60;

    // Parsear lado izquierdo (2x + 2)
    final leftTokens = RegExp(r'(\d+[xX]|\d+|[+\-])').allMatches(leftSide);

    for (final token in leftTokens) {
      final value = token.group(0)!;

      elements.add(
        MathElement(
          id: 'left_$value',
          value: value,
          position: Offset(xPos, 150),
          scale: 1.0,
          opacity: 1.0,
          color: const Color(0xFF6B5CE7),
        ),
      );

      xPos += 50;
    }

    // Signo igual
    elements.add(
      MathElement(
        id: 'equals',
        value: '=',
        position: Offset(xPos + 10, 150),
        scale: 1.0,
        opacity: 1.0,
        color: Colors.grey,
      ),
    );

    xPos += 60;

    // Lado derecho
    elements.add(
      MathElement(
        id: 'right',
        value: rightSide,
        position: Offset(xPos, 150),
        scale: 1.0,
        opacity: 1.0,
        color: const Color(0xFF8B7CE8),
      ),
    );

    setState(() {});
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (widget.operation.contains('+')) {
      await _animateAddition();
    } else if (widget.operation.contains('-')) {
      await _animateSubtraction();
    } else if (widget.operation.contains('x') ||
        widget.operation.contains('X')) {
      await _animateEquationSolving();
    }
  }

  // ========== ANIMACIÓN DE SUMA ==========
  Future<void> _animateAddition() async {
    if (elements.length < 3) return;

    setState(() => isAnimating = true);

    // Paso 1: Los números se acercan
    final num1 = elements.firstWhere((e) => e.id == 'num1');
    final num2 = elements.firstWhere((e) => e.id == 'num2');
    final operator = elements.firstWhere((e) => e.id == 'operator');

    // Mover ambos números al centro
    await _animateElement(
      num1,
      newPosition: const Offset(130, 150),
      duration: 800,
    );

    await _animateElement(
      num2,
      newPosition: const Offset(170, 150),
      duration: 800,
    );

    // Paso 2: Hacer desaparecer el operador
    await _animateElement(
      operator,
      newOpacity: 0.0,
      newScale: 0.0,
      duration: 400,
    );

    // Paso 3: Los números "chocan" y se fusionan
    await Future.wait([
      _animateElement(
        num1,
        newPosition: const Offset(150, 150),
        newScale: 1.5,
        duration: 300,
      ),
      _animateElement(
        num2,
        newPosition: const Offset(150, 150),
        newScale: 1.5,
        duration: 300,
      ),
    ]);

    // Paso 4: Calcular resultado
    final result = int.parse(num1.value) + int.parse(num2.value);

    // Hacer desaparecer los números originales
    await Future.wait([
      _animateElement(num1, newOpacity: 0.0, newScale: 0.0, duration: 300),
      _animateElement(num2, newOpacity: 0.0, newScale: 0.0, duration: 300),
    ]);

    // Paso 5: Aparecer el resultado
    elements.add(
      MathElement(
        id: 'result',
        value: result.toString(),
        position: const Offset(150, 150),
        scale: 0.0,
        opacity: 0.0,
        color: Colors.green,
      ),
    );

    setState(() {});

    await Future.delayed(const Duration(milliseconds: 100));

    final resultElement = elements.firstWhere((e) => e.id == 'result');
    await _animateElement(
      resultElement,
      newScale: 1.5,
      newOpacity: 1.0,
      duration: 600,
    );

    widget.onStepComplete?.call('¡Resultado: $result! ✨');

    setState(() => isAnimating = false);
  }

  // ========== ANIMACIÓN DE RESTA ==========
  Future<void> _animateSubtraction() async {
    if (elements.length < 3) return;

    setState(() => isAnimating = true);

    final num1 = elements.firstWhere((e) => e.id == 'num1');
    final num2 = elements.firstWhere((e) => e.id == 'num2');
    final operator = elements.firstWhere((e) => e.id == 'operator');

    // Paso 1: El segundo número se acerca al primero
    await _animateElement(
      num2,
      newPosition: Offset(num1.position.dx + 40, num1.position.dy),
      duration: 800,
    );

    // Paso 2: El segundo número se "come" (desaparece)
    await _animateElement(num2, newScale: 0.0, newOpacity: 0.0, duration: 500);

    // Hacer desaparecer el operador
    await _animateElement(
      operator,
      newOpacity: 0.0,
      newScale: 0.0,
      duration: 300,
    );

    // Paso 3: Calcular resultado
    final result = int.parse(num1.value) - int.parse(num2.value);

    // Hacer pulsar el primer número mientras "digiere"
    await _animateElement(num1, newScale: 1.3, duration: 400);

    await _animateElement(num1, newScale: 1.0, duration: 400);

    // Paso 4: Transformar el primer número en el resultado
    await _animateElement(num1, newOpacity: 0.0, newScale: 0.5, duration: 300);

    elements.add(
      MathElement(
        id: 'result',
        value: result.toString(),
        position: num1.position,
        scale: 0.0,
        opacity: 0.0,
        color: Colors.green,
      ),
    );

    setState(() {});

    await Future.delayed(const Duration(milliseconds: 100));

    final resultElement = elements.firstWhere((e) => e.id == 'result');
    await _animateElement(
      resultElement,
      newScale: 1.5,
      newOpacity: 1.0,
      duration: 600,
    );

    widget.onStepComplete?.call('¡Resultado: $result! ✨');

    setState(() => isAnimating = false);
  }

  // ========== ANIMACIÓN DE ECUACIÓN ==========
  Future<void> _animateEquationSolving() async {
    setState(() => isAnimating = true);

    // Ejemplo: 2x + 2 = 4
    // Paso 1: Mover el "+2" al otro lado (cambia a "-2")

    final constantElement = elements.firstWhere(
      (e) => e.id.contains('left_2') && !e.id.contains('2x'),
      orElse: () => elements.first,
    );

    final equalsElement = elements.firstWhere((e) => e.id == 'equals');
    final rightElement = elements.firstWhere((e) => e.id == 'right');

    // Mover el "2" al otro lado
    await _animateElement(
      constantElement,
      newPosition: Offset(
        equalsElement.position.dx + 80,
        equalsElement.position.dy,
      ),
      duration: 1000,
    );

    // Cambiar el "+" a "-"
    final plusElement = elements.firstWhere(
      (e) => e.value == '+',
      orElse: () => elements.first,
    );

    if (plusElement.id != 'equals') {
      await _animateElement(plusElement, newOpacity: 0.0, duration: 300);

      elements.add(
        MathElement(
          id: 'minus',
          value: '-',
          position: Offset(
            rightElement.position.dx - 30,
            rightElement.position.dy,
          ),
          scale: 0.0,
          opacity: 0.0,
          color: Colors.orange,
        ),
      );

      setState(() {});

      final minusElement = elements.firstWhere((e) => e.id == 'minus');
      await _animateElement(
        minusElement,
        newScale: 1.0,
        newOpacity: 1.0,
        duration: 400,
      );
    }

    widget.onStepComplete?.call('¡Ecuación resuelta! ✨');

    setState(() => isAnimating = false);
  }

  // ========== FUNCIÓN AUXILIAR PARA ANIMAR ==========
  Future<void> _animateElement(
    MathElement element, {
    Offset? newPosition,
    double? newScale,
    double? newOpacity,
    int duration = 500,
  }) async {
    final controller = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );

    final positionTween = newPosition != null
        ? Tween<Offset>(begin: element.position, end: newPosition)
        : null;

    final scaleTween = newScale != null
        ? Tween<double>(begin: element.scale, end: newScale)
        : null;

    final opacityTween = newOpacity != null
        ? Tween<double>(begin: element.opacity, end: newOpacity)
        : null;

    controller.addListener(() {
      setState(() {
        if (positionTween != null) {
          element.position = positionTween.evaluate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
          );
        }
        if (scaleTween != null) {
          element.scale = scaleTween.evaluate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          );
        }
        if (opacityTween != null) {
          element.opacity = opacityTween.evaluate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }
      });
    });

    await controller.forward();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF6B5CE7).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF6B5CE7).withValues(alpha: 0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5CE7).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fondo con grid
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: GridPainter(),
          ),

          // Elementos animados
          ...elements.map((element) => _buildMathElement(element)),

          // Indicador de paso
          if (widget.steps.isNotEmpty && currentStep < widget.steps.length)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B5CE7).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.steps[currentStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMathElement(MathElement element) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: Opacity(
        opacity: element.opacity,
        child: Transform.scale(
          scale: element.scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [element.color, element.color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: element.color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              element.value,
              style: TextStyle(
                fontSize: element.value.length == 1 ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ========== CLASE MODELO ==========
class MathElement {
  final String id;
  String value;
  Offset position;
  double scale;
  double opacity;
  Color color;

  MathElement({
    required this.id,
    required this.value,
    required this.position,
    required this.scale,
    required this.opacity,
    required this.color,
  });
}

// ========== PAINTER DEL GRID ==========
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    // Línea horizontal central
    canvas.drawLine(
      Offset(20, size.height / 2),
      Offset(size.width - 20, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

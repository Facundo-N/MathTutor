import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:demo_33_v2/models/ai_exercise_model.dart';

class AcademiaNinjaTemplate extends StatefulWidget {
  final AIExercise exercise;
  final VoidCallback onStepCompleted;
  final VoidCallback onExerciseCompleted;
  final Function(int) onLivesChanged;

  const AcademiaNinjaTemplate({
    super.key,
    required this.exercise,
    required this.onStepCompleted,
    required this.onExerciseCompleted,
    required this.onLivesChanged,
  });

  @override
  State<AcademiaNinjaTemplate> createState() => _AcademiaNinjaTemplateState();
}

class _AcademiaNinjaTemplateState extends State<AcademiaNinjaTemplate>
    with TickerProviderStateMixin {
  int _currentLevelIdx = 0;
  int _currentStepIdx = 0;
  bool _isAnimating = false;
  String? _currentTargetId;

  // Pantallas: intro, tutorial, game
  String _currentScreen = 'intro'; // 'intro', 'tutorial', 'game', 'outro'

  // Sistema de corte
  final List<Offset> _trailData = [];
  Timer? _trailTimer;
  final Map<String, GlobalKey> _targetKeys = {};

  // Estado de bloques cortados (para animación de vuelo)
  final Map<String, bool> _cutBlocks = {}; // id -> isFlyingAway

  // Partículas y efectos visuales temporales
  final List<Widget> _effectWidgets = [];

  // Fondo animado
  final List<_Particle> _bgParticles = [];
  late Timer _bgTimer;
  final Random _random = Random();

  // Controladores de animación
  late AnimationController _cutFlashController;
  bool _showCutFlash = false;

  // Popup de respuesta
  String? _showPopupForTarget;
  int _mistakesCount = 0;

  @override
  void initState() {
    super.initState();
    _cutFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Inicializar fondo
    for (int i = 0; i < 20; i++) {
      _bgParticles.add(
        _Particle(
          symbol: ['+', '-', '×', '÷', '=', 'x', '√', 'x²'][_random.nextInt(8)],
          x: _random.nextDouble(),
          y: 1.0 + _random.nextDouble(),
          speed: 0.05 + _random.nextDouble() * 0.05,
          size: 20 + _random.nextDouble() * 40,
        ),
      );
    }
    _bgTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        for (var p in _bgParticles) {
          p.y -= p.speed * 0.05;
          p.rotation += p.speed;
          if (p.y < -0.2) {
            p.y = 1.2;
            p.x = _random.nextDouble();
          }
        }
      });
    });

    // Trail cleanup
    _trailTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      if (_trailData.length > 5) {
        setState(() {
          _trailData.removeAt(0);
        });
      }
    });

    _generateDynamicGameLevels();
    _initializeLevel();
  }

  void _generateDynamicGameLevels() {
    _gameLevels.clear();
    
    // Normalizar la ecuación al igual que en DestruirConSeleccion
    String eqStr = widget.exercise.equation;
    eqStr = eqStr
        .replaceAll('\u2212', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('÷', '/')
        .replaceAll('×', '*')
        .replaceAll(',', '.')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .trim();

    String normalizedEq = eqStr.replaceAll(' ', '');

    // Para la generación dinámica simplificada, vamos a usar un parser básico inspirado en DestruirConSeleccion
    // Por ahora, detectamos si es cuadrática, cúbica, lineal o distributiva

    final matchHigh = RegExp(
      r'^([+-]?\d*)([a-zA-Z]+)\^([23])([+-]\d+)?=(-?\d+)$',
    ).firstMatch(normalizedEq);

    if (matchHigh != null) {
      final int exp = matchHigh.group(3) == '3' ? 3 : 2;
      _generateDynamicLevelHard(normalizedEq, exp, matchHigh);
    } else {
       // Asumimos Lineal por fallback
       _generateDynamicLevelLineal(normalizedEq);
    }
    
    if (_gameLevels.isEmpty) {
      // Fallback por si todo falla
      _gameLevels.add({
        'tutorial': {
          'title': 'Completado',
          'theory': 'Ejercicio completado.'
        },
        'steps': [{'target': null, 'title': '¡Felicidades!', 'desc': 'Has concluido'}]
      });
    }
  }

  void _generateDynamicLevelHard(String normalizedEq, int exp, RegExpMatch match) {
    String aStr = match.group(1)!;
    final String literal = match.group(2)!;
    final String? opText = match.group(4);
    final String rightStr = match.group(5)!;

    if (aStr.isEmpty || aStr == '+') aStr = '1';
    if (aStr == '-') aStr = '-1';
    final double a = _parseNum(aStr);
    final bool hasOp = opText != null;
    final String op = hasOp ? opText.substring(0, 1) : '+';
    final double opVal = hasOp ? (_parseNum(opText.substring(1))) : 0.0;
    final double rightNum = _parseNum(rightStr);
    
    final double afterOp = hasOp ? (op == '+' ? rightNum - opVal : rightNum + opVal) : rightNum;
    final double underRoot = a != 0 ? (afterOp / a) : afterOp;
    // Compute root logic
    final double ans = exp == 3 
         ? (underRoot >= 0 ? pow(underRoot, 1/3).toDouble() : -pow(underRoot.abs(), 1/3).toDouble())
         : (underRoot >= 0 ? sqrt(underRoot) : 0.0);

    final List<Map<String, dynamic>> steps = [];
    double currentRight = rightNum;
    
    if (hasOp) {
      final String ansAfterOp = _formatNum(afterOp);
      steps.add({
        'target': 't-op',
        'title': 'Despejar el Término',
        'desc': 'Corta el $opText para moverlo al otro lado.',
        'options': [ansAfterOp, opText, _formatNum(rightNum), '0'],
        'correct': ansAfterOp,
        'boardBuilder': () => Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 _buildTermWithExp(literal, "$exp", expId: null),
                 const SizedBox(width: 12),
                 _buildCuttableBlock(opText, isGreen: true, id: "t-op", isTarget: _currentTargetId == "t-op"),
              ]
            ),
            _buildOp("="),
            _buildBlock(_formatNum(currentRight), isGreen: true),
          ]
        )
      });
      currentRight = afterOp;
    }

    if (a != 1.0) {
      final String opA = "÷ ${_formatNum(a)}";
      final String ansAfterDiv = _formatNum(underRoot);
      steps.add({
        'target': 't-a',
        'title': 'Despejar el Modificador',
        'desc': 'Corta el multiplicador para pasarlo dividiendo.',
        'options': [ansAfterDiv, opA, _formatNum(currentRight), _formatNum(a)],
        'correct': ansAfterDiv,
        'boardBuilder': () => Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            _buildCuttableBlock(aStr, isBlack: true, id: "t-a", isTarget: _currentTargetId == "t-a", isDivisor: true),
            _buildTermWithExp(literal, "$exp", expId: null),
            _buildOp("="),
            _buildBlock(_formatNum(currentRight), isGreen: true),
          ]
        )
      });
      currentRight = underRoot;
    }

    // Step to apply root
    final rootSym = exp == 3 ? '∛' : '√';
    final String exponentStr = "$exp";
    final String resultAns = exp == 3 ? _formatNum(ans) : '± ${_formatNum(ans)}';

    steps.add({
       'target': 't-exp',
       'title': 'Aplicar la Raíz',
       'desc': '¡Corta el exponente $exponentStr para mandarlo como Raíz!',
       'options': ['$rootSym${_formatNum(currentRight)}', '${_formatNum(currentRight)}/$exponentStr', '${_formatNum(currentRight*2)}', '${_formatNum(currentRight)}^$exponentStr'],
       'correct': '$rootSym${_formatNum(currentRight)}',
       'boardBuilder': () => Wrap(
         alignment: WrapAlignment.center,
         crossAxisAlignment: WrapCrossAlignment.center,
         spacing: 12,
         children: [
           _buildTermWithExp(literal, exponentStr, expId: "t-exp", targetGlow: _currentTargetId == "t-exp"),
           _buildOp("="),
           _buildBlock(_formatNum(currentRight), isGreen: true),
         ]
       )
    });
    
    // Step to solve root
    steps.add({
       'target': 't-root',
       'title': 'Resolver la Raíz',
       'desc': '¡Revienta la raíz de ${_formatNum(currentRight)}!',
       'options': [resultAns, _formatNum(ans), _formatNum(ans+1), _formatNum(ans*2)],
       'correct': resultAns,
       'boardBuilder': () => Wrap(
         alignment: WrapAlignment.center,
         crossAxisAlignment: WrapCrossAlignment.center,
         spacing: 12,
         children: [
            _buildBlock(literal, isBlack: true, id: "t-var"),
            _buildOp("="),
            _buildRadical(rootSym, _formatNum(currentRight), index: exp == 3 ? "3" : null, id: "t-root", targetGlow: _currentTargetId == "t-root"),
         ]
       )
    });

    // Final
    steps.add({
       'target': null,
       'title': exp == 3 ? '¡Dominio Tridimensional!' : '¡Doble Solución!',
       'desc': exp == 3 ? 'Has vencido el volumen cúbico.' : 'El signo ± cubre ambas posibilidades.',
       'boardBuilder': () => Wrap(
         alignment: WrapAlignment.center,
         crossAxisAlignment: WrapCrossAlignment.center,
         spacing: 12,
         children: [
           _buildBlock(literal, isBlack: true),
           _buildOp("="),
           _buildBlock(resultAns, isPurple: true),
         ]
       )
    });

    _gameLevels.add({
       'tutorial': {
         'title': exp == 3 ? 'Lección: El Poder Tridimensional' : 'Lección: Máquina del Tiempo (Cuadráticas)',
         'theory': exp == 3 ? 'Invoca a la mística Raíz Cúbica (∛).' : 'Corta el exponente "2". Verás cómo muta en una raíz mágica.',
       },
       'steps': steps,
    });
  }

  void _generateDynamicLevelLineal(String normalizedEq) {
    // Ejemplo rudimentario para lineal (similar logic)
    final matchLinear = RegExp(r'^([+-]?\d*)([a-zA-Z]+)([+-]\d+)?=(-?\d+)$').firstMatch(normalizedEq);
    if (matchLinear == null) return;
    
    String aStr = matchLinear.group(1)!;
    final String literal = matchLinear.group(2)!;
    final String? opText = matchLinear.group(3);
    final String rightStr = matchLinear.group(4)!;

    if (aStr.isEmpty || aStr == '+') aStr = '1';
    if (aStr == '-') aStr = '-1';
    final double a = _parseNum(aStr);
    final bool hasOp = opText != null;
    final String op = hasOp ? opText.substring(0, 1) : '+';
    final double opVal = hasOp ? (_parseNum(opText.substring(1))) : 0.0;
    final double rightNum = _parseNum(rightStr);

    final double afterOp = hasOp ? (op == '+' ? rightNum - opVal : rightNum + opVal) : rightNum;
    final double resFinal = a != 0 ? (afterOp / a) : afterOp;

    final List<Map<String, dynamic>> steps = [];
    double currentRight = rightNum;

    if (hasOp) {
      steps.add({
        'target': 't-op',
        'title': 'Despejar la Suma/Resta',
        'desc': '¡Corta el $opText para moverlo al otro lado!',
        'options': [_formatNum(afterOp), opText, _formatNum(rightNum), '0'],
        'correct': _formatNum(afterOp),
        'boardBuilder': () => Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 _buildBlock(a == 1.0 ? literal : "$aStr$literal", isBlack: true),
                 const SizedBox(width: 12),
                 _buildCuttableBlock(opText, isGreen: true, id: "t-op", isTarget: _currentTargetId == "t-op"),
              ]
            ),
            _buildOp("="),
            _buildBlock(_formatNum(currentRight), isGreen: true),
          ]
        )
      });
      currentRight = afterOp;
    }

    if (a != 1.0) {
      steps.add({
        'target': 't-a',
        'title': 'Despejar el Multiplicador',
        'desc': '¡Corta el $a para pasarlo dividiendo!',
        'options': [_formatNum(resFinal), '÷ ${_formatNum(a)}', _formatNum(currentRight * 2), '0'],
        'correct': _formatNum(resFinal),
        'boardBuilder': () => Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            _buildCuttableBlock(aStr, isBlack: true, id: "t-a", isTarget: _currentTargetId == "t-a", isDivisor: true),
            _buildBlock(literal, isBlack: true),
            _buildOp("="),
            _buildBlock(_formatNum(currentRight), isGreen: true),
          ]
        )
      });
      currentRight = resFinal;
    }

    steps.add({
       'target': null,
       'title': '¡Excelente!',
       'desc': 'Has dominado la balanza.',
       'boardBuilder': () => Wrap(
         alignment: WrapAlignment.center,
         crossAxisAlignment: WrapCrossAlignment.center,
         spacing: 12,
         children: [
           _buildBlock(literal, isBlack: true),
           _buildOp("="),
           _buildBlock(_formatNum(resFinal), isGreen: true),
         ]
       ).animate().shakeX()
    });

    _gameLevels.add({
       'tutorial': {
         'title': 'Lección: Ecuaciones Lineales',
         'theory': 'Usa tu espada para cortar primero los números que suman o restan. Al cortarlos, volarán al otro lado.',
       },
       'steps': steps,
    });
  }

  @override
  void dispose() {
    _bgTimer.cancel();
    _trailTimer?.cancel();
    _cutFlashController.dispose();
    super.dispose();
  }

  void _initializeLevel() {
    if (_currentLevelIdx >= _gameLevels.length) {
      _currentScreen = 'outro';
      return;
    }
    _targetKeys.clear();
    _cutBlocks.clear();
  }

  void _startTutorial() {
    setState(() {
      _currentScreen = 'tutorial';
    });
  }

  void _startGame() {
    setState(() {
      _currentStepIdx = 0;
      _cutBlocks.clear();
      _currentScreen = 'game';
      _currentTargetId =
          _gameLevels[_currentLevelIdx]['steps'][_currentStepIdx]['target'];
      _targetKeys.clear();
    });
  }

  void _handlePanStart(DragStartDetails details) {
    if (_currentScreen != 'game' || _isAnimating || _showPopupForTarget != null) {
      return;
    }
    setState(() {
      _trailData.clear();
      _trailData.add(details.localPosition);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_currentScreen != 'game' || _isAnimating || _showPopupForTarget != null) {
      return;
    }
    setState(() {
      _trailData.add(details.localPosition);
      if (_trailData.length > 20) {
        _trailData.removeAt(0);
      }
    });

    _checkCutValidation(details.localPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentScreen != 'game' || _isAnimating || _showPopupForTarget != null) {
      return;
    }
    setState(() {
      _trailData.clear();
    });
  }

  void _checkCutValidation(Offset point) {
    if (_isAnimating || _currentTargetId == null || _showPopupForTarget != null) {
      return;
    }
    final key = _targetKeys[_currentTargetId];
    if (key == null) return;

    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final rect = position & size;

      // Ampliar caja de colisión para celulares
      final hitRect = rect.inflate(20.0);

      if (hitRect.contains(point)) {
        _processCut(_currentTargetId!);
      }
    }
  }

  void _processCut(String targetId) async {
    if (_isAnimating || _showPopupForTarget != null) return;

    final steps = _gameLevels[_currentLevelIdx]['steps'] as List;
    final currentStepData = steps[_currentStepIdx];

    if (currentStepData.containsKey('options')) {
      setState(() {
        _showPopupForTarget = targetId;
        _mistakesCount = 0;
        _trailData.clear(); // Limpiar el trazo de la espada
      });
    } else {
      _executeFlightAnimation(targetId);
    }
  }

  void _executeFlightAnimation(String targetId) async {
    setState(() {
      _showPopupForTarget = null;
      _isAnimating = true;
      _cutBlocks[targetId] = true; // Marcar bloque como cortado (vuelo)
      _showCutFlash = true;
    });

    // Animación de flash del corte
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _showCutFlash = false);

    // Esperar animación de vuelo del bloque
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      setState(() {
        _isAnimating = false;
        _cutBlocks.clear();
        if (!_advanceStep()) {
          // Si advanceStep devuelve false, es porque ya completó el nivel
          _currentLevelIdx++;
          if (_currentLevelIdx >= _gameLevels.length) {
            _currentScreen = 'outro';
            widget.onExerciseCompleted();
          } else {
            _currentScreen = 'intro';
            _initializeLevel();
          }
          widget.onStepCompleted();
        }
      });
    }
  }

  bool _advanceStep() {
    final steps = _gameLevels[_currentLevelIdx]['steps'] as List;
    if (_currentStepIdx < steps.length - 1) {
      _currentStepIdx++;
      _currentTargetId = steps[_currentStepIdx]['target'];
      _targetKeys.clear();
      widget.onStepCompleted();
      return true; // Continuar en nivel
    }
    return false; // Nivel completado
  }

  double _parseNum(String s) {
    if (s.isEmpty || s == "+" || s == "-") return 1.0;
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  String _formatNum(double n) {
    if (n == n.toInt()) return n.toInt().toString();
    String s = n.toStringAsFixed(1);
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s.replaceAll('.', ',');
  }

  // ====== NIVELES DE JUEGO ======
  final List<Map<String, dynamic>> _gameLevels = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: Stack(
            children: [
              // Fondo animado
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF0a3a6b), Color(0xFF01142e)],
                      center: Alignment.center,
                      radius: 1.0,
                    ),
                  ),
                ),
              ),
              ..._bgParticles.map(
                (p) => Positioned(
                  left: p.x * MediaQuery.of(context).size.width,
                  top: p.y * MediaQuery.of(context).size.height,
                  child: Transform.rotate(
                    angle: p.rotation,
                    child: Text(
                      p.symbol,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.05),
                        fontSize: p.size,
                        fontWeight: ui.FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),

              // UI Principal
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCurrentScreen(),
                ),
              ),

              // Capa de efectos temporales (Cortes, Partículas, etc.)
              ..._effectWidgets,

              // Popup de respuestas
              if (_showPopupForTarget != null) _buildPopupOverlay(),

              // Flash de corte
              if (_showCutFlash)
                IgnorePointer(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.15),
                  ).animate().fadeOut(duration: 200.ms),
                ),

              // Trail de la espada katana
              if (_currentScreen == 'game')
                IgnorePointer(
                  child: CustomPaint(
                    painter: _TrailPainter(trail: _trailData),
                    child: Container(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'intro':
        final tut = _gameLevels[_currentLevelIdx]['tutorial'];
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ACADEMIA NINJA',
                style: TextStyle(
                  color: Color(0xFF4ade80),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Color(0x804ade80), blurRadius: 20)],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tut['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Aprenderás no solo CÓMO resolver ecuaciones, sino el PORQUÉ de cada movimiento.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 18),
                ),
              ),
              const SizedBox(height: 40),
              _buildModernButton("Comenzar Lección", _startTutorial),
            ],
          ),
        );
      case 'tutorial':
        final tut = _gameLevels[_currentLevelIdx]['tutorial'];
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4ade80), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x334ade80), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tut['title'],
                  style: const TextStyle(
                    color: Color(0xFF4ade80),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  tut['theory'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                // Visual de corte para tutorial — línea de corte ENCIMA del bloque verde
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF01142e),
                    border: Border.all(
                      color: const Color(0xFF4ade80),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Instrucción de gesto
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '← DESLIZA AQUÍ →',
                          style: TextStyle(
                            color: Color(0xFF4ade80),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBlock("x", isBlack: true),
                          const SizedBox(width: 8),
                          // Bloque +4 con la línea de corte ENCIMA
                          Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              _buildBlock("+4", isGreen: true),
                              // Línea de corte posicionada arriba del bloque
                              Positioned(
                                top: -2,
                                child:
                                    Container(
                                          width: 80,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0xCC4ade80),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          transform: Matrix4.rotationZ(-0.2),
                                        )
                                        .animate(
                                          onPlay: (ctrl) => ctrl.repeat(),
                                        )
                                        .move(
                                          begin: const Offset(-80, 0),
                                          end: const Offset(80, 0),
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
                                        )
                                        .fadeOut(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                        ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '=',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildBlock("10", isGreen: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Flecha indicando bloque yendo al otro lado
                      const Text(
                        '✂️ Al cortar → ¡vuela al otro lado!',
                        style: TextStyle(
                          color: Color(0xFFcbd5e1),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildModernButton("¡Al Ejercicio!", _startGame),
              ],
            ),
          ),
        );
      case 'game':
        final step = _gameLevels[_currentLevelIdx]['steps'][_currentStepIdx];
        return Column(
          children: [
            // UI Barra superior interactiva
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Text(
                    step['title'],
                    style: const TextStyle(
                      color: Color(0xFF4ade80),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step['desc'],
                    style: const TextStyle(
                      color: Color(0xFFe2e8f0),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEquationBoard(_currentLevelIdx, _currentStepIdx),
                    if (_currentTargetId == null) ...[
                      const SizedBox(height: 40),
                      _buildModernButton("Siguiente", () {
                        setState(() {
                          _currentLevelIdx++;
                          if (_currentLevelIdx >= _gameLevels.length) {
                            _currentScreen = 'outro';
                            widget.onExerciseCompleted();
                          } else {
                            _currentScreen = 'intro';
                            _initializeLevel();
                          }
                          widget.onStepCompleted();
                        });
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      case 'outro':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¡ERES UN MAESTRO NINJA!',
                style: TextStyle(
                  color: Color(0xFF4ade80),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0x804ade80), blurRadius: 20)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Has dominado las Ecuaciones y la Factorización.\nLas matemáticas se rinden ante tu espada.",
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              // Botón eliminado: el EquationLabWidget mostrará la barra global
               const SizedBox(height: 80), // Espacio para que no choque con la barra global
            ],
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildPopupOverlay() {
    final steps = _gameLevels[_currentLevelIdx]['steps'] as List;
    final currentStepData = steps[_currentStepIdx];
    final List<String> options = List<String>.from(
      currentStepData['options'] ?? [],
    );
    final String correct = currentStepData['correct'] ?? '';

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF01142e),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4ade80), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x334ade80), blurRadius: 30),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Rellena la respuesta correcta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () {
                        setState(() {
                          _showPopupForTarget = null;
                          _mistakesCount = 0;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...options.map((opt) {
                  final isCorrect = opt == correct;

                  Widget button = GestureDetector(
                    onTap: () {
                      if (isCorrect) {
                        _executeFlightAnimation(_showPopupForTarget!);
                      } else {
                        setState(() {
                          _mistakesCount++;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1e24),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFF2a2e34),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );

                  if (isCorrect && _mistakesCount >= 3) {
                    button = button
                        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                        .shimmer(
                          duration: 800.ms,
                          color: const Color(0xFF4ade80),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.05, 1.05),
                        );
                  }

                  return button;
                }),
              ],
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ),
      ),
    );
  }

  // ====== METODOS PARA EL TABLERO ======
  Widget _buildEquationBoard(int lvl, int step) {
    if (lvl >= _gameLevels.length) return const SizedBox();
    final steps = _gameLevels[lvl]['steps'] as List;
    if (step >= steps.length) return const SizedBox();
    
    final stepData = steps[step];
    if (stepData.containsKey('boardBuilder')) {
      final builder = stepData['boardBuilder'] as Widget Function();
      return builder();
    }
    return const SizedBox();
  }

  // ====== BLOQUE CORTABLE CON ANIMACIÓN ======
  /// Versión mejorada de bloque que implementa:
  /// - Glow pulsante cuando es objetivo
  /// - Animación de vuelo lateral al ser cortado
  /// - Agrandamiento adicional para divisores
  Widget _buildCuttableBlock(
    String text, {
    bool isBlack = false,
    bool isGreen = false,
    bool isRed = false,
    bool isPurple = false,
    required String id,
    bool isTarget = false,
    bool isDivisor = false,
  }) {
    final key = GlobalKey();
    _targetKeys[id] = key;

    Color bg = const Color(0xFF1a1e24);
    Color border = const Color(0xFF2a2e34);
    Color glowColor = const Color(0xFF4ade80);

    if (isGreen) {
      bg = const Color(0xFF228b37);
      border = const Color(0xFF32a84a);
      glowColor = const Color(0xFF4ade80);
    } else if (isRed) {
      bg = const Color(0xFFb91c1c);
      border = const Color(0xFFef4444);
      glowColor = const Color(0xFFef4444);
    } else if (isPurple) {
      bg = const Color(0xFF6d28d9);
      border = const Color(0xFF8b5cf6);
      glowColor = const Color(0xFF8b5cf6);
    }

    final isCut = _cutBlocks[id] == true;

    Widget block = Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isDivisor && isTarget ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border, width: 2),
        boxShadow: [
          BoxShadow(
            color: isTarget ? glowColor.withValues(alpha: 0.6) : Colors.black45,
            blurRadius: isTarget ? 20 : 10,
            offset: const Offset(0, 6),
            spreadRadius: isTarget ? 2 : 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: isDivisor && isTarget
              ? 36
              : 32, // Agrandado para divisores objetivo
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (isCut) {
      // Animación de vuelo lateral al ser cortado (deslizamiento hacia el otro lado)
      block = block
          .animate()
          .moveX(
            begin: 0,
            end: isDivisor
                ? 150
                : -150, // Divisores van a la derecha, numeros a la izq
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
          )
          .fadeOut(duration: const Duration(milliseconds: 400))
          .scaleXY(
            begin: 1.0,
            end: 0.6,
            duration: const Duration(milliseconds: 500),
          );
    } else if (isTarget) {
      // Pulsación del bloque objetivo + agrandamiento progresivo
      block = block
          .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.08, 1.08),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          )
          .shimmer(
            color: glowColor.withValues(alpha: 0.5),
            duration: const Duration(milliseconds: 700),
          );
    } else {
      block = block.animate().scale(
        curve: Curves.easeOutBack,
        duration: const Duration(milliseconds: 400),
      );
    }

    return block;
  }

  // ====== AYUDANTES DE UI ======
  Widget _buildModernButton(String text, VoidCallback onPressed) {
    return GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF228b37), Color(0xFF4ade80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF228b37).withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: const Duration(seconds: 1),
        );
  }

  Widget _buildOp(String op, {String? id, bool targetGlow = false}) {
    Widget child = Text(
      op,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w900,
      ),
    );

    if (id != null) {
      final key = GlobalKey();
      _targetKeys[id] = key;
      child = Container(key: key, child: child);
    }

    if (targetGlow) {
      child = child
          .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
          .shimmer(
            duration: const Duration(milliseconds: 800),
            color: Colors.white,
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: const Duration(milliseconds: 700),
          );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: child,
    );
  }

  Widget _buildTermWithExp(
    String baseStr,
    String expStr, {
    String? id,
    String? expId,
    bool targetGlow = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildBlock(baseStr, isBlack: true, id: id),
        Positioned(
          right: -10,
          top: -15,
          child: _buildExp(expStr, id: expId, targetGlow: targetGlow),
        ),
      ],
    );
  }

  Widget _buildExp(String exp, {String? id, bool targetGlow = false}) {
    final key = GlobalKey();
    if (id != null) {
      _targetKeys[id] = key;
    }

    final isCut = id != null && _cutBlocks[id] == true;

    Widget block = Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFb91c1c), width: 2),
        boxShadow: [
          BoxShadow(
            color: targetGlow
                ? const Color(0xFFef4444).withValues(alpha: 0.6)
                : Colors.black45,
            blurRadius: targetGlow ? 16 : 8,
            offset: const Offset(0, 4),
            spreadRadius: targetGlow ? 2 : 0,
          ),
        ],
      ),
      child: Text(
        exp,
        style: TextStyle(
          color: Colors.white,
          fontSize: targetGlow ? 22 : 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    if (isCut) {
      block = block
          .animate()
          .moveY(
            begin: 0,
            end: 80,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
          )
          .fadeOut(duration: const Duration(milliseconds: 400));
    } else if (targetGlow) {
      block = block
          .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: const Duration(milliseconds: 700),
          )
          .shimmer(color: Colors.white54);
    }

    return block;
  }

  Widget _buildRadical(
    String sign,
    String inside, {
    String? index,
    String? id,
    bool targetGlow = false,
  }) {
    final key = GlobalKey();
    if (id != null) {
      _targetKeys[id] = key;
    }

    final isCut = id != null && _cutBlocks[id] == true;

    Widget block = Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6d28d9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF8b5cf6), width: 2),
        boxShadow: [
          BoxShadow(
            color: targetGlow
                ? const Color(0xFF8b5cf6).withValues(alpha: 0.6)
                : Colors.black45,
            blurRadius: targetGlow ? 16 : 8,
            offset: const Offset(0, 4),
            spreadRadius: targetGlow ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                index,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            sign,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.normal,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white, width: 3)),
            ),
            child: Text(
              inside,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (isCut) {
      block = block
          .animate()
          .moveX(
            begin: 0,
            end: -150,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
          )
          .fadeOut(duration: const Duration(milliseconds: 400));
    } else if (targetGlow) {
      block = block
          .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: const Duration(milliseconds: 800),
          )
          .shimmer(color: const Color(0xFFc084fc));
    }

    return block;
  }

  Widget _buildBlock(
    String text, {
    bool isBlack = false,
    bool isGreen = false,
    bool isRed = false,
    bool isPurple = false,
    String? id,
    bool targetGlow = false,
  }) {
    Color bg = const Color(0xFF1a1e24);
    Color border = const Color(0xFF2a2e34);

    if (isGreen) {
      bg = const Color(0xFF228b37);
      border = const Color(0xFF32a84a);
    } else if (isRed) {
      bg = const Color(0xFFb91c1c);
      border = const Color(0xFFef4444);
    } else if (isPurple) {
      bg = const Color(0xFF6d28d9);
      border = const Color(0xFF8b5cf6);
    }

    final key = GlobalKey();
    if (id != null) {
      _targetKeys[id] = key;
    }

    Widget block =
        Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: border, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ).animate().scale(
          curve: Curves.easeOutBack,
          duration: const Duration(milliseconds: 400),
        );

    if (targetGlow) {
      block =
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Color(0x804ade80), blurRadius: 20),
                  ],
                ),
                child: block,
              )
              .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: const Duration(milliseconds: 1000),
              );
    }

    return block;
  }
}

// Custom Painter para la espada Ninja Trail
class _TrailPainter extends CustomPainter {
  final List<Offset> trail;

  _TrailPainter({required this.trail});

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.length < 2) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF4ade80).withValues(alpha: 0.6)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0);

    final path = Path();
    path.moveTo(trail.first.dx, trail.first.dy);

    for (int i = 1; i < trail.length - 1; i++) {
      final p0 = trail[i];
      final p1 = trail[i + 1];
      path.quadraticBezierTo(
        p0.dx,
        p0.dy,
        (p0.dx + p1.dx) / 2,
        (p0.dy + p1.dy) / 2,
      );
    }
    path.lineTo(trail.last.dx, trail.last.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) {
    return true;
  }
}

class _Particle {
  String symbol;
  double x;
  double y;
  double speed;
  double size;
  double rotation = 0;

  _Particle({
    required this.symbol,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}


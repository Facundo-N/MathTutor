import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../equation_lab.dart';
import '../../models/ai_exercise_model.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _FloatingSymbol {
  String char;
  double x, y;
  double speed;
  double size;
  double rot;
  double rotSpeed;
  _FloatingSymbol({
    required this.char,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.rot,
    required this.rotSpeed,
  });
}

class _Particle {
  double x, y, vx, vy, life, size, rot, rotSpeed;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
    required this.rot,
    required this.rotSpeed,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  MAIN WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class DestructorEcuacionesTemplate extends StatefulWidget {
  final AIExercise exercise;
  final VoidCallback onStepCompleted;
  final VoidCallback onExerciseCompleted;
  final Function(int) onLivesChanged;

  const DestructorEcuacionesTemplate({
    super.key,
    required this.exercise,
    required this.onStepCompleted,
    required this.onExerciseCompleted,
    required this.onLivesChanged,
  });

  @override
  _DestructorEcuacionesTemplateState createState() =>
      _DestructorEcuacionesTemplateState();
}

// ══════════════════════════════════════════════════════════════════════════════
//  STATE
// ══════════════════════════════════════════════════════════════════════════════

class _DestructorEcuacionesTemplateState
    extends State<DestructorEcuacionesTemplate>
    with TickerProviderStateMixin {
  // ── Lives & Shake ────────────────────────────────────────────────────────
  int _lives = 3;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // ── Zone pulse / float-hint ──────────────────────────────────────────────
  late AnimationController _zoneShakeController;
  late AnimationController _floatTextController;

  // ── Equation pieces ──────────────────────────────────────────────────────
  List<EquationLabPiece> _leftPieces = [];
  List<EquationLabPiece> _rightPieces = [];

  // ── Drag / equals-cross state ────────────────────────────────────────────
  bool _isHoveringRight = false;
  bool _isEqualsCrossed = false;
  bool _waitingForCrush = false;

  // ── Orb overlay ──────────────────────────────────────────────────────────
  bool _isAnimatingShatter = false;
  List<int> _orbOptions = [];

  // ── Particles & Background ───────────────────────────────────────────────
  final List<_FloatingSymbol> _bgSymbols = [];
  final List<_Particle> _particles = [];
  late Ticker _ticker;
  final Random _rnd = Random();

  // ── Alert ────────────────────────────────────────────────────────────────
  bool _gameStarted = false;
  String _alertText = '';
  Color _alertColor = Colors.transparent;
  bool _showAlert = false;

  // ══════════════════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();

    // ── Screen-shake controller ──────────────────────────────────────────
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // ── Zone continuous shake (while waiting to crush) ────────────────────
    _zoneShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..repeat(reverse: true);

    // ── Floating hint text ────────────────────────────────────────────────
    _floatTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // ── Floating background math symbols ─────────────────────────────────
    const chars = ['+', '-', '×', '÷', '=', 'x', 'y', 'z', 'π', 'θ', '√', '∫'];
    for (int i = 0; i < 25; i++) {
      _bgSymbols.add(
        _FloatingSymbol(
          char: chars[_rnd.nextInt(chars.length)],
          x: _rnd.nextDouble(),
          y: _rnd.nextDouble(),
          speed: _rnd.nextDouble() * 0.4 + 0.1,
          size: _rnd.nextDouble() * 20 + 16,
          rot: _rnd.nextDouble() * 2 * pi,
          rotSpeed: (_rnd.nextDouble() - 0.5) * 0.02,
        ),
      );
    }

    _ticker = createTicker(_onTick)..start();
    _initializeEquation();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shakeController.dispose();
    _zoneShakeController.dispose();
    _floatTextController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TICK — updates particles + background
  // ══════════════════════════════════════════════════════════════════════════

  void _onTick(Duration elapsed) {
    setState(() {
      for (var s in _bgSymbols) {
        s.y -= s.speed * 0.01;
        s.rot += s.rotSpeed;
        if (s.y < -0.1) {
          s.y = 1.1;
          s.x = _rnd.nextDouble();
        }
      }
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.rot += p.rotSpeed;
        p.life -= 0.022;
        p.size *= 0.93;
        if (p.life <= 0) _particles.removeAt(i);
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PARTICLE EXPLOSION
  // ══════════════════════════════════════════════════════════════════════════

  /// Feature 3 – triggerExplosion
  void _createExplosion(Offset pos, Color color, {int count = 30}) {
    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          x: pos.dx,
          y: pos.dy,
          vx: (_rnd.nextDouble() - 0.5) * 20,
          vy: (_rnd.nextDouble() - 0.5) * 20,
          life: 1.0,
          color: color,
          size: _rnd.nextDouble() * 10 + 4,
          rot: _rnd.nextDouble() * 2 * pi,
          rotSpeed: (_rnd.nextDouble() - 0.5) * 0.5,
        ),
      );
    }
  }

  /// Feature 3 – screen shake on failure
  void _triggerShake() {
    _shakeController.forward(from: 0.0).then((_) => _shakeController.reset());
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ALERTS
  // ══════════════════════════════════════════════════════════════════════════

  void _showHtmlAlert(String text, Color color) {
    setState(() {
      _alertText = text;
      _alertColor = color;
      _showAlert = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showAlert = false);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  EQUATION INITIALISATION
  // ══════════════════════════════════════════════════════════════════════════

  String _gameMode = 'linear';
  int _valA = 1, _valB = 0, _valC = 0, _valA1 = 1, _valA2 = 1, _exp = 1;
  bool _isAdd = true;

  void _initializeEquation() {
    _gameMode = widget.exercise.exerciseType.replaceAll('destructor_', '');
    if (_gameMode == 'ecuaciones') _gameMode = 'linear';

    String raw = widget.exercise.equation.replaceAll(' ', '');
    // Regex parsing based on game mode
    if (_gameMode == 'distributive') {
      final m = RegExp(r'^(\d+)\(x([+-])(\d+)\)=(\d+)$').firstMatch(raw);
      if (m != null) {
        _valA = int.parse(m.group(1)!);
        _isAdd = m.group(2) == '+';
        _valB = int.parse(m.group(3)!);
        _valC = int.parse(m.group(4)!);
      }
    } else if (_gameMode == 'factorization' || _gameMode == 'combine') {
      final m = RegExp(r'^([+-]?\d*)x([+-]\d+)x=(.*)$').firstMatch(raw);
      if (m != null) {
        String a1Str = m.group(1)!;
        if (a1Str == "" || a1Str == "+") a1Str = "1";
        if (a1Str == "-") a1Str = "-1";
        _valA1 = int.parse(a1Str);

        String a2Sign = m.group(2)!.substring(0, 1);
        _isAdd = a2Sign == '+';
        _valA2 = int.parse(m.group(2)!.substring(1));
        _valC = int.tryParse(m.group(3)!) ?? 0;
        _gameMode = 'combine'; // Force name to match html
      } else {
        _gameMode = 'linear'; // Fallback
      }
    } else if (_gameMode == 'quadratic' ||
        _gameMode == 'cubic' ||
        _gameMode == 'poly' ||
        raw.contains('^2') ||
        raw.contains('^3') ||
        raw.contains('²') ||
        raw.contains('³')) {
      final m = RegExp(
        r'^([+-]?\d*)x(?:\^?([23])|([²³]))([+-]\d+)?=(.*)$',
      ).firstMatch(raw);
      if (m != null) {
        String aStr = m.group(1)!;
        if (aStr == "" || aStr == "+") aStr = "1";
        if (aStr == "-") aStr = "-1";
        _valA = int.parse(aStr);

        final expGroup2 = m.group(2);
        final expGroup3 = m.group(3);

        if (expGroup2 == '2' || expGroup3 == '²') {
          _exp = 2;
        } else {
          _exp = 3;
        }

        final bStr = m.group(4);
        if (bStr != null && bStr.isNotEmpty) {
          _isAdd = bStr.startsWith('+');
          _valB = int.parse(bStr.substring(1));
        } else {
          _valB = 0;
          _isAdd = true;
        }
        _valC = int.tryParse(m.group(5)!) ?? 0;
      }
    } else {
      // Linear - improved to handle various formats
      final m = RegExp(r'^([+-]?\d*)x([+-]\d+)?=(.*)$').firstMatch(raw);
      if (m != null) {
        String aStr = m.group(1)!;
        if (aStr == "" || aStr == "+") aStr = "1";
        if (aStr == "-") aStr = "-1";
        _valA = int.parse(aStr);

        final bStr = m.group(2);
        if (bStr != null && bStr.isNotEmpty) {
          _isAdd = bStr.startsWith('+');
          _valB = int.parse(bStr.substring(1));
        } else {
          _valB = 0;
          _isAdd = true;
        }
        _valC = int.tryParse(m.group(3)!) ?? 0;
      }
      if (_valA > 1 && _valB == 0) _gameMode = 'linear_coeff';
    }

    _buildInitialPieces();
  }

  void _buildInitialPieces() {
    setState(() {
      _leftPieces.clear();
      _rightPieces.clear();

      String op = _isAdd ? '+' : '-';

      // -- RIGHT SIDE --
      _rightPieces = [
        EquationLabPiece(
          id: 'right_result',
          type: 'number_with_sign',
          text: _valC.toString(),
          side: 'right',
          order: 1,
          draggable: false,
        ),
      ];

      // -- LEFT SIDE --
      if (_gameMode == 'distributive') {
        _leftPieces.add(
          EquationLabPiece(
            id: 'coeff',
            type: 'coeff',
            text: '$_valA',
            side: 'left',
            draggable: true,
            order: 1,
          ),
        );
        _leftPieces.add(
          EquationLabPiece(
            id: 'locked_group',
            type: 'locked_group',
            text: '(x$op$_valB)',
            side: 'left',
            draggable: false,
            order: 2,
          ),
        );
      } else if (_gameMode == 'combine') {
        _leftPieces.add(
          EquationLabPiece(
            id: 'term1',
            type: 'xTerm',
            text: '${_valA1}x',
            side: 'left',
            draggable: true,
            order: 1,
          ),
        );
        _leftPieces.add(
          EquationLabPiece(
            id: 'term2',
            type: 'xTerm',
            text: '$op${_valA2}x',
            side: 'left',
            draggable: true,
            order: 2,
          ),
        );
      } else {
        // Linear, quad, cubic, linear_coeff
        if (_valA > 1) {
          _leftPieces.add(
            EquationLabPiece(
              id: 'coeff',
              type: 'coeff',
              text: '$_valA',
              side: 'left',
              draggable: true,
              order: 1,
            ),
          );
        }
        _leftPieces.add(
          EquationLabPiece(
            id: 'var',
            type: 'term',
            text: 'x',
            side: 'left',
            draggable: false,
            order: 2,
          ),
        );
        if (_exp > 1) {
          _leftPieces.add(
            EquationLabPiece(
              id: 'exp',
              type: 'exp',
              text: _exp == 2 ? '²' : '³',
              side: 'left',
              draggable: true,
              order: 3,
            ),
          );
        }
        if (_valB > 0) {
          _leftPieces.add(
            EquationLabPiece(
              id: 'term_b',
              type: 'number_with_sign',
              text: '$op $_valB',
              side: 'left',
              draggable: true,
              order: 4,
            ),
          );
        }
      }
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ORB LOGIC
  // ══════════════════════════════════════════════════════════════════════════

  String _currentOrbMode = '';

  void _showOrbsOptions() {
    int answer = 0;
    Set<int> fakeSet = {};

    if (_currentOrbMode == 'combine') {
      int v2 = _isAdd ? _valA2 : -_valA2;
      answer = _valA1 + v2;
      fakeSet.add(_valA1 - v2);
      fakeSet.add(_valA1 * v2);
      fakeSet.add(answer + 1);
    } else if (_currentOrbMode == 'distributive') {
      answer = _valA * _valB;
      fakeSet.add(_valA + _valB);
      fakeSet.add(_valA * -_valB);
      fakeSet.add(answer + _valA);
    } else if (_currentOrbMode == 'root') {
      if (_rightPieces.isEmpty) return;
      final baseVal = int.tryParse(_rightPieces[0].text) ?? 0;
      if (_gameMode == 'quadratic') {
        answer = sqrt(baseVal).round();
        fakeSet.add(baseVal ~/ 2);
        fakeSet.add(baseVal - 2);
      } else if (_gameMode == 'cubic') {
        answer = pow(baseVal, 1 / 3).round();
        fakeSet.add(baseVal ~/ 3);
        fakeSet.add(baseVal - 3);
      }
      fakeSet.add(answer * answer);
    } else if (_currentOrbMode == 'division') {
      if (_rightPieces.length < 2) return;
      final baseVal = int.tryParse(_rightPieces[0].text) ?? 0;
      final modVal =
          int.tryParse(_rightPieces[1].text.replaceAll('÷', '').trim()) ??
          _valA;
      if (modVal != 0) {
        answer = baseVal ~/ modVal;
        fakeSet.add(baseVal * modVal);
        fakeSet.add(baseVal - modVal);
        fakeSet.add(modVal - baseVal);
      }
    } else {
      // Linear Add/Sub (_currentOrbMode == 'linear')
      if (_rightPieces.length < 2) return;
      final baseVal = int.tryParse(_rightPieces[0].text) ?? 0;
      final modText = _rightPieces[1].text;
      final modVal =
          int.tryParse(
            modText.replaceAll('+', '').replaceAll('-', '').trim(),
          ) ??
          0;
      if (modText.startsWith('-')) {
        answer = baseVal - modVal;
        fakeSet.add(baseVal + modVal);
      } else {
        answer = baseVal + modVal;
        fakeSet.add(baseVal - modVal);
      }
      fakeSet.add(baseVal * modVal);
      fakeSet.add(modVal - baseVal);
    }

    List<int> options = [answer];
    List<int> possibleFakes = fakeSet.where((f) => f != answer).toList();
    possibleFakes.shuffle(_rnd);

    for (int fake in possibleFakes) {
      if (options.length < 3) {
        options.add(fake);
      } else {
        break;
      }
    }

    int attempts = 0;
    while (options.length < 3 && attempts < 50) {
      attempts++;
      final fake = answer + (_rnd.nextInt(10) - 4);
      if (!options.contains(fake)) options.add(fake);
    }

    int fallback = 1;
    while (options.length < 3) {
      if (!options.contains(fallback)) options.add(fallback);
      fallback++;
    }
    options.shuffle();

    setState(() {
      _orbOptions = options;
      _isAnimatingShatter = true;
      _waitingForCrush = false;
    });
  }

  void _verifyShatter(int selected, int correct) {
    if (selected == correct) {
      _showHtmlAlert('¡DESTRUCCIÓN ÉPICA!', const Color(0xFF4ade80));
      final box = context.findRenderObject() as RenderBox;
      _createExplosion(
        Offset(box.size.width / 2, box.size.height / 2),
        const Color(0xFF4ade80),
        count: 40,
      );
      _createExplosion(
        Offset(box.size.width * 0.3, box.size.height / 2),
        const Color(0xFF22d3ee),
        count: 20,
      );
      setState(() {
        if (_currentOrbMode == 'combine') {
          _leftPieces.clear();
          _leftPieces.add(
            EquationLabPiece(
              id: 'coeff',
              type: 'coeff',
              text: '$correct',
              side: 'left',
              draggable: true,
              order: 1,
            ),
          );
          _leftPieces.add(
            EquationLabPiece(
              id: 'var',
              type: 'term',
              text: 'x',
              side: 'left',
              draggable: false,
              order: 2,
            ),
          );
          _valA = correct;
          _gameMode = _valA == 1 ? 'linear' : 'linear_coeff';
        } else if (_currentOrbMode == 'distributive') {
          _leftPieces.clear();
          _leftPieces.add(
            EquationLabPiece(
              id: 'coeff',
              type: 'coeff',
              text: '$_valA',
              side: 'left',
              draggable: true,
              order: 1,
            ),
          );
          _leftPieces.add(
            EquationLabPiece(
              id: 'var',
              type: 'term',
              text: 'x',
              side: 'left',
              draggable: false,
              order: 2,
            ),
          );
          String op = _isAdd ? '+' : '-';
          _leftPieces.add(
            EquationLabPiece(
              id: 'term_b',
              type: 'number_with_sign',
              text: '$op $correct',
              side: 'left',
              draggable: true,
              order: 3,
            ),
          );
          _gameMode = 'linear'; // Now it acts like a linear equation
          _valB = correct;
        } else {
          _rightPieces.clear();
          _rightPieces.add(
            EquationLabPiece(
              id: 'merged_val',
              type: 'number_with_sign',
              text: correct.toString(),
              side: 'right',
              draggable: false,
            ),
          );
          if (_currentOrbMode == 'root') {
            _gameMode = 'linear';
          }
        }
        _isAnimatingShatter = false;
      });

      // Check Win Condition
      if (_gameMode == 'linear' &&
          _leftPieces.length == 1 &&
          _leftPieces.first.type == 'term' &&
          _rightPieces.length == 1) {
        Future.delayed(const Duration(milliseconds: 900), () {
          widget.onExerciseCompleted();
        });
      }
    } else {
      _triggerShake();
      _showHtmlAlert(
        '¡CÁLCULO CRÍTICO! Intenta de nuevo.',
        const Color(0xFFef4444),
      );
      final box = context.findRenderObject() as RenderBox;
      _createExplosion(
        Offset(box.size.width / 2, box.size.height * 0.8),
        const Color(0xFFef4444),
        count: 25,
      );
      setState(() {
        _lives--;
        _isAnimatingShatter = false;
        // ── BUG FIX: Reset orb state so the user can re-tap and try again ──
        _orbOptions = [];
        _waitingForCrush = true; // put zone back to "tap to retry" state
      });
      widget.onLivesChanged(_lives);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final double offset = sin(_shakeAnimation.value * pi * 4) * 8;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF0b1120),
          body: Stack(
            children: [
              // Layer 0 – Background
              _buildBackground(),

              // Layer 1 – InteractiveViewer game board
              InteractiveViewer(
                boundaryMargin: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width,
                ),
                minScale: 0.1,
                maxScale: 4.0,
                child: Stack(
                  children: [
                    // Particle canvas
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ParticlesPainter(_particles),
                        ),
                      ),
                    ),
                    // Main board
                    _buildBoard(),
                  ],
                ),
              ),

              // Layer 2 – Header
              _buildHeader(),

              // Layer 3 – In-game alert
              if (_showAlert) _buildMathAlert(),

              // Layer 4 – Orb overlay (outside InteractiveViewer)
              if (_isAnimatingShatter) _buildOrbOptionsOverlay(),

              // Layer 5 – Tutorial / start screen
              if (!_gameStarted) _buildStartScreen(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FEATURE 4 – Tutorial / Start Screen
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStartScreen() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Container(
              width: 560,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0f172a),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF22d3ee), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(34, 211, 238, 0.35),
                    blurRadius: 45,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ────────────────────────────────────────────────
                  Center(
                    child: const Text(
                      'TUTORIAL: TRANSPOSICIÓN',
                      style: TextStyle(
                        fontSize: 24,
                        color: Color(0xFF22d3ee),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Theory card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFF22d3ee),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📖 La Teoría',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Una ecuación es como una balanza perfecta. '
                          'Si un número está sumando de un lado, para quitarlo '
                          'y dejar la "x" sola, debemos pasarlo al otro lado '
                          'realizando la operación contraria (restando).',
                          style: TextStyle(
                            color: Color(0xFFcbd5e1),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── How to play card ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFF22d3ee),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎮 Cómo Jugar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Arrastra el bloque verde con número al otro lado del '
                          'signo "=". Al cruzar, ¡verás cómo cambia su signo!',
                          style: TextStyle(
                            color: Color(0xFFcbd5e1),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Feature 5 – Animated demo
                        const TutorialDemoArea(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── CTA ────────────────────────────────────────────────
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22d3ee),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 52,
                          vertical: 15,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setState(() => _gameStarted = true),
                      child: const Text('¡ENTENDIDO! A JUGAR'),
                    ),
                  ),
                ],
              ),
            ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms).fadeIn(),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BACKGROUND
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF17253d), Color(0xFF0b1120)],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: CustomPaint(painter: _BgSymbolPainter(_bgSymbols)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _ScoreCard(
              label: 'Misión',
              value: '1',
              valueColor: Color(0xFF22d3ee),
            ).animate().slideX(begin: -1).fadeIn(),
            _ScoreCard(
              label: 'Integridad',
              value: '${_lives * 33}%',
              valueColor: const Color(0xFFef4444),
            ).animate().slideX(begin: 1).fadeIn(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  IN-GAME ALERT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMathAlert() {
    return Align(
      alignment: const Alignment(0, -0.6),
      child: Material(
        color: Colors.transparent,
        child:
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: _alertColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _alertColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _alertColor.withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Text(
                    _alertText,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _alertColor,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                  duration: 500.ms,
                )
                .fadeIn()
                .then(delay: 700.ms)
                .fadeOut()
                .scale(end: const Offset(0.5, 0.5)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BOARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBoard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0d1b2e),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildDraggableZoneLeft(),

                  // ── Equals sign – rotates + glows when block crosses it ────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: _isEqualsCrossed ? pi : 0,
                      ),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      builder: (context, angle, child) {
                        return Transform.rotate(
                          angle: angle,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: _isEqualsCrossed
                                  ? const Color(0xFF4ade80)
                                  : const Color(0xFFcbd5e1),
                              shadows: [
                                Shadow(
                                  color: _isEqualsCrossed
                                      ? const Color(0xFF4ade80)
                                      : const Color(0xFF22d3ee),
                                  blurRadius: _isEqualsCrossed ? 28 : 10,
                                ),
                              ],
                            ),
                            child: const Text('='),
                          ),
                        );
                      },
                    ),
                  ),

                  _buildDraggableZoneRight(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Left drop zone ────────────────────────────────────────────────────────

  Widget _buildDraggableZoneLeft() {
    // Check if we are in the "preview pending tap" state after a drop
    final bool hasPendingPreview = _leftPieces.any(
      (p) => p.type == 'distrib_preview' || p.type == 'combine_preview',
    );

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: _leftPieces.isNotEmpty
          ? _leftPieces.map((p) {
              if (p.type == 'locked_group' ||
                  (_gameMode == 'combine' && p.id == 'term2')) {
                return DragTarget<EquationLabPiece>(
                  onWillAcceptWithDetails: (details) {
                    if (_gameMode == 'distributive')
                      return details.data.type == 'coeff';
                    if (_gameMode == 'combine')
                      return details.data.type == 'xTerm' &&
                          details.data.id != p.id;
                    return false;
                  },
                  onAcceptWithDetails: (details) {
                    _handleLeftDrop(details.data, p);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isActive = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: isActive
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _gameMode == 'distributive'
                                      ? const Color(0xFFc084fc).withOpacity(0.8)
                                      : const Color(
                                          0xFF22d3ee,
                                        ).withOpacity(0.8),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            )
                          : const BoxDecoration(),
                      child: _buildPiece(p),
                    );
                  },
                );
              }
              return _buildPiece(p);
            }).toList()
          : [const SizedBox(width: 80, height: 70)],
    );

    // If we have preview blocks waiting for user to tap, wrap in a crush zone
    if (hasPendingPreview && _waitingForCrush) {
      final Color previewColor = _currentOrbMode == 'distributive'
          ? const Color(0xFFc084fc)
          : const Color(0xFF22d3ee);
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _zoneShakeController,
            builder: (context, child) {
              final dx = (_rnd.nextDouble() - 0.5) * 4;
              final dy = (_rnd.nextDouble() - 0.5) * 4;
              return Transform.translate(offset: Offset(dx, dy), child: child);
            },
            child: GestureDetector(
              onTap: () {
                if (_waitingForCrush) {
                  setState(() => _waitingForCrush = false);
                  _showOrbsOptions();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: previewColor.withOpacity(0.10),
                  border: Border.all(color: previewColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: previewColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: row,
              ),
            ),
          ),
          Positioned(
            top: -48,
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0.4,
                end: 1.0,
              ).animate(_floatTextController),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: const Offset(0, -0.2),
                    ).animate(
                      CurvedAnimation(
                        parent: _floatTextController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: previewColor),
                  ),
                  child: Text(
                    _currentOrbMode == 'distributive'
                        ? '¡TOCA PARA DISTRIBUIR!'
                        : '¡TOCA PARA SUMAR!',
                    style: TextStyle(
                      color: previewColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return row;
  }

  void _handleLeftDrop(EquationLabPiece dragged, EquationLabPiece target) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Simulate drop position in center
    final size = MediaQuery.of(context).size;
    final globalPos = Offset(size.width / 4, size.height / 2);

    if (_gameMode == 'distributive') {
      _createExplosion(globalPos, const Color(0xFFc084fc));
      setState(() {
        // Remove the dragged coeff and the locked_group piece
        _leftPieces.removeWhere(
          (p) => p.type == 'coeff' || p.type == 'locked_group',
        );
        // Build the distributive-preview pieces:
        // Block 1: "Ax" — shows the multiplication pending
        // Block 2: "+ (A × B)" — shows the second multiplication pending
        _leftPieces.insert(
          0,
          EquationLabPiece(
            id: 'distrib_ax',
            type: 'distrib_preview',
            text: '${_valA}x',
            side: 'left',
            draggable: false,
            order: 0,
          ),
        );
        _leftPieces.insert(
          1,
          EquationLabPiece(
            id: 'distrib_calc',
            type: 'distrib_preview',
            text: '${_isAdd ? "+" : "-"} ($_valA × $_valB)',
            side: 'left',
            draggable: false,
            order: 1,
          ),
        );
        _currentOrbMode = 'distributive';
        _waitingForCrush = true;
      });
      _showHtmlAlert(
        '¡Multiply! Toca la zona izquierda.',
        const Color(0xFFc084fc),
      );
    } else if (_gameMode == 'combine') {
      _createExplosion(globalPos, const Color(0xFF22d3ee));
      setState(() {
        // Remove both x-term blocks and replace with fused preview
        _leftPieces.removeWhere((p) => p.type == 'xTerm');
        _leftPieces.insert(
          0,
          EquationLabPiece(
            id: 'combine_preview',
            type: 'combine_preview',
            text: '(${_valA1} + ${_valA2})x',
            side: 'left',
            draggable: false,
            order: 0,
          ),
        );
        _currentOrbMode = 'combine';
        _waitingForCrush = true;
      });
      _showHtmlAlert(
        '¡Suma los Factores! Toca la zona izquierda.',
        const Color(0xFF22d3ee),
      );
    }
  }

  // ── Right drop zone ───────────────────────────────────────────────────────

  Widget _buildDraggableZoneRight() {
    return DragTarget<EquationLabPiece>(
      onWillAcceptWithDetails: (details) {
        if (_gameMode == 'distributive' || _gameMode == 'combine') {
          // You shouldn't drag things to the right while in mode-specific tasks unless they are free terms (which I don't support mixing yet)
          if (_leftPieces.any(
            (p) => p.type == 'locked_group' || p.type == 'xTerm',
          ))
            return false;
        }

        // Prevent coeff drag if there are terms
        if (details.data.type == 'coeff' && _gameMode != 'distributive') {
          if (_leftPieces.any((p) => p.type == 'number_with_sign')) {
            _showHtmlAlert(
              '¡Pasa las sumas/restas primero!',
              const Color(0xFFef4444),
            );
            _triggerShake();
            return false;
          }
        }
        // Prevent exp drag if there are terms or coeff
        if (details.data.type == 'exp') {
          if (_leftPieces.any(
            (p) => p.type == 'number_with_sign' || p.type == 'coeff',
          )) {
            _showHtmlAlert('¡Despeja la X primero!', const Color(0xFFef4444));
            _triggerShake();
            return false;
          }
        }

        return details.data.side == 'left' && details.data.draggable;
      },
      onAcceptWithDetails: (details) {
        final piece = details.data;
        final box = context.findRenderObject() as RenderBox?;
        final globalPos = box?.localToGlobal(details.offset) ?? details.offset;
        _createExplosion(globalPos, const Color(0xFF22d3ee));
        setState(() {
          _isHoveringRight = false;
          _isEqualsCrossed = false;
          _leftPieces.remove(piece);

          String newText = piece.text;

          if (piece.type == 'coeff') {
            newText = '÷ ${piece.text}';
            _currentOrbMode = 'division';
          } else if (piece.type == 'exp') {
            newText = piece.text == '²' ? '√' : '∛';
            _currentOrbMode = 'root';
          } else {
            // normal term
            _currentOrbMode = 'linear';
            if (newText.startsWith('+')) {
              newText = newText.replaceFirst('+', '-');
            } else if (newText.startsWith('-')) {
              newText = newText.replaceFirst('-', '+');
            } else {
              newText = '-$newText';
            }
          }

          final newPiece = piece.copyWith(side: 'right', text: newText);
          _rightPieces.add(newPiece);
          _waitingForCrush = true;
        });
        widget.onStepCompleted();
        _showHtmlAlert('¡TRANSFERENCIA OK!', const Color(0xFF22d3ee));
      },
      onMove: (_) {
        if (!_isHoveringRight) setState(() => _isHoveringRight = true);
        if (!_isEqualsCrossed) setState(() => _isEqualsCrossed = true);
      },
      onLeave: (_) {
        if (_isHoveringRight) setState(() => _isHoveringRight = false);
        if (_isEqualsCrossed) setState(() => _isEqualsCrossed = false);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isActive = _isHoveringRight || candidateData.isNotEmpty;
        final bool isCrush = _isAnimatingShatter || _waitingForCrush;

        final Color borderColor = isActive
            ? const Color(0xFF4ade80)
            : isCrush
            ? const Color(0xFF22d3ee)
            : Colors.white.withOpacity(0.08);

        // ── Inner content ─────────────────────────────────────────────
        Widget innerContent = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._rightPieces.map((p) => _buildPiece(p, isTargetSide: true)),
            if (_rightPieces.isEmpty)
              Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 40,
                          color: isActive
                              ? const Color(0xFF4ade80)
                              : Colors.white24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isActive ? '¡SUELTA AQUÍ!' : 'ARRASTRA AQUÍ',
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF4ade80)
                                : Colors.white30,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(begin: 0.5, end: 1.0, duration: 700.ms),
          ],
        );

        // ── Drop zone container ───────────────────────────────────────
        Widget dropZone = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isActive
                ? const Color(0xFF4ade80).withOpacity(0.15)
                : isCrush
                ? const Color(0xFF22d3ee).withOpacity(0.10)
                : Colors.transparent,
            border: Border.all(
              color: borderColor,
              width: (isActive || isCrush) ? 2.5 : 0,
            ),
            boxShadow: (isActive || isCrush)
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.5),
                      blurRadius: isActive ? 40 : 20,
                      spreadRadius: isActive ? 4 : 2,
                    ),
                  ]
                : null,
          ),
          child: innerContent,
        );

        if (_waitingForCrush) {
          if (_currentOrbMode != 'combine' &&
              _currentOrbMode != 'distributive') {
            return _buildReadyToCrushZone(dropZone);
          }
        }
        return dropZone;
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FEATURE 1 – Shake zone + floating "¡Toca para Romper!" hint
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildReadyToCrushZone(Widget content) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Continuous subtle shake
        AnimatedBuilder(
          animation: _zoneShakeController,
          builder: (context, child) {
            final dx = (_rnd.nextDouble() - 0.5) * 4;
            final dy = (_rnd.nextDouble() - 0.5) * 4;
            return Transform.translate(offset: Offset(dx, dy), child: child);
          },
          child: GestureDetector(
            onTap: () {
              if (_waitingForCrush) {
                setState(() => _waitingForCrush = false);
                _showOrbsOptions();
              }
            },
            child: content,
          ),
        ),

        // Floating hint text above the zone
        Positioned(
          top: -48,
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.4,
              end: 1.0,
            ).animate(_floatTextController),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: const Offset(0, -0.2),
                  ).animate(
                    CurvedAnimation(
                      parent: _floatTextController,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.yellowAccent),
                ),
                child: const Text(
                  '¡TOCA PARA ROMPER!',
                  style: TextStyle(
                    color: Colors.yellowAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FEATURE 2 – Orb overlay with CustomPaint energy rays
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOrbOptionsOverlay() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 165.0;

    return Positioned.fill(
      child: Stack(
        children: [
          // Dark backdrop
          Container(color: Colors.black.withOpacity(0.72)),

          // Energy rays (CustomPaint)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EnergyRaysPainter(
                  center: center,
                  radius: radius,
                  orbCount: _orbOptions.length,
                ),
              ),
            ),
          ),

          // Orbs
          ...List.generate(_orbOptions.length, (index) {
            final angle = (index * 2 * pi / _orbOptions.length) - (pi / 2);
            final orbX = center.dx + radius * cos(angle) - 50;
            final orbY = center.dy + radius * sin(angle) - 50;

            return Positioned(
              left: orbX,
              top: orbY,
              child: _buildOrbInteractive(_orbOptions[index], index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrbInteractive(int opt, int index) {
    // Derive correct answer using same logic as _showOrbsOptions
    final int correct;
    if (_currentOrbMode == 'combine') {
      correct = _valA1 + (_isAdd ? _valA2 : -_valA2);
    } else if (_currentOrbMode == 'distributive') {
      correct = _valA * _valB;
    } else if (_currentOrbMode == 'root') {
      final baseVal =
          int.tryParse(_rightPieces.isNotEmpty ? _rightPieces[0].text : '0') ??
          0;
      correct = _gameMode == 'quadratic'
          ? sqrt(baseVal).round()
          : pow(baseVal, 1 / 3).round();
    } else if (_currentOrbMode == 'division') {
      final baseVal =
          int.tryParse(_rightPieces.isNotEmpty ? _rightPieces[0].text : '0') ??
          0;
      final modVal =
          int.tryParse(
            _rightPieces.length > 1
                ? _rightPieces[1].text.replaceAll('÷', '').trim()
                : '$_valA',
          ) ??
          _valA;
      correct = modVal != 0 ? baseVal ~/ modVal : 0;
    } else {
      // linear add/sub
      final baseVal =
          int.tryParse(_rightPieces.isNotEmpty ? _rightPieces[0].text : '0') ??
          0;
      final modText = _rightPieces.length > 1 ? _rightPieces[1].text : '+0';
      final modVal =
          int.tryParse(
            modText.replaceAll('+', '').replaceAll('-', '').trim(),
          ) ??
          0;
      if (modText.startsWith('-')) {
        correct = baseVal - modVal;
      } else {
        correct = baseVal + modVal;
      }
    }

    return GestureDetector(
          onTap: () => _verifyShatter(opt, correct),
          child:
              Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF238b3c), Color(0xFF064e3b)],
                        center: Alignment(-0.3, -0.3),
                      ),
                      border: Border.all(
                        color: const Color(0xFF4ade80),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(74, 222, 128, 0.8),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        opt.toString(),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.06, duration: 800.ms),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          delay: Duration(milliseconds: index * 80),
        );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PIECE BUILDER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPiece(EquationLabPiece piece, {bool isTargetSide = false}) {
    bool isVariableBlock = piece.type == 'term' || piece.type == 'locked_group';
    bool isExp = piece.type == 'exp';
    bool isDistribLock = piece.type == 'locked_group';
    bool isDistribPreview = piece.type == 'distrib_preview';
    bool isCombinePreview = piece.type == 'combine_preview';

    // ── Special preview blocks render ────────────────────────────────────────
    if (isDistribPreview) {
      return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3b0764),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFc084fc), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFc084fc).withOpacity(0.5),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Text(
              piece.text,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1200.ms,
            color: const Color(0xFFc084fc).withOpacity(0.4),
          );
    }
    if (isCombinePreview) {
      return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0c4a6e),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF22d3ee), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22d3ee).withOpacity(0.5),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Text(
              piece.text,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1200.ms,
            color: const Color(0xFF22d3ee).withOpacity(0.4),
          );
    }

    Color bgColor = const Color(0xFF064e3b);
    Color borderColor = const Color(0xFF10b981);
    Color textColor = Colors.white;

    if (isVariableBlock) {
      bgColor = const Color(0xFF1e293b);
      borderColor = isDistribLock
          ? const Color(0xFFc084fc)
          : const Color(0xFF334155);
      textColor = const Color(0xFF38bdf8);
    } else if (isExp) {
      bgColor = const Color(0xFF3b0764);
      borderColor = const Color(0xFF7e22ce);
    } else if (piece.type == 'coeff' && _gameMode == 'distributive') {
      borderColor = const Color(0xFF22c55e);
    } else if (piece.type == 'xTerm') {
      bgColor = const Color(0xFF0891b2);
      borderColor = const Color(0xFF22d3ee);
    }

    Widget child = Container(
      margin: EdgeInsets.symmetric(horizontal: isExp ? 2 : 4),
      padding: isExp
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isExp ? 12 : 18),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isVariableBlock
            ? [
                if (isDistribLock)
                  BoxShadow(
                    color: borderColor.withOpacity(0.4),
                    blurRadius: 15,
                  ),
              ]
            : [
                BoxShadow(
                  color: borderColor.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isDistribLock) const Text('🔒 ', style: TextStyle(fontSize: 28)),
          Text(
            piece.text,
            style: TextStyle(
              fontSize: isExp ? 28 : 40,
              fontWeight: FontWeight.w900,
              color: textColor,
              shadows: isVariableBlock
                  ? [Shadow(color: textColor.withOpacity(0.8), blurRadius: 15)]
                  : const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );

    if (isExp) {
      // Exponents should be smaller and floated up
      child = Transform.translate(offset: const Offset(0, -20), child: child);
    }

    // Shimmering shake on target side while orbs are visible
    if (isTargetSide && _isAnimatingShatter) {
      child = child
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: Colors.white54)
          .shake(rotation: 0.02, hz: 6, duration: 1000.ms);
    }

    if (piece.draggable && !_isAnimatingShatter) {
      return Draggable<EquationLabPiece>(
        data: piece,
        feedback: Material(
          color: Colors.transparent,
          child: child
              .animate()
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.15, 1.15),
                duration: 100.ms,
              )
              .rotate(end: -0.05)
              .boxShadow(
                end: const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(10, 10),
                ),
              ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: child),
        child: child,
      );
    }

    return child;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FEATURE 5 – Tutorial animated demo (AnimationController repeat)
// ══════════════════════════════════════════════════════════════════════════════

class TutorialDemoArea extends StatefulWidget {
  const TutorialDemoArea({super.key});

  @override
  _TutorialDemoAreaState createState() => _TutorialDemoAreaState();
}

class _TutorialDemoAreaState extends State<TutorialDemoArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Alignment> _slideAnim;
  late Animation<double> _crossAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _slideAnim = AlignmentTween(
      begin: const Alignment(-0.8, 0),
      end: const Alignment(0.8, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _crossAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border.all(color: Colors.white24, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static "=" divider
          const Text(
            '=',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white38,
            ),
          ),
          // Animated block that crosses the equals
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final bool hasCrossed = _crossAnim.value > 0.5;
              return Align(
                alignment: _slideAnim.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: hasCrossed
                        ? const Color(0xFFef4444)
                        : const Color(0xFF22d3ee),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: hasCrossed
                            ? Colors.red.withOpacity(0.5)
                            : Colors.cyan.withOpacity(0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Text(
                    hasCrossed ? '- X' : '+ X',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════════════════════

/// Background floating math symbols painter
class _BgSymbolPainter extends CustomPainter {
  final List<_FloatingSymbol> symbols;
  _BgSymbolPainter(this.symbols);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    for (var s in symbols) {
      canvas.save();
      canvas.translate(s.x * size.width, s.y * size.height);
      canvas.rotate(s.rot);
      final tp = TextPainter(
        text: TextSpan(
          text: s.char,
          style: TextStyle(
            color: Colors.white.withOpacity(0.06),
            fontSize: s.size,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Particle explosion painter (Feature 3)
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        paint,
      );
      // Glow
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.5,
          height: p.size * 1.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Feature 2 – Energy rays from centre to each orb
class _EnergyRaysPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final int orbCount;

  _EnergyRaysPainter({
    required this.center,
    required this.radius,
    required this.orbCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (orbCount == 0) return;
    final paint = Paint()
      ..color = const Color(0xFF4ade80).withOpacity(0.55)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    for (int i = 0; i < orbCount; i++) {
      final angle = (i * 2 * pi / orbCount) - (pi / 2);
      final endX = center.dx + (radius * 0.85) * cos(angle);
      final endY = center.dy + (radius * 0.85) * sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  AUXILIARY WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _ScoreCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ScoreCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: valueColor.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

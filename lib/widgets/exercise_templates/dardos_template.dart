import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:demo_33_v2/models/ai_exercise_model.dart';
import 'dart:async';

class DardosTemplate extends StatefulWidget {
  final AIExercise exercise;
  final VoidCallback
  onLevelComplete; // kept for legacy compatibility, changing soon if needed
  final VoidCallback? onStepCompleted;
  final VoidCallback? onExerciseCompleted;
  final Function(int)? onLivesChanged;

  const DardosTemplate({
    super.key,
    required this.exercise, // If using config, might need to adapt. Let's assume AIExercise.
    this.onLevelComplete = _defaultCallback,
    this.onStepCompleted,
    this.onExerciseCompleted,
    this.onLivesChanged,
  });

  static void _defaultCallback() {}

  @override
  State<DardosTemplate> createState() => _DardosTemplateState();
}

class _DardosTemplateState extends State<DardosTemplate>
    with TickerProviderStateMixin {
  int _currentLevel = 0;
  late Map<String, dynamic> _eq;
  String _gameState =
      'tutorial'; // tutorial, select_target, shoot, animating, won
  String? _activeTarget;
  String? _wrongTarget;
  bool _activationFlash = false;
  bool _isAnimating = false;
  int? _arrowTarget;
  Map<String, dynamic> _mathAnim = {'phase': 0, 'type': null, 'value': null};
  bool _gameWon = false;
  List<Map<String, dynamic>> _options = [];
  Map<String, String> _message = {
    'text':
        "Fase 1: Haz clic en el bloque de la izquierda que debes operar primero.",
    'type': 'info',
  };

  late AnimationController _rotationController;
  Timer? _animTimer;
  Offset _shotEnd = Offset.zero;

  final List<Map<String, dynamic>> _levels = [
    {
      'id': 1,
      'type': 'linear',
      'power': 1,
      'leftX': 2,
      'leftConst': 4,
      'rightConst': 10,
      'parenCoeff': null,
      'parenX': null,
      'parenConst': null,
      'trinom': null,
      'factors': null,
      'factored': false,
      'tutorial': {
        'title': "Ecuaciones Lineales: La Balanza (ax + b = c)",
        'theory':
            "Imagina que la ecuación es una balanza perfecta. Deja la 'x' sola aplicando la operación inversa a ambos lados. La jerarquía estricta dicta eliminar sumas y restas primero, luego multiplicaciones/divisiones.",
        'instruction':
            "Haz clic en el número que está sumando/restando para fijarlo. Luego dispara a la operación contraria en la ruleta.",
      },
    },
    {
      'id': 2,
      'type': 'distributive',
      'power': 1,
      'leftX': 1,
      'leftConst': 0,
      'rightConst': 12,
      'parenCoeff': 3,
      'parenX': 1,
      'parenConst': -2,
      'trinom': null,
      'factors': null,
      'factored': false,
      'tutorial': {
        'title': "Propiedad Distributiva: Rompiendo Barreras",
        'theory':
            "Cuando un número multiplica a un grupo entre paréntesis a(x+b), multiplica a cada término adentro. Es obligatorio distribuir primero.",
        'instruction':
            "Haz clic en el número amarillo multiplicador. Luego dispara a 'Distribuir' en la ruleta.",
      },
    },
    {
      'id': 3,
      'type': 'linear',
      'power': 2,
      'leftX': 1,
      'leftConst': -9,
      'rightConst': 0,
      'parenCoeff': null,
      'parenX': null,
      'parenConst': null,
      'trinom': null,
      'factors': null,
      'factored': false,
      'tutorial': {
        'title': "Ecuaciones Cuadráticas: El Antídoto",
        'theory':
            "Si la 'x' está elevada al cuadrado (x²), su antídoto es la raíz cuadrada (√). Aplicarla a ambos lados destruye el exponente.",
        'instruction':
            "Despeja los números sueltos. Cuando x² quede sola, haz clic en el exponente y dispara a 'Raíz √'.",
      },
    },
    {
      'id': 4,
      'type': 'linear',
      'power': 3,
      'leftX': 2,
      'leftConst': -16,
      'rightConst': 0,
      'parenCoeff': null,
      'parenX': null,
      'parenConst': null,
      'trinom': null,
      'factors': null,
      'factored': false,
      'tutorial': {
        'title': "Ecuaciones Cúbicas: Subiendo de Nivel",
        'theory':
            "Si la 'x' está elevada al cubo (x³), su antídoto exacto es la raíz cúbica (³√).",
        'instruction':
            "Despeja constantes, luego divide el multiplicador. Selecciona el exponente y dispara a 'Raíz ³√'.",
      },
    },
    {
      'id': 5,
      'type': 'factorization',
      'power': 1,
      'leftX': 1,
      'leftConst': 0,
      'rightConst': 0,
      'parenCoeff': null,
      'parenX': null,
      'parenConst': null,
      'trinom': "x² + 5x + 6",
      'factors': ["(x + 2)", "(x + 3)"],
      'factored': false,
      'tutorial': {
        'title': "Factorización: Transformando Sumas",
        'theory':
            "Un trinomio x² + bx + c se puede factorizar en (x + p)(x + q). Busca números que sumen 'b' y multipliquen 'c'.",
        'instruction':
            "Haz clic en el trinomio violeta y dispara a 'Factorizar' en la ruleta para presenciar la partición.",
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _eq = Map.from(_levels[0]);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _generateOptions();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _animTimer?.cancel();
    super.dispose();
  }

  void _generateOptions() {
    if ((_mathAnim['phase'] as int) > 0 || _activeTarget == null) return;
    Map<String, dynamic> correctOp = {};
    List<Map<String, dynamic>> wrongOps = [];

    if (_activeTarget == 'paren') {
      correctOp = {'type': 'distribute', 'label': 'Distribuir', 'value': 0};
      wrongOps = [
        {'type': 'x', 'label': 'Factorizar', 'value': 0},
        {'type': 'y', 'label': 'Raíz √', 'value': 0},
        {'type': 'z', 'label': 'Sumar', 'value': 0},
      ];
    } else if (_activeTarget == 'trinomial') {
      correctOp = {'type': 'factorize', 'label': 'Factorizar', 'value': 0};
      wrongOps = [
        {'type': 'x', 'label': 'Distribuir', 'value': 0},
        {'type': 'y', 'label': 'Dividir', 'value': 0},
        {'type': 'z', 'label': 'Potencia', 'value': 0},
      ];
    } else if (_activeTarget == 'power') {
      final isSq = _eq['power'] == 2;
      correctOp = {
        'type': 'root',
        'value': _eq['power'],
        'label': isSq ? 'Raíz √' : 'Raíz ³√',
      };
      wrongOps = [
        {'type': 'wrong', 'label': isSq ? 'Raíz ³√' : 'Raíz √', 'value': 0},
        {'type': 'wrong', 'label': '÷ 2', 'value': 0},
        {'type': 'wrong', 'label': 'x²', 'value': 0},
      ];
    } else if (_activeTarget == 'const') {
      final val = (_eq['leftConst'] as int).abs();
      correctOp = {
        'type': 'add',
        'value': -_eq['leftConst'],
        'label': _eq['leftConst'] > 0 ? "- $val" : "+ $val",
      };
      wrongOps = [
        {
          'type': 'add',
          'value': _eq['leftConst'],
          'label': _eq['leftConst'] > 0 ? "+ $val" : "- $val",
        },
        {
          'type': 'div',
          'value': val == 0 ? 2 : val,
          'label': "÷ ${val == 0 ? 2 : val}",
        },
        {'type': 'root', 'value': 2, 'label': 'Raíz √'},
      ];
    } else if (_activeTarget == 'x') {
      final val = (_eq['leftX'] as int).abs();
      correctOp = {'type': 'div', 'value': _eq['leftX'], 'label': "÷ $val"};
      wrongOps = [
        {
          'type': 'add',
          'value': -_eq['leftX'],
          'label': _eq['leftX'] > 0 ? "- $val" : "+ $val",
        },
        {'type': 'mul', 'value': _eq['leftX'], 'label': "× $val"},
        {'type': 'root', 'value': 2, 'label': 'Raíz √'},
      ];
    }

    final allOps = [correctOp, ...wrongOps.take(3)]..shuffle(Random());
    setState(() {
      _options = allOps;
    });
  }

  void _handleBlockClick(String type) {
    if (_gameState != 'select_target') return;
    if (type == 'right') {
      setState(() {
        _wrongTarget = 'right';
        _message = {
          'text':
              "¡Error! Debes operar los números de la izquierda para dejar sola a la 'x'.",
          'type': 'error',
        };
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrongTarget = null);
      });
      return;
    }

    if (type == 'x') {
      if (_eq['type'] == 'distributive' && _eq['parenCoeff'] != null) {
        setState(() {
          _wrongTarget = 'x';
          _message = {
            'text':
                "Lógica: ¡Aún no! Primero debes romper el paréntesis distribuyendo.",
            'type': 'error',
          };
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _wrongTarget = null);
        });
        return;
      }
      if (_eq['leftConst'] != 0) {
        setState(() {
          _wrongTarget = 'x';
          _message = {
            'text':
                "Lógica: Primero elimina los números sueltos (sumas/restas) antes de dividir.",
            'type': 'error',
          };
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _wrongTarget = null);
        });
        return;
      }
      setState(() {
        _activeTarget = (_eq['power'] > 1 && _eq['leftX'] == 1) ? 'power' : 'x';
      });
    } else {
      setState(() {
        _activeTarget = type;
      });
    }

    setState(() {
      _gameState = 'shoot';
      _activationFlash = true;
      _message = {
        'text':
            "Fase 2: Objetivo fijado. ¡Dispara a su operación inversa en la ruleta!",
        'type': 'info',
      };
      _generateOptions();
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _activationFlash = false);
    });
  }

  void _handleShoot(Map<String, dynamic> option, int index, Offset position) {
    if (_isAnimating ||
        _gameWon ||
        (_mathAnim['phase'] as int) > 0 ||
        _gameState != 'shoot') {
      return;
    }

    setState(() {
      _isAnimating = true;
      _arrowTarget = index;
      _shotEnd = position;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      bool isCorrect = false;
      Map<String, dynamic> newEq = Map.from(_eq);

      if (_activeTarget == 'paren' && option['type'] == 'distribute') {
        isCorrect = true;
      } else if (_activeTarget == 'trinomial' && option['type'] == 'factorize')
        isCorrect = true;
      else if (_activeTarget == 'power' && option['type'] == 'root')
        isCorrect = true;
      else if (_activeTarget == 'const' &&
          option['type'] == 'add' &&
          option['value'] == -_eq['leftConst'])
        isCorrect = true;
      else if (_activeTarget == 'x' &&
          option['type'] == 'div' &&
          option['value'] == _eq['leftX'])
        isCorrect = true;

      if (!isCorrect) {
        setState(() {
          _message = {
            'text':
                "¡Dardo fallido! Piensa lógicamente en la operación contraria.",
            'type': 'error',
          };
          _isAnimating = false;
          _arrowTarget = null;
        });
        return;
      }

      setState(() {
        _gameState = 'animating';
        _message = {
          'text': "¡Impacto! Iniciando resolución paso a paso...",
          'type': 'info',
        };
        _isAnimating = false;
        _arrowTarget = null;
        _mathAnim = {
          'phase': 1,
          'type': option['type'],
          'value': option['value'],
        };
      });

      // PASO 1
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() {
          _mathAnim['phase'] = 2;
          _message = {
            'text':
                "Micropaso 2 (Cancelación): En la izquierda, la operación inversa destruye a nuestro objetivo.",
            'type': 'info',
          };
        });

        // PASO 2
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          setState(() {
            _mathAnim['phase'] = 3;
            _message = {
              'text':
                  "Micropaso 3 (Resultado): En la derecha, calculamos los números para mantener el equilibrio.",
              'type': 'info',
            };
          });

          // FINAL
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!mounted) return;
            setState(() {
              if (option['type'] == 'add') {
                newEq['leftConst'] += option['value'];
                newEq['rightConst'] += option['value'];
              } else if (option['type'] == 'div') {
                newEq['leftX'] = (newEq['leftX'] ~/ option['value']);
                newEq['rightConst'] = (newEq['rightConst'] ~/ option['value']);
              } else if (option['type'] == 'distribute') {
                newEq['type'] = 'linear';
                newEq['leftX'] = _eq['parenCoeff'] * _eq['parenX'];
                newEq['leftConst'] = _eq['parenCoeff'] * _eq['parenConst'];
                newEq['parenCoeff'] = null;
              } else if (option['type'] == 'root') {
                newEq['power'] = 1;
                newEq['rightConst'] = option['value'] == 2
                    ? sqrt(newEq['rightConst']).toInt()
                    : pow(newEq['rightConst'], 1 / 3).round();
              } else if (option['type'] == 'factorize') {
                newEq['factored'] = true;
              }

              _eq = newEq;
              _mathAnim = {'phase': 0, 'type': null, 'value': null};
            });

            if (newEq['factored'] == true ||
                (newEq['leftX'] == 1 &&
                    newEq['leftConst'] == 0 &&
                    newEq['power'] == 1 &&
                    newEq['parenCoeff'] == null)) {
              setState(() {
                _gameWon = true;
                _gameState = 'won';
                _message = {
                  'text': "¡Despeje Perfecto! Ecuación completamente resuelta.",
                  'type': 'success',
                };
              });
              widget.onStepCompleted?.call();
              if (_currentLevel == _levels.length - 1) {
                Future.delayed(const Duration(seconds: 2), () {
                  widget.onExerciseCompleted?.call();
                });
              }
            } else {
              setState(() {
                _gameState = 'select_target';
                _activeTarget = null;
                _message = {
                  'text':
                      "Siguiente fase lógica: Haz clic en el siguiente bloque a operar.",
                  'type': 'info',
                };
              });
            }
          });
        });
      });
    });
  }

  void _nextLevel() {
    if (_currentLevel < _levels.length - 1) {
      setState(() {
        _currentLevel++;
        _eq = Map.from(_levels[_currentLevel]);
        _gameWon = false;
        _gameState = 'tutorial';
        _activeTarget = null;
        _mathAnim = {'phase': 0, 'type': null, 'value': null};
        _message = {
          'text':
              "Fase 1: Haz clic en el bloque de la izquierda que debes operar primero.",
          'type': 'info',
        };
      });
      widget.onStepCompleted?.call();
    } else {
      widget.onExerciseCompleted?.call();
    }
  }

  void _resetLevel() {
    setState(() {
      _eq = Map.from(_levels[_currentLevel]);
      _gameWon = false;
      _gameState = 'select_target';
      _activeTarget = null;
      _mathAnim = {'phase': 0, 'type': null, 'value': null};
      _message = {
        'text': "Nivel reiniciado. Aplica la lógica paso a paso.",
        'type': 'info',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Column(
                    children: [
                      _buildPizarra(),
                      _buildMessagePanel(),
                      Expanded(child: _buildRouletteArea()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_gameState == 'tutorial') _buildTutorialOverlay(),
          if (_activationFlash) _buildActivationFlash(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                "ÁLGEBRA ANIMADA",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Text(
                  "Nivel ${_currentLevel + 1} / ${_levels.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
                onPressed: () => setState(() => _gameState = 'tutorial'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _resetLevel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPizarra() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topLeft,
            child: Text(
              "PIZARRA INTERACTIVA",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLeftTerms(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "=",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ),
                _buildRightTerms(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftTerms() {
    List<Widget> children = [];

    if (_eq['type'] == 'factorization') {
      if (!_eq['factored']) {
        children.add(
          _buildBlock(
            id: 'trinomial',
            text: _eq['trinom'],
            isX: true,
            colorBase: Colors.purple,
            colorShadow: Colors.purple[900]!,
            isActive: _activeTarget == 'trinomial',
            isWrong: _wrongTarget == 'trinomial',
            isDimmed: _gameState == 'shoot' && _activeTarget != 'trinomial',
            isSlashed: (_mathAnim['phase'] as int) >= 2,
          ),
        );
      } else {
        children.add(
          _buildBlock(
            text: _eq['factors'][0],
            isX: true,
            colorBase: Colors.purple,
            colorShadow: Colors.purple[900]!,
          ),
        );
        children.add(const SizedBox(width: 8));
        children.add(
          _buildBlock(
            text: _eq['factors'][1],
            isX: true,
            colorBase: Colors.purple,
            colorShadow: Colors.purple[900]!,
          ),
        );
      }
    } else if (_eq['type'] == 'distributive' && _eq['parenCoeff'] != null) {
      children.add(
        _buildBlock(
          id: 'paren',
          text: _eq['parenCoeff'].toString(),
          isX: false,
          colorBase: Colors.orange,
          colorShadow: Colors.orange[900]!,
          isActive: _activeTarget == 'paren',
          isWrong: _wrongTarget == 'paren',
          isDimmed: _gameState == 'shoot' && _activeTarget != 'paren',
          isSlashed: (_mathAnim['phase'] as int) >= 2,
        ),
      );
      children.add(
        const Text(
          " ( ",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: Colors.grey,
          ),
        ),
      );
      children.add(
        _buildBlock(
          text: _eq['parenX'] == 1 ? "x" : "${_eq['parenX']}x",
          isX: true,
          colorBase: const Color(0xFF1E293B),
          colorShadow: const Color(0xFF0F172A),
          isDimmed: _gameState == 'shoot',
        ),
      );
      children.add(
        _buildBlock(
          text: _eq['parenConst'] > 0
              ? "+${_eq['parenConst']}"
              : _eq['parenConst'].toString(),
          isX: false,
          colorBase: Colors.green,
          colorShadow: Colors.green[900]!,
          isDimmed: _gameState == 'shoot',
        ),
      );
      children.add(
        const Text(
          " )",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: Colors.grey,
          ),
        ),
      );
    } else if (_eq['type'] == 'linear') {
      if (_eq['leftX'] != 0) {
        String xText = "x";
        if (_eq['power'] == 2) xText = "x²";
        if (_eq['power'] == 3) xText = "x³";
        if (_eq['leftX'] != 1 && _eq['leftX'] != -1) {
          xText = "${_eq['leftX']}$xText";
        } else if (_eq['leftX'] == -1) {
          xText = "-$xText";
        }

        bool isDivAnim =
            (_mathAnim['phase'] as int) >= 1 && _mathAnim['type'] == 'div';

        var xBlock = _buildBlock(
          id: 'x',
          text: xText,
          isX: true,
          colorBase: const Color(0xFF1E293B),
          colorShadow: const Color(0xFF0F172A),
          isActive: _activeTarget == 'x' || _activeTarget == 'power',
          isWrong: _wrongTarget == 'x',
          isDimmed:
              _gameState == 'shoot' &&
              _activeTarget != 'x' &&
              _activeTarget != 'power',
          isSlashed:
              (_mathAnim['phase'] as int) >= 2 && _mathAnim['type'] == 'div',
        );

        children.add(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: isDivAnim
                    ? const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                        ),
                      )
                    : null,
                child: xBlock,
              ),
              if (isDivAnim)
                _buildBlock(
                  text: _mathAnim['value'].toString(),
                  isX: false,
                  colorBase: Colors.blue,
                  colorShadow: Colors.blue[900]!,
                  isSlashed: (_mathAnim['phase'] as int) >= 2,
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
            ],
          ),
        );
      }

      if (_eq['leftConst'] != 0) {
        bool isAddAnim =
            (_mathAnim['phase'] as int) >= 1 && _mathAnim['type'] == 'add';
        children.add(const SizedBox(width: 10));
        var cBlock = Column(
          children: [
            _buildBlock(
              id: 'const',
              text: _eq['leftConst'] > 0
                  ? "+${_eq['leftConst']}"
                  : _eq['leftConst'].toString(),
              isX: false,
              colorBase: Colors.green,
              colorShadow: Colors.green[900]!,
              isActive: _activeTarget == 'const',
              isWrong: _wrongTarget == 'const',
              isDimmed: _gameState == 'shoot' && _activeTarget != 'const',
              isSlashed:
                  (_mathAnim['phase'] as int) >= 2 &&
                  _mathAnim['type'] == 'add',
            ),
            if (isAddAnim)
              _buildBlock(
                text: _mathAnim['value'] > 0
                    ? "+${_mathAnim['value']}"
                    : _mathAnim['value'].toString(),
                isX: false,
                colorBase: Colors.blue,
                colorShadow: Colors.blue[900]!,
                isSlashed: (_mathAnim['phase'] as int) >= 2,
              ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          ],
        );
        children.add(cBlock);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildRightTerms() {
    int phase = _mathAnim['phase'] as int;

    if (phase < 3 && _eq['rightConst'] != 0) {
      bool isDivAnim = phase >= 1 && _mathAnim['type'] == 'div';
      bool isAddAnim = phase >= 1 && _mathAnim['type'] == 'add';

      return Column(
        children: [
          Container(
            decoration: isDivAnim
                ? const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 4),
                    ),
                  )
                : null,
            child: _buildBlock(
              text: _eq['rightConst'].toString(),
              isX: false,
              colorBase: Colors.green,
              colorShadow: Colors.green[900]!,
              isDimmed: _gameState == 'shoot',
            ),
          ),
          if (isDivAnim)
            _buildBlock(
              text: _mathAnim['value'].toString(),
              isX: false,
              colorBase: Colors.blue,
              colorShadow: Colors.blue[900]!,
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          if (isAddAnim)
            _buildBlock(
              text: _mathAnim['value'] > 0
                  ? "+${_mathAnim['value']}"
                  : _mathAnim['value'].toString(),
              isX: false,
              colorBase: Colors.blue,
              colorShadow: Colors.blue[900]!,
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ],
      );
    } else if (phase < 3 && _eq['rightConst'] == 0) {
      return _buildBlock(
        text: "0",
        isX: false,
        colorBase: Colors.green,
        colorShadow: Colors.green[900]!,
        isDimmed: _gameState == 'shoot',
      );
    } else if (phase >= 3) {
      String resText = _eq['rightConst'].toString();
      if (_mathAnim['type'] == 'add') {
        resText = (_eq['rightConst'] + _mathAnim['value']).toString();
      }
      if (_mathAnim['type'] == 'div') {
        resText = (_eq['rightConst'] ~/ _mathAnim['value']).toString();
      }
      if (_mathAnim['type'] == 'root') {
        resText = _mathAnim['value'] == 2
            ? sqrt(_eq['rightConst']).toInt().toString()
            : pow(_eq['rightConst'], 1 / 3).round().toString();
      }

      return _buildBlock(
        text: resText,
        isX: false,
        colorBase: Colors.amber,
        textColor: Colors.black,
        colorShadow: Colors.amber[900]!,
      ).animate().scale(duration: 500.ms).shimmer(duration: 800.ms);
    }
    return const SizedBox();
  }

  Widget _buildBlock({
    String? id,
    required String text,
    required bool isX,
    required Color colorBase,
    required Color colorShadow,
    Color textColor = Colors.white,
    bool isActive = false,
    bool isWrong = false,
    bool isDimmed = false,
    bool isSlashed = false,
  }) {
    bool isWaitingClick =
        id != null && !isActive && !isWrong && _gameState == 'select_target';

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isActive || isWrong
            ? Colors.redAccent
            : (isSlashed ? Colors.grey[700] : colorBase),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive || isWrong
              ? Colors.red
              : (isSlashed ? Colors.grey : Colors.white10),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive || isWrong
                ? Colors.red[900]!
                : (isSlashed ? Colors.black45 : colorShadow),
            offset: const Offset(0, 6),
          ),
          if (isActive) const BoxShadow(color: Colors.red, blurRadius: 20),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: isSlashed ? Colors.grey[400] : textColor,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(text),
            if (isSlashed)
              Positioned.fill(
                child: CustomPaint(painter: _SlashPainter()),
              ).animate().fadeIn(duration: 200.ms),
            if (isActive)
              Positioned(
                top: -20,
                right: -20,
                child:
                    Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.gps_fixed,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(
                          begin: -5,
                          end: 5,
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .moveY(
                          begin: 5,
                          end: -5,
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
          ],
        ),
      ),
    );

    if (isDimmed) {
      child = Opacity(opacity: 0.3, child: child);
    }
    if (isWaitingClick) {
      child = GestureDetector(
        onTap: () => _handleBlockClick(id),
        child: child
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 800.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.05, 1.05),
              end: const Offset(1, 1),
              duration: 800.ms,
            ),
      );
    } else if (id != null && _gameState == 'select_target') {
      child = GestureDetector(onTap: () => _handleBlockClick(id), child: child);
    }
    if (isWrong) {
      child = child.animate().shakeX(duration: 400.ms);
    }
    if (isActive) {
      child = Transform.scale(
        scale: 1.1,
        child: Transform.translate(offset: const Offset(0, -5), child: child),
      );
    }
    return child;
  }

  Widget _buildMessagePanel() {
    Color borderColor = Colors.blue;
    Color bgColor = Colors.blue.withOpacity(0.2);
    IconData icon = Icons.play_arrow;
    Color iconColor = Colors.blueAccent;

    if (_message['type'] == 'error') {
      borderColor = Colors.red;
      bgColor = Colors.red.withOpacity(0.2);
      icon = Icons.error_outline;
      iconColor = Colors.redAccent;
    } else if (_message['type'] == 'success') {
      borderColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.2);
      icon = Icons.check_circle_outline;
      iconColor = Colors.greenAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _message['text']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouletteArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_gameState == 'select_target')
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.red, size: 64)
                        .animate(onPlay: (c) => c.repeat())
                        .scale(duration: 800.ms),
                    const SizedBox(height: 16),
                    const Text(
                      "BLOQUEADA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      "Haz clic arriba para recargar",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          if (!_gameWon &&
              _gameState != 'select_target' &&
              _gameState != 'tutorial')
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue[700]!, width: 12),
                      gradient: const SweepGradient(
                        colors: [
                          Colors.red,
                          Colors.white,
                          Colors.blueAccent,
                          Colors.amber,
                          Colors.red,
                          Colors.white,
                          Colors.blueAccent,
                          Colors.amber,
                          Colors.red,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, blurRadius: 20),
                      ],
                    ),
                  ),
                );
              },
            ),

          if (!_gameWon &&
              _gameState != 'select_target' &&
              _gameState != 'tutorial')
            ..._options.asMap().entries.map((entry) {
              int idx = entry.key;
              var opt = entry.value;
              double angle = (idx * (2 * pi / _options.length)) - (pi / 2);

              return Positioned(
                left: 130 + cos(angle) * 100 - 45, // rad = 130, center = 130
                top:
                    130 +
                    sin(angle) * 100 -
                    45 +
                    50, // Added +50 to roughly align center, maybe layout builder needed
                child: Builder(
                  builder: (btnContext) {
                    bool isArrowTarget = _arrowTarget == idx;
                    return GestureDetector(
                      onTapDown: (details) {
                        RenderBox box =
                            btnContext.findRenderObject() as RenderBox;
                        Offset position = box.localToGlobal(Offset.zero);
                        _handleShoot(opt, idx, position);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isArrowTarget
                              ? Colors.green
                              : const Color(0xFF020617),
                          border: Border.all(color: Colors.white30, width: 3),
                          boxShadow: [
                            if (isArrowTarget)
                              const BoxShadow(
                                color: Colors.green,
                                blurRadius: 20,
                              ),
                            const BoxShadow(
                              color: Colors.black54,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          opt['label'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

          if (!_gameWon &&
              _gameState != 'select_target' &&
              _gameState != 'tutorial')
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[700],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.star, color: Colors.white),
            ),

          if (_isAnimating && _arrowTarget != null) _buildFlyingDart(),

          if (_gameWon)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.2),
                      border: Border.all(color: Colors.green, width: 4),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 80,
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),
                  const SizedBox(height: 20),
                  ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                        ),
                        onPressed: _nextLevel,
                        child: const Text(
                          "Siguiente Reto",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlyingDart() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A simple animation of an icon flying to the target
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth / 2 - 24,
                bottom: -20,
                child:
                    const Icon(
                          Icons.change_history,
                          color: Colors.red,
                          size: 48,
                        )
                        .animate()
                        .move(
                          duration: 500.ms,
                          curve: Curves.easeInQuad,
                          end: Offset(
                            _shotEnd.dx - constraints.maxWidth / 2,
                            _shotEnd.dy - constraints.maxHeight,
                          ),
                        )
                        .scale(end: const Offset(0.2, 0.2))
                        .fadeOut(delay: 400.ms),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 50),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.blueAccent,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _eq['tutorial']['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Teoría Matemática",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _eq['tutorial']['theory'],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Instrucciones de Juego",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _eq['tutorial']['instruction'],
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => setState(() => _gameState = 'select_target'),
                child: const Text(
                  "¡Entendido, a jugar!",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildActivationFlash() {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.greenAccent, Colors.green],
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(color: Colors.green, blurRadius: 40),
                  ],
                  border: Border.all(color: Colors.white54, width: 4),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "¡RULETA ACTIVADA!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      "¡Apunta y dispara a la operación inversa!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut)
              .fadeOut(delay: 1500.ms, duration: 500.ms),
    );
  }
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

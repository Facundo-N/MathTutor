import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math';
import '../../models/ai_exercise_model.dart';

final List<Map<String, dynamic>> gameLevels = [
  {
    'id': 1,
    'title': "Nivel 1: Ecuaciones Lineales (ax + b = c)",
    'tutorial': {
      'formula': [
        {'val': "a", 'type': "num-blue"},
        {'val': "x", 'type': "var"},
        {'val': "+ b", 'type': "num"},
        {'val': "=", 'type': "eq"},
        {'val': "c", 'type': "num-red"},
      ],
      'theory':
          "Una ecuación lineal es como una balanza perfecta. Nuestro objetivo es dejar a la 'x' sola. Mueve los números al otro lado usando su operación inversa (contraria).",
      'gameplay':
          "Toca la operación correcta en los caramelos de abajo para anular el número que estorba. ¡Lo que haces de un lado, se hace del otro!",
    },
    'initialEq': [
      {'val': "x", 'type': "var"},
      {'val': "+ 5", 'type': "num"},
      {'val': "=", 'type': "eq"},
      {'val': "12", 'type': "num"},
    ],
    'steps': [
      {
        'stepType': "equality",
        'explanation':
            "¡A jugar! Para eliminar '+ 5', ¿qué aplicamos en AMBOS lados?",
        'correctAction': "- 5",
        'options': ["+ 5", "* 5", "- 5"],
        'cancelIndex': 1,
        'resultExplanation':
            "¡Perfecto! Aplicamos '- 5' en ambos lados (+5 - 5 = 0). Ahora resuelve la derecha: ¿Cuánto es 12 - 5?",
        'correctResult': "7",
        'resultOptions': ["17", "7", "6"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "x", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "7", 'type': "num"},
        ],
      },
    ],
  },
  {
    'id': 2,
    'title': "Nivel 2: Propiedad Distributiva",
    'tutorial': {
      'formula': [
        {'val': "a", 'type': "distribute-factor"},
        {'val': "( x + b )", 'type': "var-wide"},
        {'val': "=", 'type': "eq"},
        {'val': "c", 'type': "num-red"},
      ],
      'theory':
          "Cuando un número está pegado a un paréntesis, ¡multiplica a todo adentro! Es como si repartiera su valor equitativamente a cada elemento.",
      'gameplay':
          "Selecciona el caramelo que dice 'Distribuir' para ver cómo el número vuela y se multiplica por cada término de adentro.",
    },
    'initialEq': [
      {'val': "2", 'type': "distribute-factor"},
      {'val': "(x + 3)", 'type': "var-wide"},
      {'val': "=", 'type': "eq"},
      {'val': "14", 'type': "num"},
    ],
    'steps': [
      {
        'stepType': "distribute",
        'explanation':
            "¡Aplica la propiedad! El 2 salta y se reparte a cada elemento del paréntesis.",
        'correctAction': "Distribuir 2",
        'options': ["Sumar 2", "Distribuir 2", "Dividir 2"],
        'targetIndex': 0,
        'resultExplanation':
            "¡Magia! 2*x es 2x. Ahora resuelve la otra multiplicación: ¿Cuánto es 2 * 3?",
        'correctResult': "6",
        'resultOptions': ["5", "6", "9"],
        'questionMarkIndex': 1,
        'resultingEq': [
          {'val': "2x", 'type': "var"},
          {'val': "+ 6", 'type': "num"},
          {'val': "=", 'type': "eq"},
          {'val': "14", 'type': "num"},
        ],
      },
      {
        'stepType': "equality",
        'explanation':
            "¡Ya es una ecuación lineal! Apliquemos la Regla de la Balanza. Para eliminar el '+ 6', ¿qué hacemos en ambos lados?",
        'correctAction': "- 6",
        'options': ["- 6", "+ 6", "/ 2"],
        'cancelIndex': 1,
        'resultExplanation':
            "Se canceló a la izquierda. ¿Cuánto es 14 - 6 a la derecha?",
        'correctResult': "8",
        'resultOptions': ["8", "10", "20"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "2x", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "8", 'type': "num"},
        ],
      },
      {
        'stepType': "equality",
        'explanation':
            "El 2 multiplica a la 'x'. Para dejarla libre y mantener la igualdad, ¿qué aplicamos?",
        'correctAction': "/ 2",
        'options': ["- 2", "* 2", "/ 2"],
        'cancelIndex': 0,
        'resultExplanation':
            "2x / 2 es solo 'x'. Y del otro lado: ¿Cuánto es 8 / 2?",
        'correctResult': "4",
        'resultOptions': ["6", "4", "16"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "x", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "4", 'type': "num"},
        ],
      },
    ],
  },
  {
    'id': 3,
    'title': "Nivel 3: Ecuaciones Cuadráticas (x²)",
    'tutorial': {
      'formula': [
        {'val': "a x²", 'type': "var"},
        {'val': "+ b", 'type': "num"},
        {'val': "=", 'type': "eq"},
        {'val': "c", 'type': "num-red"},
      ],
      'theory':
          "El exponente ² significa que un número se multiplicó por sí mismo (x * x). La única forma de destruir este poder y liberar a la 'x' es usando su operación inversa exacta: ¡La Raíz Cuadrada (√)!",
      'gameplay':
          "Primero despeja los números normales. Cuando la x² esté sola, ¡libera el poder de la raíz cuadrada (√) en los caramelos!",
    },
    'initialEq': [
      {'val': "x²", 'type': "var"},
      {'val': "- 9", 'type': "num-red"},
      {'val': "=", 'type': "eq"},
      {'val': "0", 'type': "num"},
    ],
    'steps': [
      {
        'stepType': "equality",
        'explanation':
            "Primero, movamos el número. Para anular el '- 9' y mantener el equilibrio en la balanza, aplicamos...",
        'correctAction': "+ 9",
        'options': ["- 9", "+ 9", "√9"],
        'cancelIndex': 1,
        'resultExplanation':
            "Excelente. 0 + 9 es fácil. Selecciona la respuesta para el lado derecho.",
        'correctResult': "9",
        'resultOptions': ["0", "9", "-9"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "x²", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "9", 'type': "num"},
        ],
      },
      {
        'stepType': "root_square",
        'explanation': "¡Es hora! Usa el poder destructor del exponente 2.",
        'correctAction': "Aplicar √",
        'options': ["Dividir / 2", "Aplicar √", "Restar 2"],
        'targetIndex': 0,
        'resultExplanation':
            "¡La raíz liberó a la 'x'! Ahora del lado derecho: ¿Qué número multiplicado por sí mismo (x * x) da 9?",
        'correctResult': "3",
        'resultOptions': ["4.5", "3", "81"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "x", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "3", 'type': "num"},
        ],
      },
    ],
  },
  {
    'id': 4,
    'title': "Nivel 4: Factorización (Factor Común)",
    'tutorial': {
      'formula': [
        {'val': "a x²", 'type': "var"},
        {'val': "+ b x", 'type': "num"},
        {'val': "=", 'type': "eq"},
        {'val': "0", 'type': "num"},
      ],
      'theory':
          "Factorizar es buscar qué tienen en común los términos (como piezas de Lego compartidas) y 'sacarlo' hacia afuera aislando los restos dentro de un paréntesis.",
      'gameplay':
          "Busca la opción que extraiga la mayor cantidad de 'x' y números que AMBOS términos comparten. ¡Saldrán volando hacia afuera!",
    },
    'initialEq': [
      {'val': "3x²", 'type': "var"},
      {'val': "+ 12x", 'type': "num"},
      {'val': "=", 'type': "eq"},
      {'val': "0", 'type': "num"},
    ],
    'steps': [
      {
        'stepType': "factorize",
        'explanation':
            "3x² y 12x comparten el '3x'. Vamos a 'extraer' ese ingrediente común hacia afuera.",
        'correctAction': "Extraer 3x",
        'options': ["Restar 12x", "Dividir / 3", "Extraer 3x"],
        'targetIndex': 0,
        'resultExplanation':
            "Si a 3x² le sacamos 3x queda 'x'. Si a 12x le sacamos 3x (12 entre 3)... ¿Qué número queda adentro del paréntesis?",
        'correctResult': "4",
        'resultOptions': ["9", "4", "36"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "3x", 'type': "distribute-factor"},
          {'val': "(x", 'type': "var"},
          {'val': "+ 4)", 'type': "num"},
          {'val': "=", 'type': "eq"},
          {'val': "0", 'type': "num"},
        ],
      },
    ],
  },
  {
    'id': 5,
    'title': "Nivel 5: Ecuaciones Cúbicas (x³)",
    'tutorial': {
      'formula': [
        {'val': "a x³", 'type': "var"},
        {'val': "=", 'type': "eq"},
        {'val': "c", 'type': "num-red"},
      ],
      'theory':
          "El exponente ³ representa el volumen de un cubo. Para descubrir el valor de un solo lado (x), invocamos a la poderosa Raíz Cúbica (∛).",
      'gameplay':
          "Usa la balanza para aislar la x³, y finalmente lanza la raíz cúbica en los caramelos para resolver el misterio tridimensional.",
    },
    'initialEq': [
      {'val': "2x³", 'type': "var"},
      {'val': "=", 'type': "eq"},
      {'val': "16", 'type': "num"},
    ],
    'steps': [
      {
        'stepType': "equality",
        'explanation':
            "Despejemos primero. El 2 está multiplicando. Ya sabes qué hacer.",
        'correctAction': "/ 2",
        'options': ["- 2", "√2", "/ 2"],
        'cancelIndex': 0,
        'resultExplanation':
            "2x³ / 2 es x³. ¿Y del otro lado? ¿Cuánto es 16 / 2?",
        'correctResult': "8",
        'resultOptions': ["14", "8", "32"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "x³", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "8", 'type': "num"},
        ],
      },
      {
        'stepType': "root_cubic",
        'explanation':
            "Lanza la operación destructora del cubo para liberar la 'x'.",
        'correctAction': "Aplicar ∛",
        'options': ["Aplicar √", "Dividir / 3", "Aplicar ∛"],
        'targetIndex': 0,
        'resultExplanation':
            "∛ envolvió la ecuación. Piensa bien: ¿Qué número multiplicado 3 veces por sí mismo (? * ? * ?) da 8?",
        'correctResult': "2",
        'resultOptions': ["2.6", "4", "2"],
        'questionMarkIndex': 2,
        'resultingEq': [
          {'val': "x", 'type': "var"},
          {'val': "=", 'type': "eq"},
          {'val': "2", 'type': "num"},
        ],
      },
    ],
  },
];

const praises = [
  "¡SABROSO!",
  "¡DULCE MATEMÁTICA!",
  "¡CEREBRO BRILLANTE!",
  "¡ÉPICO!",
  "¡LOGICA PURA!",
];

class EquationPartState {
  final String val;
  final String type;
  bool isNew;
  bool isRightSide;

  EquationPartState({
    required this.val,
    required this.type,
    this.isNew = false,
    this.isRightSide = false,
  });

  factory EquationPartState.fromMap(Map<String, dynamic> map) {
    return EquationPartState(val: map['val'], type: map['type']);
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class CandyMathTemplate extends StatefulWidget {
  final dynamic exercise;
  final VoidCallback onStepCompleted;
  final VoidCallback onExerciseCompleted;
  final Function(int) onLivesChanged;

  const CandyMathTemplate({
    super.key,
    required this.exercise,
    required this.onStepCompleted,
    required this.onExerciseCompleted,
    required this.onLivesChanged,
  });

  @override
  State<CandyMathTemplate> createState() => _CandyMathTemplateState();
}

class _CandyMathTemplateState extends State<CandyMathTemplate>
    with TickerProviderStateMixin {
  String _gameState =
      'menu'; // menu, tutorial, intro, playing_op, animating_op, playing_res, animating_success, level_complete, game_over
  int _levelIndex = 0;
  int _stepIndex = 0;
  int _score = 0;
  int _lives = 5; // Initial lives for demo

  List<EquationPartState> _equationParts = [];
  String? _shakingCandyOption;
  String? _floatingTextTitle;

  // Hint system
  int _consecutiveErrors = 0;
  bool _showHint = false;

  final List<Particle> _particles = [];
  Timer? _particleTimer;

  Map<String, dynamic>? _runtimeLevelData;

  String _formatNum(double n) {
    if ((n - n.round()).abs() < 0.001) {
      return n.round().toString();
    }
    String s = n.toStringAsFixed(1);
    return s.replaceAll('.', ',');
  }

  Map<String, dynamic> get currentLevel {
    if (_runtimeLevelData != null) return _runtimeLevelData!;
    if (widget.exercise is AIExercise) {
      final ai = widget.exercise as AIExercise;
      return {
        'id': 0,
        'title': ai.storyContext.isNotEmpty
            ? ai.storyContext
            : "Desafío de Banny",
        'initialEq': ai.uiConfig?['initialEq'],
        'steps': ai.uiConfig?['steps'],
        'tutorial': ai.uiConfig?['tutorial'],
      };
    }
    if (widget.exercise != null && widget.exercise is Map<String, dynamic>) {
      return widget.exercise;
    }
    return gameLevels[_levelIndex];
  }

  Map<String, dynamic> get currentStep {
    final steps = currentLevel['steps'];
    if (steps == null || steps is! List || steps.isEmpty) {
      return {};
    }
    return steps.elementAt(_stepIndex);
  }

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _particleTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startLevelTutorial(int lIndex) {
    setState(() {
      _levelIndex = lIndex;
      _runtimeLevelData = null; // Reiniciar para el nuevo nivel
    });

    if (currentLevel['tutorial'] == null) {
      _startLevelGameplay();
    } else {
      setState(() {
        _gameState = 'tutorial';
      });
    }
  }

  double _parseNum(String s) {
    if (s.isEmpty || s == "+" || s == "-") return 1.0;
    return double.tryParse(s.replaceAll(',', '.')) ?? 0.0;
  }

  List<Map<String, dynamic>> _parseRawEquation(String eq) {
    // Parser simple para CandyMath
    // Ejemplo: "2(x + 3) = 14" -> [{'val': "2", 'type': "distribute-factor"}, {'val': "(x + 3)", 'type': "var-wide"}, ...]
    final List<Map<String, dynamic>> parts = [];

    // Limpieza básica y normalización de unicode
    eq = eq.replaceAll(' ', '').replaceAll('²', '^2').replaceAll('³', '^3');

    // Regex para detectar patrones comunes
    final distributeMatch = RegExp(r'^(\d+)\((.+)\)=(.*)$').firstMatch(eq);
    final factorizeMatch = RegExp(
      r'^(\d*x\^?2)([+-]\d*x)=(.*)$',
    ).firstMatch(eq);
    final matchHigh = RegExp(
      r'^([+-]?\d*)([a-zA-Z]+)\^([23])([+-]\d+)?=(-?\d+)$',
    ).firstMatch(eq);

    if (distributeMatch != null) {
      parts.add({
        'val': distributeMatch.group(1)!,
        'type': "distribute-factor",
      });
      parts.add({'val': "(${distributeMatch.group(2)!})", 'type': "var-wide"});
      parts.add({'val': "=", 'type': "eq"});
      parts.add({'val': distributeMatch.group(3)!, 'type': "num"});
    } else if (factorizeMatch != null) {
      parts.add({'val': factorizeMatch.group(1)!, 'type': "var"});
      parts.add({'val': factorizeMatch.group(2)!, 'type': "num"});
      parts.add({'val': "=", 'type': "eq"});
      parts.add({'val': factorizeMatch.group(3)!, 'type': "num"});
    } else if (matchHigh != null) {
      String aStr = matchHigh.group(1)!;
      if (aStr == '-') aStr = '-1';
      if (aStr.isNotEmpty && aStr != '+' && aStr != '1' && aStr != '-1') {
        parts.add({'val': matchHigh.group(1)!, 'type': "num"});
      } else if (aStr == '-1') {
        parts.add({'val': "-", 'type': "num"});
      }

      parts.add({
        'val': '${matchHigh.group(2)!}^${matchHigh.group(3)!}',
        'type': "var",
      });

      if (matchHigh.group(4) != null) {
        parts.add({'val': matchHigh.group(4)!, 'type': "num"});
      }
      parts.add({'val': "=", 'type': "eq"});
      parts.add({'val': matchHigh.group(5)!, 'type': "num"});
    } else {
      // Ecuación lineal estándar: x + 5 = 12
      final linearMatch = RegExp(
        r'^([a-zA-Z0-9]+)([+-]\d+)?=(.*)$',
      ).firstMatch(eq);
      if (linearMatch != null) {
        parts.add({'val': linearMatch.group(1)!, 'type': "var"});
        if (linearMatch.group(2) != null) {
          parts.add({'val': linearMatch.group(2)!, 'type': "num"});
        }
        parts.add({'val': "=", 'type': "eq"});
        parts.add({'val': linearMatch.group(3)!, 'type': "num"});
      } else {
        // Fallback si nada coincide
        parts.add({'val': eq, 'type': "var"});
      }
    }
    return parts;
  }

  List<Map<String, dynamic>> _generateDynamicSteps(String equationStr) {
    final List<Map<String, dynamic>> steps = [];
    String eq = equationStr
        .replaceAll(' ', '')
        .replaceAll('²', '^2')
        .replaceAll('³', '^3');

    final distributeMatch = RegExp(r'^(\d+)\((.+)\)=(.*)$').firstMatch(eq);
    final matchHigh = RegExp(
      r'^([+-]?\d*)([a-zA-Z]+)\^([23])([+-]\d+)?=(-?\d+)$',
    ).firstMatch(eq);
    final linearMatch = RegExp(
      r'^([a-zA-Z0-9]+)([+-]\d+)=(.*)$',
    ).firstMatch(eq);
    final multMatch = RegExp(r'^(\d+)([a-zA-Z]+)=(.*)$').firstMatch(eq);

    if (distributeMatch != null) {
      steps.add({
        'stepType': "distribute",
        'explanation': "¡Cápsula de Distribuir! Reparte el valor de afuera.",
        'correctAction': "Distribuir",
        'options': ["Sumar", "Distribuir", "Restar"],
        'targetIndex': 0,
        'resultExplanation': "¿Cuánto es la multiplicación?",
        'correctResult': "OK",
        'resultOptions': ["OK", "FAIL"],
        'resultingEq': _parseRawEquation(
          eq.replaceAll('(', '').replaceAll(')', ''),
        ), // Simplificación extrema
      });
    } else if (matchHigh != null) {
      String aStr = matchHigh.group(1)!;
      final String literal = matchHigh.group(2)!;
      final int exp = matchHigh.group(3) == '3' ? 3 : 2;
      final String rootSym = exp == 3 ? 'Aplicar ∛' : 'Aplicar √';
      final String? opText = matchHigh.group(4);
      final String rightStr = matchHigh.group(5)!;

      if (aStr.isEmpty || aStr == '+') aStr = '1';
      if (aStr == '-') aStr = '-1';
      final double a = _parseNum(aStr);

      final bool hasOp = opText != null;
      final String op = hasOp ? opText.substring(0, 1) : '+';
      final double opVal = hasOp ? _parseNum(opText.substring(1)) : 0.0;
      final double rightNum = _parseNum(rightStr);

      final double afterOp = hasOp
          ? (op == '+' ? rightNum - opVal : rightNum + opVal)
          : rightNum;

      final double underRoot = a != 1
          ? (afterOp.toDouble() / a)
          : afterOp.toDouble();

      final double resFinal = exp == 3
          ? (underRoot >= 0 ? underRoot : underRoot.abs())
          : underRoot;

      final double exactAns = exp == 3
          ? (underRoot >= 0
                ? pow(underRoot, 1 / 3).toDouble()
                : -pow(underRoot.abs(), 1 / 3).toDouble())
          : (underRoot >= 0 ? sqrt(resFinal) : 0);
      final String ansStr = _formatNum(exactAns);

      // Paso 1: Mover constante (si existe)
      if (hasOp) {
        String inverseOp = op == '+' ? '-' : '+';
        String correctAction = "$inverseOp${_formatNum(opVal.toDouble())}";
        steps.add({
          'stepType': "equality",
          'explanation':
              "¿Qué operación inversa aplicamos para cancelar el $opText?",
          'correctAction': correctAction,
          'options': ["+$opVal", "-$opVal", "*$opVal", "/$opVal"],
          'cancelIndex': a != 1
              ? 2
              : 1, // El index depende de si a está partido o no
          'resultExplanation':
              "¿Cuánto es $rightStr $inverseOp ${_formatNum(opVal.toDouble())}?",
          'correctResult': _formatNum(afterOp.toDouble()),
          'resultOptions': [
            _formatNum(afterOp.toDouble()),
            _formatNum(afterOp.toDouble() + 1.0),
            _formatNum((afterOp.toDouble() - 0.5).abs()),
          ]..shuffle(),
          'intermediateEq': [
            if (a != 1) {'val': aStr, 'type': 'num'},
            {'val': '$literal^$exp', 'type': 'var'},
            {'val': '=', 'type': 'eq'},
            {'val': rightStr, 'type': 'num'},
            {'val': correctAction, 'type': 'action'},
          ],
          'resultingEq': [
            if (a != 1) {'val': aStr, 'type': 'num'},
            {'val': '$literal^$exp', 'type': 'var'},
            {'val': '=', 'type': 'eq'},
            {'val': _formatNum(afterOp.toDouble()), 'type': 'num'},
          ],
        });
      }

      // Paso 2: Dividir coeficiente
      if (a != 1) {
        steps.add({
          'stepType': "equality",
          'explanation':
              "El número $aStr multiplica a la literal. ¿Cómo lo cancelamos?",
          'correctAction': "/$aStr",
          'options': ["+$aStr", "-$aStr", "*$aStr", "/$aStr"],
          'cancelIndex': 0,
          'resultExplanation':
              "¿Cuánto es ${_formatNum(afterOp.toDouble())} / ${_formatNum(a.toDouble())}?",
          'correctResult': _formatNum(underRoot),
          'resultOptions': [
            _formatNum(underRoot),
            _formatNum(underRoot + 2.5),
            _formatNum((underRoot - 1.2).abs()),
          ]..shuffle(),
          'intermediateEq': [
            {'val': '$literal^$exp', 'type': 'var'},
            {'val': '=', 'type': 'eq'},
            {'val': afterOp.toString(), 'type': 'num'},
            {'val': "/$aStr", 'type': 'action'},
          ],
          'resultingEq': [
            if (a != 1) {'val': _formatNum(a.toDouble()), 'type': 'num'},
            {'val': '$literal^$exp', 'type': 'var'},
            {'val': '=', 'type': 'eq'},
            {'val': _formatNum(underRoot), 'type': 'num'},
          ],
        });
      }

      // Paso 3: Aplicar raíz
      final double d1 = exactAns + 1.0;
      final double d2 = (exactAns - 1.0).abs() > 0.1
          ? exactAns - 1.0
          : exactAns + 2.0;
      final String dis1 = _formatNum(d1);
      final String dis2 = _formatNum(d2);
      final List<String> rootResultOptions = [ansStr, dis1, dis2]..shuffle();
      steps.add({
        'stepType': "root_square",
        'explanation':
            "¡Conecta con la Raíz Suprema para desintegrar el exponente!",
        'correctAction': rootSym,
        'options': ["/ $exp", rootSym, "- $exp"],
        'targetIndex': 0,
        'resultExplanation':
            "¿Cuánto vale $literal después de aplicar la raíz?",
        'correctResult': ansStr,
        'resultOptions': rootResultOptions,
        'questionMarkIndex': 2,
        // Mostrar x=? mientras el usuario selecciona el resultado
        'intermediateEq': [
          {'val': literal, 'type': 'var'},
          {'val': '=', 'type': 'eq'},
          {'val': '?', 'type': 'num'},
        ],
        // Mostrar la respuesta final cuando ya la seleccionó
        'resultingEq': [
          {'val': literal, 'type': 'var'},
          {'val': '=', 'type': 'eq'},
          {'val': ansStr, 'type': 'num'},
        ],
      });
    } else if (linearMatch != null) {
      String varPart = linearMatch.group(1)!;
      String opText = linearMatch.group(2)!; // ej: "+5"
      String rightSideStr = linearMatch.group(3)!;

      String op = opText.substring(0, 1);
      String numStr = opText.substring(1);
      double rightNum =
          double.tryParse(rightSideStr.replaceAll(',', '.')) ?? 0.0;
      double opNum = double.tryParse(numStr.replaceAll(',', '.')) ?? 0.0;

      String inverseOp = op == '+' ? '-' : '+';
      String correctAction = "$inverseOp$numStr";

      double correctResNum = op == '+'
          ? rightNum.toDouble() - opNum.toDouble()
          : rightNum.toDouble() + opNum.toDouble();
      String correctResStr = _formatNum(correctResNum);

      steps.add({
        'stepType': "equality",
        'explanation':
            "¿Qué operación inversa aplicamos para cancelar el $opText?",
        'correctAction': correctAction,
        'options': ["+$numStr", "-$numStr", "*$numStr", "/$numStr"],
        'cancelIndex': 1,
        'resultExplanation':
            "¿Cuánto es $rightSideStr $inverseOp ${_formatNum(opNum.toDouble())}?",
        'correctResult': correctResStr,
        'resultOptions': [
          correctResStr,
          _formatNum(correctResNum + 1.2),
          _formatNum(correctResNum - 0.5),
        ]..shuffle(),
        'intermediateEq': [
          {'val': varPart, 'type': 'var'},
          {'val': '=', 'type': 'eq'},
          {'val': rightSideStr, 'type': 'num'},
          {'val': correctAction, 'type': 'action'},
        ],
        'resultingEq': [
          {'val': varPart, 'type': 'var'},
          {'val': '=', 'type': 'eq'},
          {'val': correctResStr, 'type': 'num'},
        ],
      });
    } else if (multMatch != null) {
      String numStr = multMatch.group(1)!;
      String rightSideStr = multMatch.group(3)!;

      double rightNum =
          double.tryParse(rightSideStr.replaceAll(',', '.')) ?? 0.0;
      double opNum =
          double.tryParse(numStr.replaceAll(',', '.')) ??
          1.0; // avoid division by zero

      double correctResNum = opNum != 0 ? rightNum / opNum : rightNum;
      String correctResStr = _formatNum(correctResNum);

      steps.add({
        'stepType': "equality",
        'explanation':
            "El número está multiplicando a la literal. ¿Cómo lo cancelamos?",
        'correctAction': "/$numStr",
        'options': ["+$numStr", "-$numStr", "*$numStr", "/$numStr"],
        'cancelIndex': 0,
        'resultExplanation': "¿Cuánto es $rightSideStr / $numStr?",
        'correctResult': correctResStr,
        'resultOptions': [
          correctResStr,
          _formatNum(correctResNum + 2.1),
          _formatNum((correctResNum - 1.5).abs()),
        ]..shuffle(),
        'intermediateEq': [
          {'val': multMatch.group(2)!, 'type': 'var'},
          {'val': '=', 'type': 'eq'},
          {'val': rightSideStr, 'type': 'num'},
          {'val': "/$numStr", 'type': 'action'},
        ],
        'resultingEq': [
          {'val': multMatch.group(2)!, 'type': 'var'},
          {'val': '=', 'type': 'eq'},
          {'val': correctResStr, 'type': 'num'},
        ],
      });
    } else {
      final match = RegExp(r'([+-])(\d+)').firstMatch(eq);
      if (match != null) {
        String op = match.group(1)!;
        String numStr = match.group(2)!;
        String inverseOp = op == '+' ? '-' : '+';
        steps.add({
          'stepType': "equality",
          'explanation': "¿Qué operación inversa aplicamos?",
          'correctAction': "$inverseOp$numStr",
          'options': ["+$numStr", "-$numStr", "*$numStr", "/$numStr"],
          'cancelIndex': 1,
          'resultOptions': ["OK"],
        });
      } else {
        steps.add({
          'stepType': "equality",
          'explanation': "¿Qué operación inversa aplicamos?",
          'correctAction': eq.contains('+') ? "-" : "+",
          'options': ["+", "-", "*", "/"],
          'cancelIndex': 1,
          'resultOptions': ["OK"],
        });
      }
    }
    return steps;
  }

  void _startLevelGameplay() {
    setState(() {
      // Tomamos los datos base del getter (que mira widget.exercise o gameLevels)
      final baseData = currentLevel;
      var initialData = baseData['initialEq'];
      var stepsData = baseData['steps'];

      // CandyMath relies on its custom dynamic step generator for interactive gameplay options
      if (widget.exercise is AIExercise) {
        final ai = widget.exercise as AIExercise;
        initialData = _parseRawEquation(ai.equation);
        stepsData = _generateDynamicSteps(ai.equation);
      }

      // Consolidamos en _runtimeLevelData para que currentLevel/currentStep sean estables
      _runtimeLevelData = {
        'id': _levelIndex,
        'title': baseData['title'] ?? "Desafío",
        'initialEq': initialData,
        'steps': stepsData,
        'tutorial': baseData['tutorial'],
      };

      if (initialData != null &&
          initialData is List &&
          initialData.isNotEmpty) {
        _equationParts = initialData
            .map((e) => EquationPartState.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        // Fallback a niveles estáticos
        _equationParts = (gameLevels[_levelIndex]['initialEq'] as List)
            .map((e) => EquationPartState.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      _stepIndex = 0;
      _gameState = 'playing_op';
    });
  }

  void _spawnParticles(double startX, double startY) {
    final rand = Random();
    final colors = [
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];

    final newParticles = List.generate(30, (i) {
      return Particle(
        x: startX,
        y: startY,
        vx: (rand.nextDouble() - 0.5) * 40,
        vy: (rand.nextDouble() - 0.5) * 40 - 10,
        color: colors[rand.nextInt(colors.length)],
        size: rand.nextDouble() * 10 + 5,
      );
    });

    setState(() {
      _particles.addAll(newParticles);
    });

    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      bool allDead = true;
      setState(() {
        for (var p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 2.0; // Gravity
          p.size *= 0.95; // Shrink
          if (p.size > 0.5) {
            allDead = false;
          }
        }
      });
      if (allDead) {
        timer.cancel();
        setState(() {
          _particles.clear();
        });
      }
    });
  }

  void _handleError(String optionText) {
    setState(() {
      _shakingCandyOption = optionText;
      _consecutiveErrors++;

      if (_consecutiveErrors >= 3) {
        _showHint = true;
      }

      // _lives no se descuentan temporalmente para probar el sistema de pistas
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _shakingCandyOption = null);
    });
  }

  void _handleCandyClick(String optionText, BuildContext context) {
    if (_gameState != 'playing_op' && _gameState != 'playing_res') return;

    if (_gameState == 'playing_op') {
      if (optionText == currentStep['correctAction']) {
        setState(() {
          _gameState = 'animating_op';
          _consecutiveErrors = 0;
          _showHint = false;
        });

        // Logic for intermediate steps vs direct jumps
        bool hasIntermediateStep = [
          'equality',
          'multiplication',
          'division',
        ].contains(currentStep['stepType']);
        int waitTime = hasIntermediateStep ? 3200 : 2500;

        Timer(Duration(milliseconds: waitTime), () {
          if (mounted) {
            setState(() {
              if (currentStep['intermediateEq'] != null) {
                _equationParts = (currentStep['intermediateEq'] as List)
                    .map(
                      (e) =>
                          EquationPartState.fromMap(e as Map<String, dynamic>),
                    )
                    .toList();
              } else if (currentStep['resultingEq'] != null) {
                _equationParts = (currentStep['resultingEq'] as List)
                    .map(
                      (e) =>
                          EquationPartState.fromMap(e as Map<String, dynamic>),
                    )
                    .toList();
              } else if (hasIntermediateStep) {
                // Fallback: If no equation is provided, just clear or show the intermediate action
                // A proper dynamic generator would rebuild the equation here.
                _equationParts = [
                  EquationPartState(val: "?", type: "var"),
                  EquationPartState(val: "=", type: "eq"),
                  EquationPartState(val: "?", type: "num"),
                ];
              }

              if (hasIntermediateStep) {
                _gameState = 'playing_res';
              } else {
                // For distribute, factorize, roots, we might jump faster or handle success differently
                _gameState =
                    'playing_res'; // Keep consistent for now but allow for direct success if resultOptions are empty
                if (currentStep['resultOptions'] == null ||
                    (currentStep['resultOptions'] as List).isEmpty) {
                  _gameState = 'animating_success';
                  _score += 250;
                  _floatingTextTitle =
                      praises[Random().nextInt(praises.length)];
                  final size = MediaQuery.of(context).size;
                  _spawnParticles(size.width / 2, size.height / 3);
                  _proceedToNextStep();
                }
              }
            });
          }
        });
      } else {
        _handleError(optionText);
      }
    } else if (_gameState == 'playing_res') {
      if (optionText == currentStep['correctResult']) {
        setState(() {
          _gameState = 'animating_success';
          _consecutiveErrors = 0;
          _showHint = false;
          _score += 250;
          _floatingTextTitle = praises[Random().nextInt(praises.length)];

          if (currentStep['resultingEq'] != null) {
            _equationParts = (currentStep['resultingEq'] as List)
                .map(
                  (e) => EquationPartState.fromMap(e as Map<String, dynamic>),
                )
                .toList();
          }
        });

        final size = MediaQuery.of(context).size;
        _spawnParticles(size.width / 2, size.height / 3);

        Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            _proceedToNextStep();
          }
        });
      } else {
        _handleError(optionText);
      }
    }
  }

  void _proceedToNextStep() {
    final steps = currentLevel['steps'] as List;
    if (_stepIndex + 1 < steps.length) {
      setState(() {
        _stepIndex++;
        _gameState = 'intro';
      });
    } else {
      setState(() {
        _gameState = 'level_complete';
        _floatingTextTitle = null;
      });
    }
  }

  Widget _buildCandyButton(
    String text,
    BuildContext context, {
    required int idx,
  }) {
    final isInteractive =
        _gameState == 'playing_op' || _gameState == 'playing_res';
    final isShaking = _shakingCandyOption == text;

    // Hint logic
    bool isHinted = false;
    if (_showHint && isInteractive) {
      if (_gameState == 'playing_op' && text == currentStep['correctAction']) {
        isHinted = true;
      } else if (_gameState == 'playing_res' &&
          text == currentStep['correctResult']) {
        isHinted = true;
      }
    }

    Color startColor, endColor, shadowColor;
    if (idx % 3 == 0) {
      startColor = Colors.pink.shade400;
      endColor = Colors.pink.shade600;
      shadowColor = Colors.pink.shade800;
    } else if (idx % 3 == 1) {
      startColor = Colors.cyan.shade400;
      endColor = Colors.cyan.shade600;
      shadowColor = Colors.cyan.shade800;
    } else {
      startColor = Colors.purple.shade400;
      endColor = Colors.purple.shade600;
      shadowColor = Colors.purple.shade800;
    }

    if (isShaking) {
      startColor = Colors.red.shade500;
      endColor = Colors.red.shade700;
      shadowColor = Colors.red.shade900;
    }

    Widget btn = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.only(
        bottom: 12,
        left: 8,
        right: 8,
      ), // For 3D depth
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHinted
              ? [Colors.white70, Colors.white54]
              : [startColor, endColor],
        ),
        boxShadow: [
          // 3D Bottom Depth
          BoxShadow(
            color: isHinted ? Colors.white30 : shadowColor,
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
          // Radiant outer shadow
          BoxShadow(
            color: isHinted
                ? Colors.white.withValues(alpha: 0.8)
                : shadowColor.withValues(alpha: 0.5),
            offset: const Offset(0, 10),
            blurRadius: 15,
          ),
        ],
        border: isHinted ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -10,
            child: Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isHinted ? Colors.black87 : Colors.white,
              shadows: isHinted
                  ? []
                  : const [Shadow(color: Colors.black45, blurRadius: 5)],
            ),
          ),
        ],
      ),
    );

    if (isInteractive) {
      btn = GestureDetector(
        onTap: () => _handleCandyClick(text, context),
        child: btn,
      );
      if (isShaking) {
        btn = btn.animate().shakeX(hz: 8, amount: 5, duration: 800.ms);
      } else if (isHinted) {
        btn = btn
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .scaleXY(begin: 1.0, end: 1.1, duration: 600.ms)
            .then()
            .scaleXY(begin: 1.1, end: 1.0, duration: 600.ms);
      } else {
        btn = btn
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.05, duration: 1.seconds)
            .moveY(begin: 0, end: -3, duration: 1.seconds);
      }
    } else {
      btn = Opacity(opacity: 0.6, child: btn);
    }

    return btn;
  }

  Widget _renderEquationPart(
    EquationPartState part,
    int idx,
    BuildContext context,
  ) {
    bool isQuestionMark =
        _gameState == 'playing_res' &&
        idx == currentStep['questionMarkIndex'] &&
        part.type != 'action-root';
    String displayVal = part.val;
    if (isQuestionMark) {
      displayVal = part.val.contains(')') ? "+ ? )" : "?";
    } else if (_gameState == 'animating_op' &&
        currentStep['stepType'] == 'distribute' &&
        part.type == 'var-wide') {
      displayVal = "( 2*x + 2*3 )"; // Visual hint mapping
    } else if (_gameState == 'animating_op' &&
        currentStep['stepType'] == 'factorize') {
      if (idx == 0) displayVal = "( x";
      if (idx == 1) displayVal = "+ ? )";
    }

    Color bgColor = Colors.transparent;
    Color borderColor = Colors.transparent;
    Color textColor = Colors.white;
    List<BoxShadow> shadows = [];
    double paddingH = 12;
    double paddingV = 8;
    double fontSize = 32;
    FontWeight fWeight = FontWeight.w900;

    if (part.type == 'eq') {
      textColor = Colors.white.withValues(alpha: 0.9);
      paddingH = 4;
      fontSize = 38;
    } else {
      if (part.type == 'var') {
        bgColor = const Color(0xFF2A3143);
        borderColor = const Color(0xFF10131d);
        shadows = [
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ];
      } else if (part.type == 'var-wide') {
        bgColor = const Color(0xFF1C202F);
        borderColor = const Color(0xFF10131d);
        shadows = [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ];
        textColor = Colors.purple.shade200;
        paddingH = 20;
      } else if (part.type == 'num') {
        bgColor = const Color(0xFF4ade80);
        borderColor = const Color(0xFF1a5c28);
        shadows = [
          BoxShadow(
            color: const Color(0xFF28843B).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ];
      } else if (part.type == 'num-red') {
        bgColor = const Color(0xFFf87171);
        borderColor = const Color(0xFF8a1c1c);
        shadows = [
          BoxShadow(
            color: const Color(0xFFC62828).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ];
      } else if (part.type == 'num-blue') {
        bgColor = const Color(0xFF60a5fa);
        borderColor = const Color(0xFF1e3a8a);
        shadows = [
          BoxShadow(
            color: const Color(0xFF2563eb).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ];
      } else if (part.type == 'distribute-factor') {
        bgColor = Colors.purple.shade500;
        borderColor = Colors.indigo.shade900;
        shadows = [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ];
      } else if (part.type == 'action') {
        bgColor = Colors.purple.shade400;
        borderColor = Colors.purple.shade800;
        shadows = [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.8),
            blurRadius: 15,
          ),
        ];
        fontSize = 28;
      } else if (part.type == 'action-root') {
        bgColor = Colors.cyan.shade400;
        borderColor = Colors.blue.shade800;
        shadows = [
          BoxShadow(color: Colors.cyan.withValues(alpha: 0.8), blurRadius: 20),
        ];
        fontSize = 32;
        paddingH = 12;
        paddingV = 8;
      }

      if (isQuestionMark) {
        bgColor = const Color(0xFF1C202F);
        borderColor = Colors.yellow.shade400;
        textColor = Colors.yellow.shade300;
        shadows = [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.5),
            blurRadius: 15,
          ),
        ];
      }
    }

    if (part.type != 'eq') {
      shadows.insert(
        0,
        BoxShadow(
          color: borderColor,
          offset: const Offset(0, 6),
          blurRadius: 0,
        ),
      );
    }

    Widget content = Container(
      padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
      margin: const EdgeInsets.only(bottom: 8), // For 3D depth
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          30,
        ), // Increased to match candy buttons
        boxShadow: shadows,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (part.type != 'eq')
            Positioned(
              top: -4,
              child: Container(
                width: 24,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              displayVal,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: fWeight,
              ),
            ),
          ),
        ],
      ),
    );

    // Apply specific logic animations based on states
    if (_gameState == 'animating_op') {
      if (currentStep['stepType'] == 'equality') {
        if (part.type == 'action') {
          content = content
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1.2, 1.2),
                duration: 400.ms,
              )
              .then()
              .scaleXY(end: 1.0, duration: 200.ms);
          if (!part.isRightSide) {
            content = content
                .animate()
                .then(delay: 1000.ms)
                .scaleXY(end: 1.1, curve: Curves.easeOut, duration: 750.ms)
                .rotate(end: 5 / 360, duration: 750.ms)
                .tint(color: Colors.grey.shade400, duration: 750.ms)
                .then()
                .scaleXY(end: 0.0, curve: Curves.easeIn, duration: 750.ms)
                .fadeOut(duration: 750.ms)
                .custom(
                  duration: 750.ms,
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => Align(
                    alignment: Alignment.center,
                    widthFactor: 1.0 - value, // 1 to 0
                    heightFactor: 1.0 - value, // 1 to 0
                    child: child,
                  ),
                );
          }
        } else if (idx == currentStep['cancelIndex']) {
          content = content
              .animate()
              .then(delay: 1000.ms)
              .scaleXY(end: 1.1, curve: Curves.easeOut, duration: 750.ms)
              .rotate(end: 5 / 360, duration: 750.ms)
              .tint(color: Colors.grey.shade400, duration: 750.ms)
              .then()
              .scaleXY(end: 0.0, curve: Curves.easeIn, duration: 750.ms)
              .fadeOut(duration: 750.ms)
              .custom(
                duration: 750.ms,
                curve: Curves.easeInOut,
                builder: (context, value, child) => Align(
                  alignment: Alignment.center,
                  widthFactor: 1.0 - value, // 1 to 0
                  heightFactor: 1.0 - value, // 1 to 0
                  child: child,
                ),
              );
        }
      } else if (currentStep['stepType'] == 'root_square' ||
          currentStep['stepType'] == 'root_cubic') {
        if (part.type == 'action-root') {
          // Aparece en el mismo lugar del bloque (sin volar desde arriba)
          content = content
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1.2, 1.2),
                duration: 400.ms,
              )
              .then()
              .scaleXY(end: 1.0, duration: 200.ms)
              // Desaparece exactamente igual que el cancelIndex
              .then(delay: 600.ms)
              .scaleXY(end: 1.1, curve: Curves.easeOut, duration: 750.ms)
              .rotate(end: 5 / 360, duration: 750.ms)
              .tint(color: Colors.grey.shade400, duration: 750.ms)
              .then()
              .scaleXY(end: 0.0, curve: Curves.easeIn, duration: 750.ms)
              .fadeOut(duration: 750.ms)
              .custom(
                duration: 750.ms,
                curve: Curves.easeInOut,
                builder: (context, value, child) => Align(
                  alignment: Alignment.center,
                  widthFactor: 1.0 - value, // 1 to 0
                  heightFactor: 1.0 - value, // 1 to 0
                  child: child,
                ),
              );
        } else if (part.isRightSide && part.type == 'num') {
          // El número vibra y desaparece exactamente igual que el cancelIndex
          content = content
              .animate(delay: 1.0.seconds)
              .shakeX(hz: 8, amount: 5, duration: 400.ms)
              .then()
              .scaleXY(end: 1.1, curve: Curves.easeOut, duration: 750.ms)
              .rotate(end: 5 / 360, duration: 750.ms)
              .tint(color: Colors.grey.shade400, duration: 750.ms)
              .then()
              .scaleXY(end: 0.0, curve: Curves.easeIn, duration: 750.ms)
              .fadeOut(duration: 750.ms)
              .custom(
                duration: 750.ms,
                curve: Curves.easeInOut,
                builder: (context, value, child) => Align(
                  alignment: Alignment.center,
                  widthFactor: 1.0 - value, // 1 to 0
                  heightFactor: 1.0 - value, // 1 to 0
                  child: child,
                ),
              );
        }
      } else if (currentStep['stepType'] == 'distribute') {
        if (part.type == 'distribute-factor') {
          content = Opacity(opacity: 0.3, child: content);
        } else if (part.type == 'var-wide') {
          content = content.animate().scaleXY(end: 1.1, duration: 1.seconds);
        }
      }
    } else if (_gameState == 'animating_success' && part.type != 'eq') {
      content = content
          .animate()
          .rotate(
            begin: 0,
            end: 2, // 2 full turns
            duration: 1.seconds,
            curve: Curves.easeInOutBack,
          )
          .scaleXY(begin: 1.0, end: 1.3, duration: 500.ms)
          .then()
          .scaleXY(begin: 1.3, end: 1.0, duration: 500.ms);
    } else if ([
          'playing_op',
          'playing_res',
          'intro',
          'tutorial',
        ].contains(_gameState) &&
        part.type != 'eq') {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -3, end: 3, duration: 1500.ms);
    }

    return content;
  }

  Widget _buildEquationDisplay(
    BuildContext context,
    List<EquationPartState> parts,
  ) {
    List<EquationPartState> renderParts = List.from(parts);

    if (_showHint &&
        _gameState == 'playing_op' &&
        currentStep['intermediateEq'] != null) {
      // If hint is active and we have an intermediate equation, preview it
      renderParts = (currentStep['intermediateEq'] as List)
          .map((e) => EquationPartState.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    if (_gameState == 'animating_op') {
      if (currentStep['stepType'] == 'equality') {
        int eqIdx = renderParts.indexWhere((p) => p.type == 'eq');
        if (eqIdx != -1) {
          EquationPartState actionLeft = EquationPartState(
            val: currentStep['correctAction'],
            type: 'action',
            isNew: true,
          );
          EquationPartState actionRight = EquationPartState(
            val: currentStep['correctAction'],
            type: 'action',
            isNew: true,
            isRightSide: true,
          );
          renderParts.insert(eqIdx, actionLeft);
          renderParts.add(actionRight);
        }
      } else if (currentStep['stepType'] == 'root_square' ||
          currentStep['stepType'] == 'root_cubic') {
        String sym = currentStep['stepType'] == 'root_square' ? '√' : '∛';
        int eqIdx = renderParts.indexWhere((p) => p.type == 'eq');
        if (eqIdx != -1) {
          EquationPartState rootLeft = EquationPartState(
            val: sym,
            type: 'action-root',
            isNew: true,
          );
          EquationPartState rootRight = EquationPartState(
            val: sym,
            type: 'action-root',
            isNew: true,
            isRightSide: true, // attacks the number side
          );
          renderParts.insert(0, rootLeft); // decorative on left
          renderParts.add(rootRight); // attacks the number on the right
        }
      }
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 16,
          children: renderParts
              .asMap()
              .entries
              .map((e) => _renderEquationPart(e.value, e.key, context))
              .toList(),
        ),

        // Flying clones logic
        if (_gameState == 'animating_op' &&
            currentStep['stepType'] == 'distribute') ...[
          Positioned(
            child:
                _renderEquationPart(
                      EquationPartState(val: "2", type: "distribute-factor"),
                      0,
                      context,
                    )
                    .animate()
                    .moveX(
                      begin: -50,
                      end: 50,
                      duration: 2.seconds,
                      curve: Curves.linear,
                    )
                    .moveY(
                      begin: 0,
                      end: -60,
                      duration: 2.seconds,
                      curve: Curves.easeOutBack,
                    )
                    .fade(end: 0, duration: 2.seconds),
          ),
          Positioned(
            child:
                _renderEquationPart(
                      EquationPartState(val: "2", type: "distribute-factor"),
                      0,
                      context,
                    )
                    .animate()
                    .moveX(
                      begin: -50,
                      end: 120,
                      duration: 2.seconds,
                      curve: Curves.linear,
                    )
                    .moveY(
                      begin: 0,
                      end: -100,
                      duration: 2.seconds,
                      curve: Curves.easeOutBack,
                    )
                    .fade(end: 0, duration: 2.seconds),
          ),
        ],
        if (_gameState == 'animating_op' &&
            currentStep['stepType'] == 'factorize') ...[
          Positioned(
            left: 0,
            child:
                _renderEquationPart(
                      EquationPartState(val: "3x", type: "num"),
                      0,
                      context,
                    )
                    .animate()
                    .moveX(
                      begin: 50,
                      end: -100,
                      duration: 2.seconds,
                      curve: Curves.linear,
                    )
                    .moveY(
                      begin: 0,
                      end: -80,
                      duration: 2.seconds,
                      curve: Curves.easeOutBack,
                    )
                    .fade(end: 0, duration: 2.seconds),
          ),
          Positioned(
            left: 50,
            child:
                _renderEquationPart(
                      EquationPartState(val: "3x", type: "num"),
                      0,
                      context,
                    )
                    .animate()
                    .moveX(
                      begin: 100,
                      end: -150,
                      duration: 2.seconds,
                      curve: Curves.linear,
                    )
                    .moveY(
                      begin: 0,
                      end: -120,
                      duration: 2.seconds,
                      curve: Curves.easeOutBack,
                    )
                    .fade(end: 0, duration: 2.seconds),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E17),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.5),
                  radius: 1.0,
                  colors: [Color(0xFF311B92), Color(0xFF0A0E17)],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.amber,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "CandyMath",
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$_score",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: List.generate(
                                3,
                                (i) =>
                                    Icon(
                                          Icons.favorite_rounded,
                                          color: i < _lives
                                              ? Colors.redAccent
                                              : Colors.white24,
                                          size: 32,
                                        )
                                        .animate(
                                          onPlay: i < _lives
                                              ? (c) => c.repeat(reverse: true)
                                              : null,
                                        )
                                        .scaleXY(
                                          end: i < _lives ? 1.1 : 1.0,
                                          duration: 1.seconds,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Main Content Area
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16.0 : 48.0,
                          vertical: 24.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_gameState == 'menu')
                              _buildMenu()
                            else if (_gameState == 'tutorial')
                              _buildTutorial()
                            else if (_gameState == 'level_complete')
                              _buildLevelComplete()
                            else if (_gameState == 'game_over')
                              _buildGameOver()
                            else
                              _buildGamePlay(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Particles layer
            ..._particles.map(
              (p) => Positioned(
                left: p.x,
                top: p.y,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    color: p.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: p.color, blurRadius: 10)],
                  ),
                ),
              ),
            ),

            // Floating Text Praise
            if (_floatingTextTitle != null && _gameState == 'animating_success')
              Positioned(
                left: 0,
                right: 0,
                top: size.height * 0.3,
                child: Center(
                  child:
                      Text(
                            _floatingTextTitle!,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.amberAccent,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 15),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          )
                          .animate()
                          .moveY(begin: 50, end: -50, duration: 2.seconds)
                          .fadeOut(delay: 1.5.seconds, duration: 500.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.pinkAccent.withValues(alpha: 0.3),
          width: 4,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.school_rounded,
            color: Colors.amberAccent,
            size: 80,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1),
          const SizedBox(height: 24),
          const Text(
            "Aprende el PORQUÉ",
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Teoría animada, Factorización, Raíces y Distribución interactiva.",
            style: TextStyle(color: Colors.pinkAccent, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: Colors.green.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              elevation: 10,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 32),
            label: const Text(
              "¡EMPEZAR!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _startLevelTutorial(0),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
        ],
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0);
  }

  Widget _buildTutorial() {
    final tut = currentLevel['tutorial'];
    if (tut == null || tut['formula'] == null) {
      // Si no hay tutorial (ej: ejercicio dinámico sin tutorial), mostrar algo vacío o volver
      return const SizedBox.shrink();
    }
    final formulaParts = (tut['formula'] as List)
        .map((e) => EquationPartState.fromMap(e))
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.indigo.shade600],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.blue.shade300, width: 2),
          ),
          child: Text(
            currentLevel['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        _buildEquationDisplay(context, formulaParts),
        const SizedBox(height: 48),

        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 2,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  } else if (index == 1) {
                    value = 0.85; // Initial state for second page
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: index == 0
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.pinkAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.pinkAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Concepto",
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tut['theory'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.games_rounded,
                              color: Colors.cyanAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Mecánica",
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tut['gameplay'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              );
            },
          ),
        ),

        const SizedBox(height: 40),
        ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                elevation: 10,
              ),
              icon: const Icon(Icons.auto_awesome, size: 28),
              label: const Text(
                "¡Ir al Ejercicio!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              onPressed: _startLevelGameplay,
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -5, end: 5, duration: 2.seconds),
      ],
    ).animate().fadeIn();
  }

  Widget _buildGamePlay(BuildContext context) {
    String instructionText = "";
    List<String> options = [];

    if (_gameState == 'intro') {
      instructionText = currentStep['explanation'] ?? "";
    } else if (_gameState == 'playing_op') {
      options = (currentStep['options'] as List?)?.cast<String>() ?? [];
      if (currentStep['stepType'] == 'distribute') {
        instructionText = "¡Haz clic en Distribuir para repartir la magia!";
      } else if (currentStep['stepType'] == 'factorize') {
        instructionText = "¡Extrae el ingrediente en común!";
      } else if (currentStep['stepType'].toString().contains('root')) {
        instructionText = "¡Elige el poder destructivo!";
      } else {
        instructionText = "Elige la operación correcta";
      }
    } else if (_gameState == 'animating_op') {
      options = (currentStep['options'] as List?)?.cast<String>() ?? [];
      instructionText = "¡Aplicando magia matemática!";
    } else if (_gameState == 'playing_res' ||
        _gameState == 'animating_success') {
      options = (currentStep['resultOptions'] as List?)?.cast<String>() ?? [];
      instructionText =
          currentStep['resultExplanation'] ?? "¿Cuál es el resultado?";
    }

    return Column(
      children: [
        if (_gameState == 'intro')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.pinkAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "¡Tu turno!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        const SizedBox(height: 48),

        SizedBox(
          height: 150,
          child: _buildEquationDisplay(context, _equationParts),
        ),

        const SizedBox(height: 48),

        if (_gameState == 'intro') ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.indigoAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              instructionText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () => setState(() => _gameState = 'playing_op'),
            child: const Text(
              "¡Manos a la obra!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              instructionText,
              style: const TextStyle(
                color: Colors.pinkAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: options
                .asMap()
                .entries
                .map((e) => _buildCandyButton(e.value, context, idx: e.key))
                .toList(),
          ),
        ],
      ],
    ).animate().fadeIn();
  }

  Widget _buildLevelComplete() {
    return Column(
      children: [
        const Text(
          "¡NIVEL SUPERADO!",
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: 40,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 48),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(value * 3.14 * 2); // full 360 degree rotation
            return Transform(
              alignment: Alignment.center,
              transform: matrix,
              child: Transform.scale(scale: 1.2, child: child),
            );
          },
          child: _buildEquationDisplay(context, _equationParts),
        ),
        const SizedBox(height: 64),
        if (_levelIndex + 1 < gameLevels.length)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: Colors.green.shade500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.school, color: Colors.white, size: 28),
            label: const Text(
              "SIGUIENTE LECCIÓN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => _startLevelTutorial(_levelIndex + 1),
          )
        else
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amberAccent),
            ),
            child: Column(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 80)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(end: const Offset(1.2, 1.2)),
                const SizedBox(height: 16),
                const Text(
                  "¡ERES UN GENIO!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade500,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () => setState(() {
                    _score = 0;
                    _lives = 3;
                    _gameState = 'menu';
                  }),
                  child: const Text(
                    "Volver a jugar",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildGameOver() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.heart_broken_rounded,
            color: Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            "¡SIN VIDAS!",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Repasa la teoría e inténtalo de nuevo.",
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () => setState(() {
              _score = 0;
              _lives = 3;
              _startLevelTutorial(_levelIndex);
            }),
            icon: const Icon(Icons.replay_rounded),
            label: const Text(
              "REINTENTAR LECCIÓN",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

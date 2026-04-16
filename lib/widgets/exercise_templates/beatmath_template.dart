import 'package:flutter/material.dart';
import 'dart:math';

class BeatMathTemplate extends StatefulWidget {
  final Map<String, dynamic>? exerciseData;
  final VoidCallback onComplete;

  const BeatMathTemplate({
    super.key,
    this.exerciseData,
    required this.onComplete,
  });

  @override
  State<BeatMathTemplate> createState() => _BeatMathTemplateState();
}

// --- CONSTANTS ---
const Color colorX = Color(0xFF1E2436);
const Color colorNum = Color(0xFF218C35);
const Color colorNeon = Color(0xFF00FFCC);
const Color colorError = Color(0xFFFF0055);
const Color colorFly = Color(0xFFFFAA00);
const Color colorParen = Color(0xFF888888);
const Color colorGhost = Color(0xFF555555);

// --- GAME CLASSES ---

class _Particle {
  Offset pos;
  Offset vel;
  Color color;
  double life = 1.0;
  double decay;
  double size;

  _Particle(this.pos, this.color)
    : vel = Offset(
        (Random().nextDouble() - 0.5) * 8,
        (Random().nextDouble() - 0.5) * 8,
      ),
      decay = 0.02 + Random().nextDouble() * 0.02,
      size = Random().nextDouble() * 4 + 2;

  void update() {
    pos += vel;
    life -= decay;
  }

  void draw(Canvas canvas) {
    if (life <= 0) {
      return;
    }
    final paint = Paint()..color = color.withValues(alpha: life);
    canvas.drawRect(
      Rect.fromCenter(center: pos, width: size, height: size),
      paint,
    );
  }
}

class _FloatingText {
  String text;
  Offset pos;
  Color color;
  double life = 1.0;
  double decay;
  double size;

  _FloatingText(
    this.text,
    this.pos,
    this.color, {
    double duration = 1.5,
    double? fontSize,
  }) : decay = 1.0 / (duration * 60),
       size = fontSize ?? 20;

  void update() {
    pos = Offset(pos.dx, pos.dy - 0.5);
    life -= decay;
  }

  void draw(Canvas canvas) {
    if (life <= 0) {
      return;
    }
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: life),
        fontSize: size,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }
}

class _Block {
  final String id;
  String text;
  double x, y;
  double targetX, targetY;
  Color color;
  bool isLeft;
  final bool isTextOnly;
  double scale = 1.0;
  double opacity = 1.0;
  bool dead = false;
  bool isDistributive = false;
  bool isFactored = false;

  _Block? bumpTarget;
  Offset bumpOffset = Offset.zero;
  VoidCallback? bumpCallback;
  bool bumpTriggered = false;
  double customSpeed = 0.1;
  bool ignoreLayout = false;
  VoidCallback? pointCallback;

  bool cancelling = false;
  double cancelProgress = 0.0;

  double widthRec = 80;
  double heightRec = 70;

  // Spring physics for "curved bounce" arrival
  Offset arrivalOffset = Offset.zero;
  Offset arrivalVelocity = Offset.zero;

  _Block(
    this.id,
    this.text,
    this.x,
    this.y,
    this.color,
    this.isLeft,
    this.isTextOnly,
  ) : targetX = x,
      targetY = y;

  void bumpTo(_Block target, Offset offset, VoidCallback callback) {
    bumpTarget = target;
    bumpOffset = offset;
    bumpCallback = callback;
    bumpTriggered = false;
    ignoreLayout = true;
  }

  void flyToPoint(double tx, double ty, VoidCallback? callback) {
    targetX = tx;
    targetY = ty;
    ignoreLayout = true;
    customSpeed = 0.05;
    pointCallback = callback;
  }

  void update(double screenWidth) {
    // Responsive dimensions
    double minW = 50;
    double minH = 45;
    if (screenWidth < 400) {
      minW = 40;
      minH = 40;
    }
    widthRec = isTextOnly
        ? max(screenWidth * 0.08, 20)
        : max(min(screenWidth * 0.18, 100), minW);
    heightRec = isTextOnly
        ? max(screenWidth * 0.15, 45)
        : max(min(screenWidth * 0.15, 80), minH);

    if (cancelling) {
      cancelProgress += 0.04;
      if (cancelProgress >= 1.0) {
        cancelProgress = 1.0;
        dead = true;
      }
      return;
    }

    if (dead) {
      scale -= 0.05;
      opacity -= 0.05;
      if (scale < 0) {
        scale = 0;
      }
      return;
    }

    if (bumpTarget != null) {
      double tX = bumpTarget!.x + bumpOffset.dx;
      double tY = bumpTarget!.y + bumpOffset.dy;
      double dx = tX - x;
      double dy = tY - y;
      double dist = sqrt(dx * dx + dy * dy);
      x += dx * 0.15;
      y += dy * 0.15;

      if (dist < 5 && !bumpTriggered) {
        bumpTriggered = true;
        dead = true;
        if (!bumpTarget!.dead) {
          bumpTarget!.scale = 1.15;
          Future.delayed(const Duration(milliseconds: 150), () {
            bumpTarget?.scale = 1.0;
          });
        }
        if (bumpCallback != null) {
          bumpCallback!();
          bumpCallback = null;
        }
      }
    } else {
      x += (targetX - x) * customSpeed;
      y += (targetY - y) * customSpeed;

      // Process spring physics for arrival wiggle
      if (arrivalOffset != Offset.zero || arrivalVelocity != Offset.zero) {
        const double k = 0.15; // spring constant
        const double d = 0.82; // damping

        Offset accel = -arrivalOffset * k;
        arrivalVelocity = (arrivalVelocity + accel) * d;
        arrivalOffset += arrivalVelocity;

        if (arrivalOffset.distance < 0.1 && arrivalVelocity.distance < 0.1) {
          arrivalOffset = Offset.zero;
          arrivalVelocity = Offset.zero;
        }
      }

      if (pointCallback != null) {
        double dist = sqrt(pow(targetX - x, 2) + pow(targetY - y, 2));
        if (dist < 5) {
          pointCallback!();
          pointCallback = null;
        }
      }
    }
  }

  void triggerArrivalSpring() {
    // Inject a curved velocity: mix of vertical and horizontal impact
    arrivalVelocity = const Offset(8, -12);
  }

  void draw(Canvas canvas) {
    if (opacity <= 0) {
      return;
    }

    double renderScale = scale;
    double renderOpacity = opacity;
    double rotation = 0.0;
    Color renderColor = color;

    if (cancelling) {
      // Pop then shrink logic: 1.0 -> 1.15 (at 0.2) -> 0.0 (at 1.0)
      if (cancelProgress < 0.2) {
        renderScale = 1.0 + (0.15 * (cancelProgress / 0.2));
      } else {
        renderScale = 1.15 * (1.0 - (cancelProgress - 0.2) / 0.8);
      }
      renderOpacity = 1.0 - cancelProgress;
      rotation = cancelProgress * 0.3; // subtle tilt (~17 degrees at max)
      // Tint towards orange
      renderColor = Color.lerp(color, Colors.orangeAccent, cancelProgress)!;
    }

    canvas.save();
    canvas.translate(x + arrivalOffset.dx, y + arrivalOffset.dy);
    canvas.rotate(rotation);
    canvas.scale(renderScale, renderScale);

    if (!isTextOnly) {
      final paint = Paint()
        ..color = renderColor.withValues(alpha: renderOpacity)
        ..style = PaintingStyle.fill;

      // Neon glow
      final shadowPaint = Paint()
        ..color = renderColor.withValues(alpha: renderOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: widthRec,
          height: heightRec,
        ),
        const Radius.circular(10),
      );

      canvas.drawRRect(rect, shadowPaint);
      canvas.drawRRect(rect, paint);
    }

    // Text rendering
    double fontSizeValue = max(heightRec * 0.45, 12);
    _drawMathText(
      canvas,
      text,
      fontSizeValue,
      isTextOnly ? colorParen : Colors.white,
      renderOpacity,
    );

    canvas.restore();
  }

  void _drawMathText(
    Canvas canvas,
    String txt,
    double fontSize,
    Color textColor,
    double op,
  ) {
    if (txt.contains('^')) {
      final parts = txt.split('^');

      // Base
      final baseSpan = TextSpan(
        text: parts[0],
        style: TextStyle(
          color: textColor.withValues(alpha: op),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      );
      final baseTp = TextPainter(
        text: baseSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Super
      final superSpan = TextSpan(
        text: parts[1],
        style: TextStyle(
          color: textColor.withValues(alpha: op),
          fontSize: fontSize * 0.6,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      );
      final superTp = TextPainter(
        text: superSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double totalW = baseTp.width + superTp.width;
      baseTp.paint(canvas, Offset(-totalW / 2, -baseTp.height / 2));
      superTp.paint(
        canvas,
        Offset(-totalW / 2 + baseTp.width, -baseTp.height / 2),
      );
    } else if (txt == '√' || txt == '∛' || txt == '±') {
      final span = TextSpan(
        text: txt,
        style: TextStyle(
          color: textColor.withValues(alpha: op),
          fontSize: fontSize * 1.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    } else {
      final span = TextSpan(
        text: txt,
        style: TextStyle(
          color: textColor.withValues(alpha: op),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    }
  }
}

class _Arrow {
  double x, y;
  final String type;
  _Arrow(this.x, this.y, this.type);

  void update() {
    y -= 15.0;
  }

  void draw(Canvas canvas) {
    canvas.save();
    canvas.translate(x, y);
    final paint = Paint()
      ..color = colorNeon
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = colorNeon
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    path.moveTo(0, -20);
    path.lineTo(-10, 10);
    path.lineTo(10, 10);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

class _SubArrow {
  double x, y;
  final _Block target;
  final String text;
  final Color color;
  final VoidCallback? onImpact;
  _SubArrow(this.x, this.y, this.target, this.text, this.color, this.onImpact);

  void update() {
    double dx = target.x - x;
    double dy = target.y - y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist > 10) {
      x += (dx / dist) * 12;
      y += (dy / dist) * 12;
    }
  }

  void draw(Canvas canvas) {
    canvas.save();
    canvas.translate(x, y);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(Offset.zero, 12, shadowPaint);
    canvas.drawCircle(Offset.zero, 12, paint);
    canvas.restore();
  }
}

// --- STATE REDUCER & STREAMS ---

class _BeatMathTemplateState extends State<BeatMathTemplate>
    with TickerProviderStateMixin {
  late AnimationController _gameLoop;

  // Game state
  String _gameMode = 'MENU'; // MENU, THEORY, GAMEPLAY
  int _currentLevel = 1;
  int _levelStep = 1;
  int _theoryStepIndex = 0;
  bool _isAnimating = false;
  bool _isAsking = false;
  String? _selectedBlockId;

  // Helper to handle Spanish decimals (comma) and standard dots
  double _parseNum(String s) {
    if (s.isEmpty || s == "+" || s == "-") return 1.0;
    // Replace comma with dot for parsing
    String normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  String _formatNum(double n) {
    // If it's effectively an integer, show no decimals
    if ((n - n.roundToDouble()).abs() < 0.0001) {
      return n.round().toString();
    }
    // Otherwise show 1 decimal, using comma as separator
    String s = n.toStringAsFixed(1);
    return s.replaceAll('.', ',');
  }

  List<String> _getBeatMathDistractors(double correct) {
    final List<double> fakes = [];
    final bool isDec = (correct - correct.roundToDouble()).abs() > 0.0001;
    final double step = isDec ? 0.5 : 1.0;
    
    fakes.add(correct + step);
    fakes.add(correct - step);
    
    final List<String> results = [ _formatNum(correct) ];
    for (var f in fakes) {
      results.add(_formatNum(f));
    }
    results.shuffle();
    return results;
  }

  String _invertSign(String text) {
    if (text.startsWith('+')) return text.replaceFirst('+', '-');
    if (text.startsWith('-')) return text.replaceFirst('-', '+');
    // If no sign, assume it was positive and now needs to be negative
    return '-$text';
  }

  void _splitSolutions(_Block sourceBlock, List<String> results) {
    setState(() {
      sourceBlock.dead = true;
      for (int i = 0; i < results.length; i++) {
        final b = _Block(
          'sol_${sourceBlock.id}_$i',
          results[i],
          sourceBlock.x,
          sourceBlock.y,
          colorNeon,
          sourceBlock.isLeft,
          false,
        );
        // Desplazamiento horizontal simétrico
        b.targetX = sourceBlock.x + (i == 0 ? -90 : 90);
        b.targetY = sourceBlock.y;
        b.ignoreLayout = true;
        _blocks.add(b);

        _floatingTexts.add(
          _FloatingText(
            i == 0 ? "+" : "-",
            Offset(b.targetX, b.targetY - 40),
            colorFly,
            fontSize: 30,
          ),
        );
      }

      _particles.addAll(
        List.generate(
          15,
          (index) => _Particle(Offset(sourceBlock.x, sourceBlock.y), colorNeon),
        ),
      );
    });
  }

  // Collections
  final List<_Block> _blocks = [];
  final List<_Particle> _particles = [];
  final List<_Arrow> _arrows = [];
  final List<_SubArrow> _subArrows = [];
  final List<_FloatingText> _floatingTexts = [];
  final List<Map<String, dynamic>> _questionQueue = [];

  // Layout info
  double _width = 0;
  double _height = 0;
  double _cx = 0;
  double _eqX = 0; // Dynamic axis for the = sign
  double _eqY = 300;
  double _shakeIntensity = 0;

  static const List<String> _sequence = [
    "2x - 4 = 10",
    "2(x - 3) = 6",
    "x² - 25 = 0",
    "x² - 3x = 0",
    "x³ = 8",
  ];
  final Map<int, Map<String, dynamic>> _levelCaches = {};

  Map<String, dynamic>? _generateDynamicLevel(String equationStr) {
    // Normalizar símbolos del teclado matemático y guiones unicodes
    String eq = equationStr
        .replaceAll('\u2212', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('÷', '/')
        .replaceAll('×', '')
        .replaceAll('*', '')
        .replaceAll(',', '.')
        .replaceAll(' ', '');

    // Normalizar superscripts unicode → notación ^ para que UN solo regex maneje todo
    eq = eq.replaceAll('²', '^2').replaceAll('³', '^3');

    debugPrint(
      '[BeatMath] _generateDynamicLevel input: "$equationStr" → normalizado: "$eq"',
    );
    // 1. Lineal: ax + b = c o ax = c
    // GUARDIA: Si la ecuación contiene '^' es de grado superior, no lineal
    final matchLinear = eq.contains('^')
        ? null
        : RegExp(
            r'^([+-]?(?:\d*[\.,]?\d+)?)([a-zA-Z]+)([+-](?:\d*[\.,]?\d+))?=(.*)$',
          ).firstMatch(eq);
    if (matchLinear != null) {
      String coeffStr = matchLinear.group(1)!;
      String literal = matchLinear.group(2)!;
      String? opText = matchLinear.group(3);
      String rightSideStr = matchLinear.group(4)!;

      if (coeffStr == "" || coeffStr == "+") coeffStr = "1";
      if (coeffStr == "-") coeffStr = "-1";
      double coeff = _parseNum(coeffStr);
      bool hasCoeff = (coeff - 1.0).abs() > 0.0001;
      bool hasOp = opText != null;

      String op = hasOp ? opText.substring(0, 1) : '';
      String numStr = hasOp ? opText.substring(1) : '0';
      double opNum = _parseNum(numStr);
      double rightNum = _parseNum(rightSideStr);

      String inverseOp = op == '+' ? '-' : '+';
      double correctResNum1 = hasOp
          ? (op == '+' ? rightNum - opNum : rightNum + opNum)
          : rightNum;
      String correctResStr1 = _formatNum(correctResNum1);
      double correctResNum2 = correctResNum1 / coeff;
      String correctResStr2 = _formatNum(correctResNum2);

      int stepOp = hasOp ? 1 : 0;
      int stepDiv = hasOp ? 2 : 1;

      return {
        'name': 'Desafío Lineal',
        'theory': [
          {
            'text': "¡Resuelve esta ecuación lineal paso a paso!",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          if (hasCoeff) {
            _blocks.add(
              _Block(
                'mul1',
                coeffStr,
                _cx - 120,
                _height + 100,
                colorFly,
                true,
                false,
              )..targetY = _eqY,
            );
          }
          _blocks.add(
            _Block(
              'var1',
              literal,
              _cx - 40,
              _height + 100,
              colorX,
              true,
              false,
            )..targetY = _eqY,
          );
          if (hasOp) {
            _blocks.add(
              _Block(
                'num1',
                opText,
                _cx + 40,
                _height + 100,
                colorNum,
                true,
                false,
              )..targetY = _eqY,
            );
          }
          _blocks.add(
            _Block(
              'num2',
              rightSideStr,
              _cx + 120,
              _height + 100,
              colorNum,
              false,
              false,
            )..targetY = _eqY,
          );
        },
        'handleAction': (action) {
          if (_levelStep == stepOp && hasOp) {
            final correctAction = "$inverseOp$numStr";
            if (action != correctAction) {
              _applyShake(10);
              return;
            }
            _isAnimating = true;
            final bNum1 = _getB('num1');
            final bNum2 = _getB('num2');
            if (bNum1 == null || bNum2 == null) return;
            _launchCrossingAnimation(
              bNum1,
              bNum2,
              "$rightSideStr $correctAction = ?",
              correctResStr1,
              _getBeatMathDistractors(correctResNum1),
              () {
                bNum1.cancelling = true;
                bNum2.text = correctResStr1;
                _levelStep = stepDiv;
                _isAnimating = false;
                _updateBlockLayout();
              },
            );
          } else if (_levelStep == stepDiv && hasCoeff) {
            final correctAction = "/$coeff";
            if (action != correctAction) {
              _applyShake(10);
              return;
            }
            _isAnimating = true;
            final bCoeff = _getB('mul1');
            final bRight = _getB('num2');
            if (bCoeff == null || bRight == null) return;
            _launchCrossingAnimation(
              bCoeff,
              bRight,
              "$correctResStr1 ÷ $coeff = ?",
              correctResStr2,
              _getBeatMathDistractors(correctResNum2),
              () {
                bCoeff.cancelling = true;
                bRight.text = correctResStr2;
                _levelStep = 100; // Final step for linear
                _updateBlockLayout();
                _endLevel("¡Resuelto!");
              },
            );
          } else if (_levelStep == stepDiv && !hasCoeff) {
            _endLevel("¡Lo lograste!");
          }
        },
        'dynamicButtons': () {
          if (_levelStep == stepOp && hasOp) {
            return [
              {'action': "$inverseOp$numStr", 'label': 'Mover $numStr'},
            ];
          } else if (_levelStep == stepDiv && hasCoeff) {
            return [
              {'action': "/$coeff", 'label': 'Dividir /$coeff'},
            ];
          }
          return [];
        },
      };
    }

    // 2. Grado Superior: ax^n + b = c o ax^n = c (n=2, 3)
    // Ahora todas las ecuaciones ya están normalizadas con ^ gracias al replaceAll arriba
    final matchHigh = RegExp(
      r'^([+-]?(?:\d*[\.,]?\d+)?)([a-zA-Z]+)\^([23])([+-](?:\d*[\.,]?\d+))?=(.*)$',
    ).firstMatch(eq);
    if (matchHigh != null) {
      String aStr = matchHigh.group(1)!;
      String literal = matchHigh.group(2)!;
      String expStr = matchHigh.group(3)!; // siempre '2' o '3'
      String? opText = matchHigh.group(4);
      String rightSideStr = matchHigh.group(5)!;

      if (aStr == "" || aStr == "+") aStr = "1";
      if (aStr == "-") aStr = "-1";
      double a = _parseNum(aStr);
      int exp = expStr == '3' ? 3 : 2;
      String expChar = exp == 3 ? '³' : '²';

      debugPrint(
        '[BeatMath] matchHigh → a=$a, literal=$literal, exp=$exp, opText=$opText, right=$rightSideStr',
      );

      bool hasOp = opText != null;
      String op = hasOp ? opText.substring(0, 1) : '';
      String numStr = hasOp ? opText.substring(1) : '0';
      double opNum = _parseNum(numStr);
      double rightNum = _parseNum(rightSideStr);

      String inverseOp = op == '+' ? '-' : '+';
      double rightAfterOp = hasOp
          ? (op == '+' ? rightNum - opNum : rightNum + opNum)
          : rightNum;

      double resFinal = exp == 3
          ? pow(rightAfterOp / a, 1 / 3).toDouble()
          : sqrt(rightAfterOp / a);
      String finalAnsStr = _formatNum(resFinal);

      int stepOp = hasOp ? 1 : 0;
      int stepDiv = (a != 1) ? (hasOp ? 2 : 1) : -1;
      int stepRoot = (a != 1) ? (hasOp ? 3 : 2) : (hasOp ? 2 : 1);

      return {
        'name': exp == 3 ? 'Raíz Cúbica Pura' : 'Raíz Cuadrática Pura',
        'theory': [
          {
            'text': exp == 3
                ? "Mueve los números y saca la raíz cúbica ∛"
                : "Mueve los números y saca la raíz cuadrada √",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          if (a != 1) {
            _blocks.add(
              _Block('a', aStr, _cx - 100, _height + 100, colorFly, true, false)
                ..targetY = _eqY,
            );
          }
          _blocks.addAll([
            _Block(
              'xPow',
              "$literal$expChar",
              _cx - 40,
              _height + 100,
              colorX,
              true,
              false,
            )..targetY = _eqY,
            if (hasOp)
              _Block(
                'op',
                opText,
                _cx + 20,
                _height + 100,
                colorNum,
                true,
                false,
              )..targetY = _eqY,
            _Block(
              'res',
              rightSideStr,
              _cx + 80,
              _height + 100,
              colorNum,
              false,
              false,
            )..targetY = _eqY,
          ]);
        },
        'handleAction': (String action) {
          if (_levelStep == stepOp && hasOp && action == 'move_num') {
            _isAnimating = true;
            final bOp = _getB('op');
            final bRes = _getB('res');
            if (bOp == null || bRes == null) {
              _isAnimating = false;
              return;
            }
            _launchCrossingAnimation(
              bOp,
              bRes,
              "$rightAfterOp ${inverseOp == '+' ? '+' : '-'}${_formatNum(opNum)} = ?",
              _formatNum(rightAfterOp),
              _getBeatMathDistractors(rightAfterOp),
              () {
                _levelStep = (stepDiv != -1) ? stepDiv : stepRoot;
                _isAnimating = false;
                bOp.cancelling = true;
                bRes.text = _formatNum(rightAfterOp);
                _updateBlockLayout();
              },
            );
          } else if (_levelStep == stepDiv && action == 'div') {
            _isAnimating = true;
            final bA = _getB('a');
            final bRes = _getB('res');
            if (bA == null || bRes == null) {
              _isAnimating = false;
              return;
            }
            _launchCrossingAnimation(
              bA,
              bRes,
              "${bRes.text} ÷ ${_formatNum(a)} = ?",
              _formatNum(rightAfterOp / a),
              _getBeatMathDistractors(rightAfterOp / a),
              () {
                _levelStep = stepRoot;
                _isAnimating = false;
                bA.cancelling = true;
                bRes.text = _formatNum(rightAfterOp / a);
                _updateBlockLayout();
              },
            );
          } else if (_levelStep == stepRoot && action == 'root') {
            _isAnimating = true;
            String rootSym = exp == 3 ? '∛' : '√';
            final bLit = _getB('xPow');
            final bResB = _getB('res');
            if (bLit == null || bResB == null) {
              _isAnimating = false;
              return;
            }

            bLit.text = literal;

            final flyPow = _Block(
              'temp_pow',
              expChar,
              bLit.x + 20,
              bLit.y,
              colorNum,
              true,
              false,
            );
            _blocks.add(flyPow);

            _launchRootCrossingAnimation(
              flyPow,
              bResB,
              exp == 3 ? '∛' : '√',
              "$rootSym ${_formatNum(rightAfterOp)} = ?",
              finalAnsStr,
              _getBeatMathDistractors(resFinal),
              () {
                _levelStep = stepRoot + 1;
                bResB.text = finalAnsStr;
                _isAnimating = false;
                _updateBlockLayout();

                // SI ES GRADO 2, OFRECER SEPARACIÓN
                if (exp == 2 && resFinal != 0) {
                  _levelStep = 200; // Special step for solution split
                } else {
                  _endLevel("¡Exponente eliminado!");
                }
              },
            );
          } else if (_levelStep == 200 && action == 'splitSol') {
            _isAnimating = true;
            final bRes = _getB('res');
            if (bRes == null) return;
            _isAnimating = false;
            _splitSolutions(bRes, ["$finalAnsStr", "-$finalAnsStr"]);
            _endLevel("¡Dos soluciones encontradas!");
          } else {
            _applyShake(10);
          }
        },
        'dynamicButtons': () {
          if (_levelStep == stepOp && hasOp) {
            return [
              {'label': 'Mover $numStr', 'action': 'move_num'},
            ];
          } else if (_levelStep == stepDiv) {
            return [
              {'label': 'Dividir entre $a', 'action': 'div'},
            ];
          } else if (_levelStep == stepRoot) {
            return [
              {'label': exp == 3 ? 'Raíz ∛' : 'Raíz √', 'action': 'root'},
            ];
          } else if (_levelStep == 200) {
            return [
              {'label': 'Separar ±$finalAnsStr', 'action': 'splitSol'},
            ];
          }
          return [];
        },
      };
    }

    // 3. Factorización: ax^2 + bx = 0  (ya normalizado: ax^2 en lugar de ax²)
    final factMatch = RegExp(
      r'^([+-]?\d*)([a-zA-Z]+)\^2([+-]\d+)\2=0$',
    ).firstMatch(eq);
    if (factMatch != null) {
      String aStr = factMatch.group(1)!;
      String literal = factMatch.group(2)!;
      String bStr = factMatch.group(3)!;
      if (aStr == "" || aStr == "+") aStr = "1";
      if (aStr == "-") aStr = "-1";
      int a = int.tryParse(aStr) ?? 1;
      int b = int.tryParse(bStr) ?? 0;
      int x2Value = -(b ~/ a);

      return {
        'name': 'Factorización Ninja',
        'theory': [
          {
            'text': "¡Extrae la '$literal' común de ambos términos!",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          _blocks.addAll([
            _Block(
              'x2',
              "$aStr$literal²",
              _cx - 60,
              _height + 100,
              colorX,
              true,
              false,
            )..targetY = _eqY,
            _Block(
              'bx',
              "$bStr$literal",
              _cx + 60,
              _height + 100,
              colorX,
              true,
              false,
            )..targetY = _eqY,
            _Block(
              'zero',
              '0',
              _cx + 180,
              _height + 100,
              colorNum,
              false,
              false,
            )..targetY = _eqY,
          ]);
        },
        'handleAction': (action) {
          if (_levelStep == 1 && action == 'fact') {
            _isAnimating = true;
            _shootArrowLeft('Extraer $literal', () {
              _askQuestion(
                "Factor Común: $literal(____) = 0",
                "$aStr$literal$bStr",
                ["$aStr$literal$bStr", "$literal+$bStr"],
                () {
                  _getB('x2')?.text = literal;
                  _getB('bx')?.text = "($aStr$literal$bStr)";
                  _levelStep = 2;
                  _isAnimating = false;
                  _updateBlockLayout();
                },
              );
            });
          } else if (_levelStep == 2 && action == 'split') {
            _isAnimating = true;
            _shootArrowLeft('Dividir', () {
              final bX2 = _getB('x2');
              final bBx = _getB('bx');
              if (bX2 == null || bBx == null) return;

              _askQuestion(
                "Segunda solución: $aStr$literal $bStr = 0",
                x2Value.toString(),
                [x2Value.toString(), "0"],
                () {
                  _endLevel("¡$literal=0 o $literal=$x2Value!");
                },
              );
            });
          }
        },
        'dynamicButtons': () {
          return _levelStep == 1
              ? [
                  {'action': 'fact', 'label': 'Extraer [$literal]'},
                ]
              : [
                  {'action': 'split', 'label': 'Separar [=0]'},
                ];
        },
      };
    }

    // 4. Propiedad Distributiva: a(bx + c) = d
    final matchDist = RegExp(
      r'^([+-]?(?:\d*[\.,]?\d+)?)\((.*?)\)=(.*)$',
    ).firstMatch(eq);
    if (matchDist != null) {
      String multiplierStr = matchDist.group(1)!;
      String inner = matchDist.group(2)!;
      String rightStr = matchDist.group(3)!;

      if (multiplierStr == "" || multiplierStr == "+") multiplierStr = "1";
      if (multiplierStr == "-") multiplierStr = "-1";

      return {
        'name': 'Propiedad Distributiva',
        'theory': [
          {
            'text': "Multiplica '$multiplierStr' por todo lo de adentro.",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          _blocks.addAll([
            _Block(
              'mul',
              multiplierStr,
              _cx - 100,
              _height + 100,
              colorFly,
              true,
              false,
            )..targetY = _eqY,
            _Block('inner', '($inner)', _cx, _height + 100, colorX, true, false)
              ..targetY = _eqY,
            _Block(
              'res',
              rightStr,
              _cx + 120,
              _height + 100,
              colorNum,
              false,
              false,
            )..targetY = _eqY,
          ]);
        },
        'handleAction': (action) {
          if (action == 'expand') {
            _isAnimating = true;
            _shootArrowLeft('Distribuir', () {
              _askQuestion(
                "Expansión: $multiplierStr * ($inner)",
                "...",
                ["...", "x"],
                () {
                  // Aquí simplificamos la expansión para el prototipo
                  _endLevel("¡Paréntesis expandido!");
                },
              );
            });
          }
        },
        'dynamicButtons': () => [
          {'label': 'Expandir ( )', 'action': 'expand'},
        ],
      };
    }

    // 5. Factores Binomiales: (x-a)(x+b) = 0
    final matchFactored = RegExp(r'^\((.*?)\)\((.*?)\)=0$').firstMatch(eq);
    if (matchFactored != null) {
      String f1 = matchFactored.group(1)!;
      String f2 = matchFactored.group(2)!;
      return {
        'name': 'Producto Zero',
        'theory': [
          {
            'text': "Si el producto es 0, uno de los factores debe ser 0.",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          _blocks.addAll([
            _Block('f1', '($f1)', _cx - 80, _height + 100, colorX, true, false)
              ..targetY = _eqY,
            _Block('f2', '($f2)', _cx + 80, _height + 100, colorX, true, false)
              ..targetY = _eqY,
            _Block(
              'zero',
              '0',
              _cx + 200,
              _height + 100,
              colorNum,
              false,
              false,
            )..targetY = _eqY,
          ]);
        },
        'handleAction': (action) {
          if (action == 'splitFactors') {
            _isAnimating = true;
            final b1 = _getB('f1');
            if (b1 == null) return;
            _splitSolutions(b1, ["$f1 = 0", "$f2 = 0"]);
            _isAnimating = false;
            _endLevel("¡Ecuaciones separadas!");
          }
        },
        'dynamicButtons': () => [
          {'label': 'Separar Factores', 'action': 'splitFactors'},
        ],
      };
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _levelCaches.clear();
    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(days: 999),
    )..addListener(_loop);
    _gameLoop.forward();

    if (widget.exerciseData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startGame('CHALLENGE_MODE');
      });
    }
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    super.dispose();
  }

  void _loop() {
    if (!mounted) {
      return;
    }

    setState(() {
      // Always update particles, floating texts, and answer blocks
      for (var p in _particles) p.update();
      for (var f in _floatingTexts) f.update();
      _particles.removeWhere((p) => p.life <= 0);
      _floatingTexts.removeWhere((f) => f.life <= 0);

      // Update answer blocks (even while asking) for their slide-in animation
      for (var ab in _answerBlocks) ab.update(_width);
      _answerBlocks.removeWhere((ab) => ab.opacity <= 0);

      if (_isAsking)
        return; // pause rest of game logic while waiting for answer

      for (var b in _blocks) {
        b.update(_width);
      }
      for (var a in _arrows) {
        a.update();
      }
      for (var sa in _subArrows) {
        sa.update();
      }

      // Arrow impacts
      final currentLvl = _getLevelData(_currentLevel);
      for (int i = _arrows.length - 1; i >= 0; i--) {
        if (_arrows[i].y < _eqY + 120) {
          final action = _arrows[i].type;
          _arrows.removeAt(i);
          if (action.isNotEmpty) {
            currentLvl['handleAction'](action);
          }
        }
      }

      // Sub-arrow impacts
      for (int i = _subArrows.length - 1; i >= 0; i--) {
        final sa = _subArrows[i];
        double dx = sa.target.x - sa.x;
        double dy = sa.target.y - sa.y;
        double dist = sqrt(dx * dx + dy * dy);
        if (dist < 30) {
          _createExplosion(sa.target.x, sa.target.y, sa.color);
          _floatingTexts.add(
            _FloatingText(
              sa.text,
              Offset(sa.target.x, sa.target.y + 60),
              sa.color,
            ),
          );
          if (sa.onImpact != null) {
            sa.onImpact!();
          }
          _subArrows.removeAt(i);
        }
      }

      // Cleanup dead blocks
      _blocks.removeWhere((b) => b.opacity <= 0);

      // Camera shake decay
      if (_shakeIntensity > 0) {
        _shakeIntensity *= 0.9;
        if (_shakeIntensity < 0.5) {
          _shakeIntensity = 0;
        }
      }
    });
  }

  // --- HELPERS ---

  void _createExplosion(double x, double y, Color color) {
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(Offset(x, y), color));
    }
  }

  void _applyShake(double val) {
    if (mounted) {
      setState(() => _shakeIntensity = val);
    }
  }

  void _askQuestion(
    String title,
    String correctAns,
    List<String> options,
    VoidCallback onCorrect,
  ) {
    if (_gameMode == 'TUTORIAL_MODE') {
      onCorrect();
      return;
    }
    setState(() {
      _questionQueue.add({
        'title': title,
        'correctAns': correctAns,
        'options': options,
        'onCorrect': onCorrect,
      });
      if (!_isAsking) {
        _showNextQuestion();
      }
    });
  }

  void _showNextQuestion() {
    if (_questionQueue.isEmpty) {
      _isAsking = false;
      return;
    }
    _isAsking = true;
  }

  _Block? _getB(String id) {
    try {
      return _blocks.firstWhere((b) => b.id == id && !b.dead);
    } catch (_) {
      return null;
    }
  }

  void _updateBlockLayout() {
    final leftBlocks = _blocks.where((b) => b.isLeft && !b.dead).toList();
    final rightBlocks = _blocks.where((b) => !b.isLeft && !b.dead).toList();

    double equalsGap = max(_width * 0.05, 18);
    double parenSpacing = max(_width * 0.05, 16);

    int totalBlocks = leftBlocks.length + rightBlocks.length;
    // Adaptive spacing
    double maxSpacing =
        (_width * 0.9 - equalsGap * 2) / (totalBlocks.clamp(1, 10).toDouble());
    double blockSpacing = maxSpacing.clamp(44.0, 100.0);

    // ── Calculate total width for perfect centering ──
    double leftTotalW = 0;
    for (var b in leftBlocks) {
      leftTotalW += b.isTextOnly ? parenSpacing : blockSpacing;
    }
    double rightTotalW = 0;
    for (var b in rightBlocks) {
      rightTotalW += b.isTextOnly ? parenSpacing : blockSpacing;
    }

    double fullWidth = leftTotalW + (equalsGap * 2) + rightTotalW;
    double startX = (_width - fullWidth) / 2;

    // Position Left Blocks
    for (var b in leftBlocks) {
      double bW = b.isTextOnly ? parenSpacing : blockSpacing;
      b.targetX = startX + bW / 2;
      b.targetY = _eqY;
      startX += bW;
    }

    // Dynamic Equals Axis
    _eqX = startX + equalsGap;
    startX += equalsGap * 2;

    // Position Right Blocks
    for (var b in rightBlocks) {
      double bW = b.isTextOnly ? parenSpacing : blockSpacing;
      b.targetX = startX + bW / 2;
      b.targetY = _eqY;
      startX += bW;
    }
  }

  void _loadLevel(int lvl) {
    setState(() {
      _currentLevel = lvl;
      _levelStep = 1;
      _isAnimating = false;
      _isAsking = false;
      _questionQueue.clear();
      _theoryStepIndex = 0;
      _blocks.clear();
      _particles.clear();
      _arrows.clear();
      _subArrows.clear();
      _floatingTexts.clear();

      if (_gameMode == 'CHALLENGE_MODE' || _gameMode == 'GAMEPLAY') {
        _gameMode = 'GAMEPLAY';
        final lvlData = _getLevelData(_currentLevel);
        _blocks.clear();
        lvlData['setupGameplay']();
        _updateBlockLayout();
      } else {
        _gameMode = 'THEORY';
        _nextTheoryStep();
      }
    });
  }

  void _nextTheoryStep() {
    final lvlData = _getLevelData(_currentLevel);
    if (_theoryStepIndex >= (lvlData['theory'] as List).length) {
      setState(() {
        _gameMode = 'GAMEPLAY';
        _blocks.clear();
        lvlData['setupGameplay']();
        _updateBlockLayout();
      });
      return;
    }
    final step = lvlData['theory'][_theoryStepIndex];
    setState(() {
      if (step['action'] != null) {
        step['action']();
      }
      _updateBlockLayout();
    });
    _theoryStepIndex++;
  }

  // State for the floating answer blocks (block-style question UI)
  List<_Block> _answerBlocks = [];
  String? _pendingCorrectAns;
  VoidCallback? _pendingOnCorrect;
  _Block? _pendingTargetBlock;

  void _launchCrossingAnimation(
    _Block movingBlock,
    _Block targetBlock, // block on the other side that receives result
    String questionTitle,
    String correctAns,
    List<String> options,
    VoidCallback onAnswered,
  ) {
    setState(() {
      // 1. Invert sign
      movingBlock.text = _invertSign(movingBlock.text);

      // 2. Move to end of list so it lands on the RIGHT of other blocks on destination side
      _blocks.removeWhere((b) => b.id == movingBlock.id);
      _blocks.add(movingBlock);

      // 3. Flip side and update layout
      movingBlock.isLeft = !movingBlock.isLeft;
      _updateBlockLayout();
    });

    movingBlock.customSpeed = 0.025; // very slow drag
    movingBlock.ignoreLayout = true;

    // Phase 2: once it crosses _cx, show the floating answer blocks
    _pendingCorrectAns = correctAns;
    _pendingTargetBlock = targetBlock;
    _pendingOnCorrect = onAnswered;

    // Build floating answer blocks below the equation
    _answerBlocks.clear();
    double totalW = options.length * (_width * 0.22 + 10);
    double startX = _cx - totalW / 2 + _width * 0.11;
    double ansY = _eqY + (_height * 0.18);
    for (int i = 0; i < options.length; i++) {
      final ab =
          _Block(
              'ans_$i',
              options[i],
              startX + i * (_width * 0.22 + 10),
              _height + 80, // spawn below screen
              options[i] == correctAns ? colorNeon : colorError,
              false,
              false,
            )
            ..targetX = startX + i * (_width * 0.22 + 10)
            ..targetY = ansY;
      _answerBlocks.add(ab);
    }

    // Trigger the question display once the block crosses cx
    _waitForCrossingThenAsk(movingBlock);
  }

  void _waitForCrossingThenAsk(_Block movingBlock) {
    // Poll until block has reached its destination target
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      // Calculate distance to target
      double dist = (movingBlock.x - movingBlock.targetX).abs();

      if (dist < 10) {
        // Stop the block in place at its target destination
        movingBlock.x = movingBlock.targetX;
        movingBlock.customSpeed = 0.0;

        // Trigger the settling bounce effect
        movingBlock.triggerArrivalSpring();
        _applyShake(3); // Global impact shake

        // Show the answer blocks after arrival
        setState(() {
          _isAsking = true;
        });
      } else {
        _waitForCrossingThenAsk(movingBlock);
      }
    });
  }

  void _launchRootCrossingAnimation(
    _Block movingPowBlock,
    _Block targetResBlock,
    String rootSym,
    String questionTitle,
    String correctAns,
    List<String> options,
    VoidCallback onAnswered,
  ) {
    setState(() {
      // Move power to end so it lands on the right (will be converted to root on arrival)
      _blocks.removeWhere((b) => b.id == movingPowBlock.id);
      _blocks.add(movingPowBlock);

      // Set isLeft to false so it's layouted on the right side
      movingPowBlock.isLeft = false;
      _updateBlockLayout();
    });

    movingPowBlock.customSpeed = 0.035;
    movingPowBlock.ignoreLayout = true;

    _pendingCorrectAns = correctAns;
    _pendingTargetBlock = targetResBlock;
    _pendingOnCorrect = onAnswered;

    _answerBlocks.clear();
    double totalW = options.length * (_width * 0.22 + 10);
    double startX = _cx - totalW / 2 + _width * 0.11;
    double ansY = _eqY + (_height * 0.18);
    for (int i = 0; i < options.length; i++) {
      final ab =
          _Block(
              'ans_$i',
              options[i],
              startX + i * (_width * 0.22 + 10),
              _height + 80,
              options[i] == correctAns ? colorNeon : colorError,
              false,
              false,
            )
            ..targetX = startX + i * (_width * 0.22 + 10)
            ..targetY = ansY;
      _answerBlocks.add(ab);
    }

    _waitForRootCrossingThenAsk(
      movingPowBlock,
      targetResBlock,
      rootSym,
      questionTitle,
      correctAns,
      options,
      onAnswered,
    );
  }

  void _waitForRootCrossingThenAsk(
    _Block movingBlock,
    _Block targetResBlock,
    String rootSym,
    String questionTitle,
    String correctAns,
    List<String> options,
    VoidCallback onAnswered,
  ) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      double dist = (movingBlock.x - movingBlock.targetX).abs();

      if (dist < 10) {
        _applyShake(5);
        _createExplosion(movingBlock.x, movingBlock.y, colorNum);

        movingBlock.cancelling = true;

        targetResBlock.text = "$rootSym${targetResBlock.text}";
        targetResBlock.triggerArrivalSpring();

        setState(() {
          _isAsking = true;
          // Hook into question UI by inserting into queue specifically here:
          if (_questionQueue.isEmpty) {
            _questionQueue.add({
              'title': questionTitle,
              'correctAns': correctAns,
              'options': options,
              'onCorrect': onAnswered,
            });
          } else {
            _questionQueue[0]['title'] = questionTitle;
            _questionQueue[0]['correctAns'] = correctAns;
            _questionQueue[0]['options'] = options;
            _questionQueue[0]['onCorrect'] = onAnswered;
          }
        });
      } else {
        _waitForRootCrossingThenAsk(
          movingBlock,
          targetResBlock,
          rootSym,
          questionTitle,
          correctAns,
          options,
          onAnswered,
        );
      }
    });
  }

  void _onAnswerBlockTapped(int index) {
    if (_pendingCorrectAns == null) return;
    if (index >= _answerBlocks.length) return;
    final ab = _answerBlocks[index];
    if (ab.dead) return;
    final target = _pendingTargetBlock;
    final onAnswered = _pendingOnCorrect;
    final correctAns = _pendingCorrectAns!;

    if (ab.text == correctAns && target != null) {
      // Dismiss the question state so the game loop resumes updating _blocks
      setState(() {
        _isAsking = false;
        _pendingCorrectAns = null;
        _pendingOnCorrect = null;
        _pendingTargetBlock = null;
      });
      // Kill other answer blocks with animation
      for (int i = 0; i < _answerBlocks.length; i++) {
        if (i != index) _answerBlocks[i].cancelling = true;
      }
      // Fly the correct block toward the target
      ab.flyToPoint(target.x, target.y, () {
        _createExplosion(target.x, target.y, colorNeon);
        ab.cancelling = true;
        if (onAnswered != null) onAnswered();
      });
    } else {
      _applyShake(10);
    }
  }

  void _shootArrowLeft(String text, VoidCallback callback) {
    if (_selectedBlockId == null) {
      callback();
      return;
    }

    _Block? b = _getB(_selectedBlockId!);
    if (b == null) {
      callback();
      return;
    }

    // Determine target x based on where it's coming from
    double destX = b.isLeft ? _cx + 150 : _cx - 150;

    b.flyToPoint(destX, _eqY, () {
      _applyShake(5);
      callback();
    });
  }

  // --- RENDERING PAINTERS ---

  Widget _buildUIOverlay() {
    if (_gameMode == 'MENU') {
      return _buildMainMenu();
    }

    return Positioned.fill(
      child: Column(
        children: [
          _buildHeader(),
          _buildInstructions(),
          const Spacer(),
          if (_isAsking) _buildQuestionModal(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final lvlData = _getLevelData(_currentLevel);
    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "🎵 BEAT MATH",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: colorNeon,
              fontSize: 22,
              shadows: [Shadow(color: colorNeon, blurRadius: 10)],
            ),
          ),
          Text(
            "Nivel $_currentLevel: ${lvlData['name']}",
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: colorFly,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final lvlData = _getLevelData(_currentLevel);
    String msg = "";
    if (lvlData['name'] == 'Ecuación no soportada') {
      msg = lvlData['theory'][0]['text'];
    } else if (_gameMode == 'THEORY') {
      msg = lvlData['theory'][max(0, _theoryStepIndex - 1)]['text'];
    } else {
      msg = "¡Encuentra el valor de x!";
    }

    return GestureDetector(
      onTap: _gameMode == 'THEORY' ? _nextTheoryStep : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xE60B192C),
          border: Border.all(color: colorNeon, width: 2),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Color(0x8000FFCC), blurRadius: 20),
          ],
        ),
        child: Text(
          msg
                  .replaceAll("<br>", "\n")
                  .replaceAll("<b>", "")
                  .replaceAll("</b>", "")
                  .replaceAll("<span class='highlight'>", "")
                  .replaceAll("</span>", "")
                  .replaceAll("<span class='theory-text'>", "") +
              (_gameMode == 'THEORY' ? "\n\n(Toca para continuar)" : ""),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionModal() {
    if (_questionQueue.isEmpty) {
      return const SizedBox();
    }
    final q = _questionQueue[0];
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xF2050A15),
            border: Border.all(color: colorFly, width: 3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x99FFAA00), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Resuelve: ${q['title']}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: colorFly,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: _width < 600 ? 1 : 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: ((q['options'] ?? []) as List)
                    .map(
                      (opt) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1F2E),
                          side: const BorderSide(
                            color: Color(0xFF555555),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (opt == q['correctAns']) {
                            (q['onCorrect'] as VoidCallback)();
                            setState(() {
                              _questionQueue.removeAt(0);
                              if (_questionQueue.isEmpty) {
                                _isAsking = false;
                              }
                            });
                          } else {
                            _applyShake(10);
                          }
                        },
                        child: Text(
                          opt,
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    return Container(
      color: const Color(0xF2050A15),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🎵 BEAT MATH",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: colorNeon,
                fontSize: 40,
                shadows: [Shadow(color: colorNeon, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Selecciona tu estilo de juego",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 40),
            _actionButton(
              "Modo Tutorial (Visual)",
              const Color(0xFF218C35),
              () => _startGame('TUTORIAL_MODE'),
            ),
            const SizedBox(height: 20),
            _actionButton(
              "Modo Desafío (Tú Piensas)",
              colorNeon,
              () => _startGame('CHALLENGE_MODE'),
              textColor: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    VoidCallback onTap, {
    Color textColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color, blurRadius: 15)],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _startGame(String mode) {
    setState(() => _gameMode = mode);
    _loadLevel(1);
  }

  void _endLevel(String msg) {
    if (_currentLevel >= 5) {
      // Si es el nivel final, no mostramos el diálogo local, 
      // dejamos que el EquationLabWidget maneje la victoria global.
      widget.onComplete();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xF2050A15),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: colorNeon, width: 3),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "¡COMPLETADO!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: colorNeon,
            fontSize: 35,
          ),
        ),
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Center(
            child: _actionButton("Continuar", colorError, () {
              Navigator.pop(context);
              _loadLevel(_currentLevel + 1);
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;
    _cx = _width / 2;
    _eqY = _height * 0.5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Optionally show a dialog or toast "No puedes salir a mitad de un ejercicio"
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050A15),
        body: Stack(
          children: [
            GestureDetector(
              onTapDown: (details) {
                final localPos = details.localPosition;

                // --- Priority 0: Answer blocks (during crossing question) ---
                if (_isAsking && _answerBlocks.isNotEmpty) {
                  for (int i = 0; i < _answerBlocks.length; i++) {
                    final ab = _answerBlocks[i];
                    if (!ab.dead) {
                      final r = Rect.fromCenter(
                        center: Offset(ab.x, ab.y),
                        width: ab.widthRec,
                        height: ab.heightRec,
                      );
                      if (r.contains(localPos)) {
                        _onAnswerBlockTapped(i);
                        return;
                      }
                    }
                  }
                  return; // Block all other taps while asking
                }

                if (_isAnimating ||
                    _isAsking ||
                    _gameMode == 'MENU' ||
                    _gameMode == 'THEORY') {
                  return;
                }

                // --- Priority 1: Direct block tap → fires action immediately ---
                final lvlData = _getLevelData(_currentLevel);
                final buttons = _getLevelButtons(_currentLevel);

                for (var b in _blocks) {
                  if (!b.dead && !b.ignoreLayout) {
                    final rect = Rect.fromCenter(
                      center: Offset(b.x, b.y),
                      width: b.widthRec + 12, // slightly larger hit area
                      height: b.heightRec + 12,
                    );
                    if (rect.contains(localPos)) {
                      // Determine which action this block maps to
                      String? actionForBlock;

                      if (b.id == 'num1' || b.id == 'op') {
                        final m = buttons.where(
                          (btn) =>
                              btn['action'] == 'move_num' ||
                              btn['action'].toString().contains(
                                RegExp(r'[+-]'),
                              ),
                        );
                        if (m.isNotEmpty) actionForBlock = m.first['action'];
                      } else if (b.id == 'a' || b.id == 'mul1') {
                        final m = buttons.where(
                          (btn) =>
                              btn['action'] == 'div' ||
                              btn['action'].toString().contains('/'),
                        );
                        if (m.isNotEmpty) actionForBlock = m.first['action'];
                      } else if (b.id == 'xPow') {
                        final m = buttons.where(
                          (btn) =>
                              btn['action'] == 'root' ||
                              btn['action'].toString().contains('√') ||
                              btn['action'].toString().contains('∛'),
                        );
                        if (m.isNotEmpty) actionForBlock = m.first['action'];
                      }

                      if (actionForBlock != null) {
                        // Highlight briefly, then fire immediately
                        setState(() {
                          _selectedBlockId = b.id;
                          _isAnimating = true;
                        });
                        // Fire the action directly — handleAction contains _launchCrossingAnimation
                        lvlData['handleAction'](actionForBlock);
                        // Clear visual selection after a moment
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) setState(() => _selectedBlockId = null);
                        });
                      } else {
                        _applyShake(5);
                      }
                      return; // Hit a block, done
                    }
                  }
                }

                // --- Priority 2: Background tap (fallback shake) ---
                _applyShake(5);
              },
              child: Transform.translate(
                offset: Offset(
                  (Random().nextDouble() - 0.5) * _shakeIntensity,
                  (Random().nextDouble() - 0.5) * _shakeIntensity,
                ),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _GamePainter(
                    blocks: _blocks,
                    answerBlocks: _answerBlocks,
                    arrows: _arrows,
                    particles: _particles,
                    subArrows: _subArrows,
                    floatingTexts: _floatingTexts,
                    showEq: _gameMode != 'MENU',
                    eqY: _eqY,
                    eqX: _eqX,
                    cx: _cx,
                    bowActive: true,
                    phase: _gameMode,
                    width: _width,
                    height: _height,
                    selectedBlockId: _selectedBlockId,
                    isAsking: _isAsking,
                  ),
                ),
              ),
            ),
            _buildUIOverlay(),
          ],
        ),
      ),
    );
  }

  // --- LEVEL DATA ---

  Map<String, dynamic> _getLevelData(int id) {
    if (_levelCaches.containsKey(id)) {
      return _levelCaches[id]!;
    }
    String eqToLoad = _sequence[(id - 1) % _sequence.length];

    // Si estamos en el primer nivel y recibimos una ecuación externa, la usamos
    if (id == 1 &&
        widget.exerciseData != null &&
        widget.exerciseData!['equation'] != null) {
      eqToLoad = widget.exerciseData!['equation'];
    }

    debugPrint('[BeatMath] getLevelData id=$id → ecuación: "$eqToLoad"');

    final dynamicLevel = _generateDynamicLevel(eqToLoad);
    if (dynamicLevel != null) {
      _levelCaches[id] = dynamicLevel;
      return dynamicLevel;
    }

    final fallback = {
      'name': 'Ecuación no soportada',
      'theory': [
        {
          'text':
              'No pude parsear:\n"$eqToLoad"\n\nFormatos soportados:\n• Lineal: 2x + 3 = 7\n• Cuadrática: x^2 - 9 = 0\n• Cúbica: x^3 = 8\n• Factorización: x^2 + 4x = 0',
          'action': () => {},
        },
      ],
      'setupGameplay': () {},
      'handleAction': (a) {},
    };
    _levelCaches[id] = fallback;
    return fallback;
  }

  List<Map<String, String>> _getLevelButtons(int id) {
    final lvl = _getLevelData(id);
    if (lvl.containsKey('dynamicButtons')) {
      return List<Map<String, String>>.from(
        (lvl['dynamicButtons'] as Function)(),
      );
    }
    return [];
  }
}

// --- PAINTERS ---

class _GamePainter extends CustomPainter {
  final List<_Block> blocks;
  final List<_Block> answerBlocks;
  final List<_Arrow> arrows;
  final List<_Particle> particles;
  final List<_SubArrow> subArrows;
  final List<_FloatingText> floatingTexts;
  final bool showEq;
  final double eqY, eqX, cx;
  final bool bowActive;
  final String phase;
  final double width, height;
  final String? selectedBlockId;
  final bool isAsking;

  _GamePainter({
    required this.blocks,
    required this.answerBlocks,
    required this.arrows,
    required this.particles,
    required this.subArrows,
    required this.floatingTexts,
    required this.showEq,
    required this.eqY,
    required this.eqX,
    required this.cx,
    required this.bowActive,
    required this.phase,
    required this.width,
    required this.height,
    required this.selectedBlockId,
    required this.isAsking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid
    _drawGrid(canvas, size);

    // 2. Equals Sign
    if (showEq && phase != 'MENU') {
      final span = TextSpan(
        text: '=',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: max(width * 0.08, 30),
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
          shadows: const [Shadow(color: Colors.white, blurRadius: 10)],
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(eqX - tp.width / 2, eqY - tp.height / 2));
    }

    // 3. Ghost target for selected block
    if (selectedBlockId != null) {
      _Block? b;
      try {
        b = blocks.firstWhere((blk) => blk.id == selectedBlockId);
      } catch (_) {}

      if (b != null) {
        // Match the destination calculation in _launchCrossingAnimation
        double destX = b.isLeft
            ? eqX + b.widthRec * 0.8
            : eqX - b.widthRec * 0.8;

        // Solid drop zone cavity
        final ghostFill = Paint()
          ..color = colorNeon.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

        final ghostStroke = Paint()
          ..color = colorNeon.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final ghostRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(destX, eqY),
            width: b.widthRec,
            height: b.heightRec,
          ),
          const Radius.circular(10),
        );

        canvas.drawRRect(ghostRect, ghostFill);
        canvas.drawRRect(ghostRect, ghostStroke);

        // Visual slot indicator "[  ]"
        final span = TextSpan(
          text: "[  ]",
          style: TextStyle(
            color: colorNeon.withValues(alpha: 0.4),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(destX - tp.width / 2, eqY - tp.height / 2));
      }
    }

    // 4. Game entities
    for (var b in blocks) {
      if (b.id == selectedBlockId) {
        final glowPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(b.x, b.y),
              width: b.widthRec + 8,
              height: b.heightRec + 8,
            ),
            const Radius.circular(8),
          ),
          glowPaint,
        );
      }
      b.draw(canvas);
    }
    for (var sa in subArrows) {
      sa.draw(canvas);
    }
    for (var a in arrows) {
      a.draw(canvas);
    }
    for (var p in particles) {
      p.draw(canvas);
    }
    for (var f in floatingTexts) {
      f.draw(canvas);
    }

    // 5. Answer blocks (floating question blocks during crossing)
    if (isAsking && answerBlocks.isNotEmpty) {
      // Draw a semi-transparent label above them
      const labelSpan = TextSpan(
        text: '¿Cuál es el resultado?',
        style: TextStyle(
          color: Color(0xBBFFFFFF),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Orbitron',
        ),
      );
      final labelTp = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      final labelY = answerBlocks.isNotEmpty
          ? answerBlocks[0].y - 50
          : eqY + 80;
      labelTp.paint(canvas, Offset(cx - labelTp.width / 2, labelY));

      for (var ab in answerBlocks) {
        ab.draw(canvas);
      }
    }

    // 6. Bow
    if (phase == 'GAMEPLAY') {
      _drawBow(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D00FFCC)
      ..strokeWidth = 1;
    double gridSize = max(50, width * 0.1);
    for (double i = 0; i < width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, height), paint);
    }
    for (double i = 0; i < height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(width, i), paint);
    }
  }

  void _drawBow(Canvas canvas) {
    canvas.save();
    double bowY = height - max(width * 0.1, 60);
    canvas.translate(cx, bowY);
    double bowSize = max(min(50, width * 0.1), 30);

    final paintBow = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: bowSize),
      pi,
      pi,
      false,
      paintBow,
    );

    final neonPaint = Paint()
      ..color = colorNeon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final stringPath = Path()
      ..moveTo(-bowSize, 0)
      ..lineTo(0, -bowSize * 0.4)
      ..lineTo(bowSize, 0);
    canvas.drawPath(stringPath, neonPaint);

    final knobPaint = Paint()
      ..color = bowActive ? colorNeon : const Color(0xFF555555);
    canvas.drawCircle(Offset(0, -bowSize * 0.4), 5, knobPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

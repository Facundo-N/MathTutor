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
  final bool isLeft;
  final bool isTextOnly;
  double scale = 1.0;
  double opacity = 1.0;
  bool dead = false;

  _Block? bumpTarget;
  Offset bumpOffset = Offset.zero;
  VoidCallback? bumpCallback;
  bool bumpTriggered = false;
  double customSpeed = 0.1;
  bool ignoreLayout = false;
  VoidCallback? pointCallback;

  double widthRec = 80;
  double heightRec = 70;

  _Block(
    this.id,
    this.text,
    this.x,
    this.y,
    this.color,
    this.isLeft, {
    this.isTextOnly = false,
  }) : targetX = x,
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
    double minW = 40;
    double minH = 35;
    if (screenWidth < 400) {
      minW = 32;
      minH = 30;
    }
    widthRec = isTextOnly
        ? max(screenWidth * 0.06, 15)
        : max(min(screenWidth * 0.15, 90), minW);
    heightRec = isTextOnly
        ? max(screenWidth * 0.12, 35)
        : max(min(screenWidth * 0.12, 70), minH);

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
      if (pointCallback != null) {
        double dist = sqrt(pow(targetX - x, 2) + pow(targetY - y, 2));
        if (dist < 5) {
          pointCallback!();
          pointCallback = null;
        }
      }
    }
  }

  void draw(Canvas canvas) {
    if (opacity <= 0) {
      return;
    }
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale, scale);

    if (!isTextOnly) {
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Neon glow
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: opacity)
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
      opacity,
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
  String? _selectedAction;

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
    // Normalizar símbolos del teclado matemático
    String eq = equationStr
        .replaceAll('÷', '/')
        .replaceAll('×', '*')
        .replaceAll(',', '.')
        .replaceAll(' ', '');
    // Soporte para ax + b = c
    final match = RegExp(r'^(\d*)([a-zA-Z]+)([+-]\d+)=(.*)$').firstMatch(eq);

    if (match != null) {
      String coeffStr = match.group(1)!;
      String literal = match.group(2)!;
      String opText = match.group(3)!;
      String rightSideStr = match.group(4)!;

      bool hasCoeff =
          coeffStr.isNotEmpty && coeffStr != "1" && coeffStr != "-1";
      String coeff = hasCoeff ? coeffStr : "1";

      String op = opText.substring(0, 1);
      String numStr = opText.substring(1);
      int rightNum = int.tryParse(rightSideStr) ?? 0;
      int opNum = int.tryParse(numStr) ?? 0;

      String inverseOp = op == '+' ? '-' : '+';
      String correctAction1 = "$inverseOp$numStr";

      int correctResNum1 = op == '+' ? rightNum - opNum : rightNum + opNum;
      String correctResStr1 = correctResNum1.toString();

      int correctResNum2 = hasCoeff
          ? (correctResNum1 ~/ (int.tryParse(coeff) ?? 1))
          : correctResNum1;
      String correctResStr2 = correctResNum2.toString();

      return {
        'name': 'Desafío Dinámico (Lineal)',
        'theory': [
          {
            'text':
                "<span class='theory-text'>1. Nuevo Desafío</span><br>¡Resuelve la ecuación que ingresaste paso a paso!",
            'action': () {
              _blocks.clear();
              String leftSide = hasCoeff ? "$coeff$literal" : literal;
              _blocks.addAll([
                _Block(
                  'tx',
                  "$leftSide$opText",
                  _cx - 60,
                  _height + 100,
                  colorX,
                  true,
                )..targetY = _eqY,
                _Block(
                  'tc',
                  rightSideStr,
                  _cx + 60,
                  _height + 100,
                  colorNum,
                  false,
                )..targetY = _eqY,
              ]);
            },
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          if (hasCoeff) {
            _blocks.addAll([
              _Block('mul1', coeff, _cx - 120, _height + 100, colorFly, true)
                ..targetY = _eqY,
              _Block('var1', literal, _cx - 40, _height + 100, colorX, true)
                ..targetY = _eqY,
              _Block('num1', opText, _cx + 40, _height + 100, colorNum, true)
                ..targetY = _eqY,
              _Block(
                'num2',
                rightSideStr,
                _cx + 120,
                _height + 100,
                colorNum,
                false,
              )..targetY = _eqY,
            ]);
          } else {
            _blocks.addAll([
              _Block('var1', literal, _cx - 60, _height + 100, colorX, true)
                ..targetY = _eqY,
              _Block('num1', opText, _cx + 20, _height + 100, colorNum, true)
                ..targetY = _eqY,
              _Block(
                'num2',
                rightSideStr,
                _cx + 100,
                _height + 100,
                colorNum,
                false,
              )..targetY = _eqY,
            ]);
          }
        },
        'handleAction': (action) {
          if (_levelStep == 1) {
            if (action != correctAction1) {
              _applyShake(10);
              return;
            }
            _isAnimating = true;
            _shootArrowsBothSides(correctAction1, () {
              final bNum1 = _getB('num1');
              final bNum2 = _getB('num2');
              if (bNum1 == null || bNum2 == null) return;

              final gL = _Block(
                'gL',
                correctAction1,
                bNum1.x,
                bNum1.y + 100,
                colorFly,
                true,
              );
              final gR = _Block(
                'gR',
                correctAction1,
                bNum2.x,
                bNum2.y + 100,
                colorFly,
                false,
              );
              _blocks.addAll([gL, gR]);

              Future.delayed(const Duration(milliseconds: 1000), () {
                gL.bumpTo(bNum1, const Offset(0, 50), () {
                  _askQuestion(
                    "$opText $correctAction1 = ?",
                    "0",
                    ["0", "1", "x"],
                    () {
                      bNum1.text = '0';
                      bNum1.color = colorGhost;
                      _createExplosion(bNum1.x, bNum1.y, colorFly);
                    },
                  );
                });
                gR.bumpTo(bNum2, const Offset(0, 50), () {
                  List<String> opts = [
                    correctResStr1,
                    (correctResNum1 + 2).toString(),
                    (correctResNum1 - 2).toString(),
                  ];
                  opts.shuffle();
                  _askQuestion(
                    "$rightSideStr $correctAction1 = ?",
                    correctResStr1,
                    opts,
                    () {
                      bNum2.text = correctResStr1;
                      _createExplosion(bNum2.x, bNum2.y, colorNeon);

                      if (hasCoeff) {
                        _levelStep = 2;
                        _isAnimating = false;
                        bNum1.dead = true;
                        _updateBlockLayout();
                      } else {
                        _endLevel("¡Completado!");
                      }
                    },
                  );
                });
              });
            });
          } else if (_levelStep == 2 && hasCoeff) {
            String correctAction2 = "/$coeff";
            if (action != correctAction2) {
              _applyShake(10);
              return;
            }
            _isAnimating = true;
            _shootArrowsBothSides('÷$coeff', () {
              final bCoeff = _getB('mul1');
              final bRight = _getB('num2');
              if (bCoeff == null || bRight == null) return;

              final gL = _Block(
                'dL',
                '÷$coeff',
                bCoeff.x,
                bCoeff.y + 100,
                colorFly,
                true,
              );
              final gR = _Block(
                'dR',
                '÷$coeff',
                bRight.x,
                bRight.y + 100,
                colorFly,
                false,
              );
              _blocks.addAll([gL, gR]);

              Future.delayed(const Duration(milliseconds: 1000), () {
                gL.bumpTo(bCoeff, const Offset(0, 50), () {
                  _askQuestion("$coeff ÷ $coeff = ?", "1", ["1", "0", "x"], () {
                    bCoeff.dead = true;
                  });
                });
                gR.bumpTo(bRight, const Offset(0, 50), () {
                  List<String> opts = [
                    correctResStr2,
                    (correctResNum2 + 1).toString(),
                    (correctResNum2 - 1).toString(),
                  ];
                  opts.shuffle();
                  _askQuestion(
                    "${bRight.text} ÷ $coeff = ?",
                    correctResStr2,
                    opts,
                    () {
                      bRight.text = correctResStr2;
                      _createExplosion(bRight.x, bRight.y, colorNeon);
                      _endLevel("¡La '$literal' siempre estuvo a salvo!");
                    },
                  );
                });
              });
            });
          }
        },
        'dynamicButtons': () {
          if (_levelStep == 1) {
            return [
              {'action': correctAction1, 'label': 'Flecha [$correctAction1]'},
              {'action': '/2', 'label': 'Flecha [/2]'},
            ];
          } else if (_levelStep == 2 && hasCoeff) {
            return [
              {'action': '/$coeff', 'label': 'Flecha [/$coeff]'},
              {'action': '-2', 'label': 'Flecha [-2]'},
            ];
          }
          return [];
        },
      };
    }

    // Soporte para distribucion: a(x + b) = c
    final distMatch = RegExp(
      r'^(\d+)\(([a-zA-Z]+)([+-]\d+)\)=(.*)$',
    ).firstMatch(eq);
    if (distMatch != null) {
      String coeffStr = distMatch.group(1)!;
      String literal = distMatch.group(2)!;
      String opText = distMatch.group(3)!;
      String rightSideStr = distMatch.group(4)!;

      int coeff = int.tryParse(coeffStr) ?? 1;
      int opNum = int.tryParse(opText.substring(1)) ?? 0;
      int rightNum = int.tryParse(rightSideStr) ?? 0;
      String opSign = opText.substring(0, 1);

      int multRes = coeff * opNum;
      String newOpText = "$opSign$multRes";

      String inverseOp = opSign == '+' ? '-' : '+';
      String correctAction2 = "$inverseOp$multRes";

      int correctResNum2 = opSign == '+'
          ? rightNum - multRes
          : rightNum + multRes;
      String correctResStr2 = correctResNum2.toString();

      int correctResNum3 = correctResNum2 ~/ coeff;
      String correctResStr3 = correctResNum3.toString();

      return {
        'name': 'Propiedad Distributiva',
        'theory': [
          {
            'text':
                "El número exterior se clona para multiplicar a cada inquilino de la casa.",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          _blocks.addAll([
            _Block('mul', coeffStr, _cx - 100, _height + 100, colorFly, true)
              ..targetY = _eqY,
            _Block(
              'p1',
              '(',
              _cx - 40,
              _height + 100,
              colorParen,
              true,
              isTextOnly: true,
            )..targetY = _eqY,
            _Block('var1', literal, _cx, _height + 100, colorX, true)
              ..targetY = _eqY,
            _Block('num1', opText, _cx + 40, _height + 100, colorNum, true)
              ..targetY = _eqY,
            _Block(
              'p2',
              ')',
              _cx + 80,
              _height + 100,
              colorParen,
              true,
              isTextOnly: true,
            )..targetY = _eqY,
            _Block(
              'num2',
              rightSideStr,
              _cx + 160,
              _height + 100,
              colorNum,
              false,
            )..targetY = _eqY,
          ]);
        },
        'handleAction': (action) {
          if (_levelStep == 1 && action == 'dist') {
            _isAnimating = true;
            _shootArrowLeft('Factorizar', () {
              final bMul = _getB('mul');
              final bX = _getB('var1');
              final bNum = _getB('num1');
              final p1 = _getB('p1');
              final p2 = _getB('p2');
              if (bMul == null ||
                  bX == null ||
                  bNum == null ||
                  p1 == null ||
                  p2 == null)
                return;

              p1.dead = true;
              p2.dead = true;
              bMul.dead = true;
              final c1 = _Block(
                'c1',
                coeffStr,
                bMul.x,
                bMul.y - 100,
                colorFly,
                true,
              );
              final c2 = _Block(
                'c2',
                coeffStr,
                bMul.x,
                bMul.y - 100,
                colorFly,
                true,
              );
              _blocks.addAll([c1, c2]);

              Future.delayed(const Duration(milliseconds: 1000), () {
                c1.bumpTo(bX, const Offset(0, -50), () {
                  _askQuestion(
                    "$coeffStr * $literal = ?",
                    "$coeffStr$literal",
                    ["$coeffStr$literal", "$literal$coeffStr", coeffStr],
                    () {
                      bX.text = '$coeffStr$literal';
                    },
                  );
                });
                c2.bumpTo(bNum, const Offset(0, -50), () {
                  _askQuestion(
                    "$coeffStr * ${opText.substring(1)} = ?",
                    "$multRes",
                    ["$multRes", "${multRes + 1}", "+$multRes"],
                    () {
                      bNum.text = newOpText;
                      _levelStep = 2;
                      _isAnimating = false;
                      _updateBlockLayout();
                    },
                  );
                });
              });
            });
          } else if (_levelStep == 2) {
            if (action == correctAction2) {
              _isAnimating = true;
              _shootArrowsBothSides(correctAction2, () {
                final bNum1 = _getB('num1');
                final bNum2 = _getB('num2');
                if (bNum1 == null || bNum2 == null) return;

                _askQuestion(
                  "$rightSideStr $correctAction2 = ?",
                  correctResStr2,
                  [
                    correctResStr2,
                    "${correctResNum2 + 12}",
                    "${correctResNum2 - 5}",
                  ],
                  () {
                    bNum1.dead = true;
                    bNum2.text = correctResStr2;
                    _levelStep = 3;
                    _isAnimating = false;
                    _updateBlockLayout();
                  },
                );
              });
            } else {
              _applyShake(10);
            }
          } else if (_levelStep == 3) {
            if (action == '/$coeffStr') {
              _isAnimating = true;
              _shootArrowsBothSides('÷$coeffStr', () {
                final bX = _getB('var1');
                final bNum2 = _getB('num2');
                if (bX == null || bNum2 == null) return;

                _askQuestion(
                  "$correctResStr2 ÷ $coeffStr = ?",
                  correctResStr3,
                  [correctResStr3, "${correctResNum3 + 5}", literal],
                  () {
                    bX.text = literal;
                    bNum2.text = correctResStr3;
                    _endLevel("¡Propiedad distributiva dominada!");
                  },
                );
              });
            } else {
              _applyShake(10);
            }
          }
        },
        'dynamicButtons': () {
          if (_levelStep == 1) {
            return [
              {'action': 'dist', 'label': 'Dist $coeffStr'},
              {'action': '-6', 'label': '-6'},
              {'action': '/3', 'label': '/3'},
            ];
          } else if (_levelStep == 2) {
            return [
              {'action': correctAction2, 'label': correctAction2},
              {'action': '+2', 'label': '+2'},
              {'action': '/$coeffStr', 'label': '/$coeffStr'},
            ];
          } else if (_levelStep == 3) {
            return [
              {'action': '/$coeffStr', 'label': '/$coeffStr'},
              {'action': '-3', 'label': '-3'},
            ];
          }
          return [];
        },
      };
    }

    // Soporte para cuadratica pura: x^2 - c = 0 o x^2 = c
    final quadMatch = RegExp(r'^([a-zA-Z]+)(?:\^2|2|²)(?:([+-]\d+)=0|=(.*))$').firstMatch(eq);
    if (quadMatch != null) {
      String literal = quadMatch.group(1)!;
      bool isEqZero = quadMatch.group(2) != null;
      String rightSideStr = isEqZero ? "0" : quadMatch.group(3)!;
      String opText = isEqZero ? quadMatch.group(2)! : "";

      String op = isEqZero ? opText.substring(0, 1) : "";
      String numStr = isEqZero ? opText.substring(1) : "";
      int rightNum = int.tryParse(rightSideStr) ?? 0;
      int opNum = isEqZero ? (int.tryParse(numStr) ?? 0) : 0;

      String inverseOp = isEqZero ? (op == '+' ? '-' : '+') : "";
      int correctResNum1 = isEqZero ? (op == '+' ? rightNum - opNum : rightNum + opNum) : rightNum;
      String correctResStr1 = correctResNum1.toString();
      int finalAns = sqrt(correctResNum1).round();

      return {
        'name': 'Desafío Dinámico (Cuadrática)',
        'theory': [
          {
            'text': "<span class='theory-text'>1. Cuadrática Pura</span><br>Despeja el término al cuadrado y luego aplica raíz cuadrada.",
            'action': () {
              _blocks.clear();
              _blocks.add(_Block(literal, '$literal²', _cx - (isEqZero ? 60 : 20), _height + 100, colorX, true)..targetY = _eqY);
              if (isEqZero) {
                 _blocks.add(_Block('op', opText, _cx + 20, _height + 100, colorFly, true)..targetY = _eqY);
                 _blocks.add(_Block('res', '0', _cx + 100, _height + 100, colorNeon, false)..targetY = _eqY);
              } else {
                 _blocks.add(_Block('res', rightSideStr, _cx + 100, _height + 100, colorNeon, false)..targetY = _eqY);
              }
            }
          }
        ],
        'setupGameplay': () {
          _blocks.clear();
          _blocks.add(_Block(literal, '$literal²', _cx - (isEqZero ? 60 : 20), _height + 100, colorX, true)..targetY = _eqY);
          if (isEqZero) {
             _blocks.add(_Block('op', opText, _cx + 20, _height + 100, colorFly, true)..targetY = _eqY);
             _blocks.add(_Block('res', '0', _cx + 100, _height + 100, colorNeon, false)..targetY = _eqY);
          } else {
             _blocks.add(_Block('res', rightSideStr, _cx + 100, _height + 100, colorNeon, false)..targetY = _eqY);
          }
        },
        'dynamicButtons': () {
          if (_levelStep == 1 && isEqZero) {
            return [
              {'label': 'Flecha [$inverseOp$numStr]', 'action': 'move_num'},
              {'label': 'Flecha [$op$numStr]', 'action': 'wrong_move'},
            ];
          } else {
            return [
              {'label': 'Flecha [√]', 'action': 'sqrt'},
              {'label': 'Flecha [/2]', 'action': 'wrong_sqrt'},
            ];
          }
        },
        'handleAction': (String a) {
          if (a == 'move_num' && isEqZero && _levelStep == 1) {
            _isAnimating = true;
            _shootArrowLeft(inverseOp + numStr, () {
               _levelStep = 2;
               _isAnimating = false;
               _blocks.removeWhere((b) => b.id == 'op');
               _Block? resB;
               try { resB = _blocks.firstWhere((b) => b.id == 'res'); } catch(_) {}
               if (resB != null) resB.text = correctResStr1;
               _updateBlockLayout();
            });
          } else if (a == 'sqrt') {
            _isAnimating = true;
            _shootArrowsBothSides('√', () {
               _levelStep = 3;
               _isAnimating = false;
               _Block? litB;
               try { litB = _blocks.firstWhere((b) => b.id == literal); } catch(_) {}
               if (litB != null) litB.text = literal;
               _Block? resB;
               try { resB = _blocks.firstWhere((b) => b.id == 'res'); } catch(_) {}
               if (resB != null) resB.text = finalAns.toString();
               _updateBlockLayout();
               _endLevel("¡Bien hecho!");
            });
          } else {
            _applyShake(10);
          }
        }
      };
    }

    // Soporte para factorizacion: ax^2 + bx = 0
    final factMatch = RegExp(r'^([+-]?\d*)x(?:\^2|2|²)([+-]\d+)x=0$').firstMatch(eq);
    if (factMatch != null) {
      String aStr = factMatch.group(1)!;
      String bStr = factMatch.group(2)!;
      if (aStr == "" || aStr == "+") aStr = "1";
      if (aStr == "-") aStr = "-1";
      int a = int.tryParse(aStr) ?? 1;
      int b = int.tryParse(bStr) ?? 0;
      int x2Value = -(b ~/ a);
      String x2Str = x2Value.toString();

      return {
        'name': 'Factorización Ninja',
        'theory': [
          {
            'text': "¡Extrae la 'x' común de ambos términos para simplificar!",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          _blocks.addAll([
            _Block('x2', "${aStr}x²", _cx - 60, _height + 100, colorX, true)
              ..targetY = _eqY,
            _Block('bx', "${bStr}x", _cx + 60, _height + 100, colorX, true)
              ..targetY = _eqY,
            _Block('zero', '0', _cx + 180, _height + 100, colorNum, false)
              ..targetY = _eqY,
          ]);
        },
        'handleAction': (action) {
          if (_levelStep == 1 && action == 'fact') {
            _isAnimating = true;
            _shootArrowLeft('Extraer x', () {
              final bx = _getB('bx');
              final x2 = _getB('x2');
              if (bx == null || x2 == null) return;
              _askQuestion(
                "Factor Común: x(____) = 0",
                "${aStr}x$bStr",
                ["${aStr}x$bStr", "x+$bStr", "x²$bStr"],
                () {
                  x2.text = 'x';
                  bx.text = "(${aStr}x$bStr)";
                  _levelStep = 2;
                  _isAnimating = false;
                  _updateBlockLayout();
                },
              );
            });
          } else if (_levelStep == 2 && action == 'split') {
            _isAnimating = true;
            _shootArrowLeft('Dividir', () {
              _endLevel("¡x=0 o x=$x2Str! ¡Doble impacto!");
            });
          }
        },
        'dynamicButtons': () {
          if (_levelStep == 1) {
            return [
              {'action': 'fact', 'label': 'Extraer [x]'},
            ];
          }
          return [
            {'action': 'split', 'label': 'Separar [=0]'},
          ];
        },
      };
    }

    // Soporte para cubicas: ax^3 = b
    final cubicMatch = RegExp(r'^([+-]?\d*)x(?:\^3|3|³)=(.*)$').firstMatch(eq);
    if (cubicMatch != null) {
      String aStr = cubicMatch.group(1)!;
      String bStr = cubicMatch.group(2)!;
      if (aStr == "" || aStr == "+") aStr = "1";
      if (aStr == "-") aStr = "-1";
      int a = int.tryParse(aStr) ?? 1;
      int b = int.tryParse(bStr) ?? 0;
      int res = b ~/ a;
      int root = pow(res, 1 / 3).round();

      return {
        'name': 'Poder Cúbico',
        'theory': [
          {
            'text': "El exponente 3 invoca a la mística Raíz Cúbica.",
            'action': () => {},
          },
        ],
        'setupGameplay': () {
          _blocks.clear();
          if (a != 1) {
            _blocks.add(
              _Block('a', aStr, _cx - 100, _height + 100, colorFly, true)
                ..targetY = _eqY,
            );
          }
          _blocks.addAll([
            _Block('x3', "x³", _cx - 20, _height + 100, colorX, true)
              ..targetY = _eqY,
            _Block('res', bStr, _cx + 100, _height + 100, colorNum, false)
              ..targetY = _eqY,
          ]);
        },
        'handleAction': (action) {
          if (_levelStep == 1 && a != 1 && action == "/$aStr") {
            _isAnimating = true;
            _shootArrowsBothSides("÷$aStr", () {
              final bRes = _getB('res');
              if (bRes == null) return;
              _askQuestion(
                "$bStr ÷ $aStr = ?",
                "$res",
                ["$res", "${res + 1}"],
                () {
                  _getB('a')?.dead = true;
                  bRes.text = "$res";
                  _levelStep = 2;
                  _isAnimating = false;
                  _updateBlockLayout();
                },
              );
            });
          } else if ((_levelStep == 1 && a == 1) || (_levelStep == 2)) {
            if (action == 'root3') {
              _isAnimating = true;
              _shootArrowsBothSides("∛", () {
                final bRes = _getB('res');
                if (bRes == null) return;
                _askQuestion(
                  "∛${bRes.text} = ?",
                  "$root",
                  ["$root", "${root + 1}"],
                  () {
                    _getB('x3')?.text = 'x';
                    bRes.text = "$root";
                    _endLevel("¡Dimensión Cúbica Restaurada!");
                  },
                );
              });
            }
          }
        },
        'dynamicButtons': () {
          List<Map<String, String>> btns = [];
          if (_levelStep == 1 && a != 1) {
            btns.add({'action': "/$aStr", 'label': 'Div [/$aStr]'});
          } else {
            btns.add({'action': 'root3', 'label': 'Invocar [∛]'});
          }
          return btns;
        },
      };
    }

    // Fallback if equation is not perfectly supported dynamically
    return null;
  }

  @override
  void initState() {
    super.initState();
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
    if (_isAsking) {
      return;
    }

    setState(() {
      // 1. Update entities
      for (var p in _particles) {
        p.update();
      }
      for (var f in _floatingTexts) {
        f.update();
      }
      for (var b in _blocks) {
        b.update(_width);
      }
      for (var a in _arrows) {
        a.update();
      }
      for (var sa in _subArrows) {
        sa.update();
      }

      // 2. Logic & Removal
      _particles.removeWhere((p) => p.life <= 0);
      _floatingTexts.removeWhere((f) => f.life <= 0);

      // Arrow impacts
      final currentLvl = _getLevelData(_currentLevel);
      for (int i = _arrows.length - 1; i >= 0; i--) {
        if (_arrows[i].y < _eqY + 120) {
          final action = _selectedAction;
          _arrows.removeAt(i);
          if (action != null) {
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
    final leftBlocks = _blocks
        .where((b) => b.isLeft && !b.dead && !b.ignoreLayout)
        .toList();
    final rightBlocks = _blocks
        .where((b) => !b.isLeft && !b.dead && !b.ignoreLayout)
        .toList();

    double spacing = max(min(_width * 0.16, 90), 40);
    double parenSpacing = max(_width * 0.05, 20);

    double leftW = 0;
    for (var b in leftBlocks) {
      leftW += b.isTextOnly ? parenSpacing : spacing;
    }

    double startX = _cx - max(_width * 0.1, 30) - leftW;
    for (var b in leftBlocks) {
      b.targetX = startX + (b.isTextOnly ? parenSpacing / 2 : spacing / 2);
      b.targetY = _eqY;
      startX += b.isTextOnly ? parenSpacing : spacing;
    }

    double rStartX = _cx + max(_width * 0.1, 30) + spacing / 2;
    for (int i = 0; i < rightBlocks.length; i++) {
      rightBlocks[i].targetX = rStartX + (i * spacing);
      rightBlocks[i].targetY = _eqY;
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

  void _shootArrowsBothSides(String text, VoidCallback callback) {
    _Block? leftB;
    try {
      leftB = _blocks.firstWhere((b) => b.isLeft && !b.dead && !b.ignoreLayout);
    } catch (_) {
      /* ignore */
    }

    _Block? rightB;
    try {
      rightB = _blocks.firstWhere(
        (b) => !b.isLeft && !b.dead && !b.ignoreLayout,
      );
    } catch (_) {
      /* ignore */
    }

    int hitsNeeded = 0;
    if (leftB != null) {
      hitsNeeded++;
    }
    if (rightB != null) {
      hitsNeeded++;
    }

    if (hitsNeeded == 0) {
      callback();
      return;
    }

    int currentHits = 0;
    void onHit() {
      currentHits++;
      if (currentHits == hitsNeeded) {
        _applyShake(5);
        callback();
      }
    }

    if (leftB != null) {
      _subArrows.add(_SubArrow(_cx, _eqY + 120, leftB, text, colorNeon, onHit));
    }
    if (rightB != null) {
      _subArrows.add(
        _SubArrow(_cx, _eqY + 120, rightB, text, colorNeon, onHit),
      );
    }
  }

  void _shootArrowLeft(String text, VoidCallback callback) {
    _Block? leftB;
    try {
      leftB = _blocks.firstWhere((b) => b.isLeft && !b.dead && !b.ignoreLayout);
    } catch (_) {
      /* ignore */
    }

    if (leftB != null) {
      _subArrows.add(
        _SubArrow(_cx, _eqY + 120, leftB, text, colorFly, () {
          _applyShake(5);
          callback();
        }),
      );
    } else {
      callback();
    }
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
          if (_gameMode == 'GAMEPLAY' && !_isAsking) _buildControls(),
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

  Widget _buildControls() {
    final lvlData = _getLevelData(_currentLevel);
    if (lvlData['name'] == 'Ecuación no soportada') {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: _actionButton("Volver", colorError, () {
            if (widget.exerciseData != null && widget.exerciseData!['equation'] != null) {
              widget.onComplete();
            } else {
              setState(() => _gameMode = 'MENU');
            }
          }),
        ),
      );
    }

    final buttons = _getLevelButtons(_currentLevel);
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "ELIGE TU SIGUIENTE PASO:",
            style: TextStyle(
              color: colorNeon,
              fontFamily: 'Orbitron',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: buttons
                .map(
                  (btn) => GestureDetector(
                    onTap: () {
                      if (_isAnimating || _isAsking) return;
                      setState(() => _selectedAction = btn['action']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedAction == btn['action']
                            ? colorNeon
                            : const Color(0xFF1A1F2E),
                        border: Border.all(
                          color: _selectedAction == btn['action']
                              ? Colors.white
                              : const Color(0xFF555555),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedAction == btn['action']
                            ? [
                                const BoxShadow(
                                  color: colorNeon,
                                  blurRadius: 15,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        btn['label']!,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          color: _selectedAction == btn['action']
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
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
                children: (q['options'] as List<String>)
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
              if (_currentLevel < 5) {
                _loadLevel(_currentLevel + 1);
              } else {
                widget.onComplete();
              }
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
    _eqY = _height * 0.4;

    return Scaffold(
      backgroundColor: const Color(0xFF050A15),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (_isAnimating ||
                  _isAsking ||
                  _gameMode == 'MENU' ||
                  _gameMode == 'THEORY') {
                return;
              }
              final action = _selectedAction;
              if (action == null) {
                _applyShake(10);
                return;
              }
              setState(() {
                _arrows.add(_Arrow(details.localPosition.dx, _height, action));
                _applyShake(2);
              });
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
                  arrows: _arrows,
                  particles: _particles,
                  subArrows: _subArrows,
                  floatingTexts: _floatingTexts,
                  showEq: _gameMode != 'MENU',
                  eqY: _eqY,
                  cx: _cx,
                  bowActive: _selectedAction != null,
                  phase: _gameMode,
                  width: _width,
                  height: _height,
                ),
              ),
            ),
          ),
          _buildUIOverlay(),
        ],
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
    if (id == 1 && widget.exerciseData != null && widget.exerciseData!['equation'] != null) {
      eqToLoad = widget.exerciseData!['equation'];
    }

    final dynamicLevel = _generateDynamicLevel(eqToLoad);
    if (dynamicLevel != null) {
      _levelCaches[id] = dynamicLevel;
      return dynamicLevel;
    }

    final fallback = {
      'name': 'Ecuación no soportada',
      'theory': [
        {
          'text': "Esta ecuación no pudo ser procesada o no se recibió ninguna ecuación. Por favor, intenta ingresar otra.",
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
      return List<Map<String, String>>.from((lvl['dynamicButtons'] as Function)());
    }
    return [];
  }
}

// --- PAINTERS ---

class _GamePainter extends CustomPainter {
  final List<_Block> blocks;
  final List<_Arrow> arrows;
  final List<_Particle> particles;
  final List<_SubArrow> subArrows;
  final List<_FloatingText> floatingTexts;
  final bool showEq;
  final double eqY, cx;
  final bool bowActive;
  final String phase;
  final double width, height;

  _GamePainter({
    required this.blocks,
    required this.arrows,
    required this.particles,
    required this.subArrows,
    required this.floatingTexts,
    required this.showEq,
    required this.eqY,
    required this.cx,
    required this.bowActive,
    required this.phase,
    required this.width,
    required this.height,
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
      tp.paint(canvas, Offset(cx - tp.width / 2, eqY - tp.height / 2));
    }

    // 3. Game entities
    for (var b in blocks) {
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

    // 4. Bow
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

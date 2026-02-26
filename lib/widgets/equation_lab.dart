import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/banny_chat_service.dart';

// --- DATA MODELS ---

class EquationParser {
  static List<EquationLabPiece> parse(String equationStr) {
    // Determine if it's math by checking for operators or variables
    bool looksLikeMath =
        RegExp(r'[\+\-\*\/=xX]').hasMatch(equationStr) ||
        RegExp(r'\d+\s*\d+').hasMatch(equationStr);

    // Looser heuristic to capture expressions, inequalities, or equations
    final eqMatch = RegExp(
      r'([+-]?\s*\d*[a-zA-Z]*\s*[\+\-\*\/]*\s*)*[+-]?\s*\d*[a-zA-Z]*(\s*=\s*([+-]?\s*\d*[a-zA-Z]*\s*[\+\-\*\/]*\s*)*[+-]?\s*\d*[a-zA-Z]*)?',
    ).firstMatch(equationStr);

    String rawEq = equationStr;
    if (eqMatch != null &&
        eqMatch.group(0) != null &&
        eqMatch.group(0)!.trim().isNotEmpty) {
      if (looksLikeMath) {
        rawEq = eqMatch.group(0)!.trim();
      } else {
        return []; // Ignore plain text
      }
    } else {
      if (!looksLikeMath) return [];
      rawEq = equationStr.trim();
    }

    rawEq = rawEq.replaceAll(RegExp(r'\s+'), ' ');
    if (rawEq.isEmpty || RegExp(r'^[a-zA-Z]+$').hasMatch(rawEq)) return [];

    final List<EquationLabPiece> pieces = [];

    void parseSide(String sideStr, String sideName) {
      final matches = RegExp(
        r'([+-]?\s*\d*[a-zA-Z]+)|([+-]?\s*\d+)',
      ).allMatches(sideStr);
      int order = 1;
      for (final match in matches) {
        String term = match.group(0)?.replaceAll(' ', '') ?? '';
        if (term.isEmpty) continue;

        bool isTerm = RegExp(r'[a-zA-Z]').hasMatch(term);
        pieces.add(
          EquationLabPiece(
            id: '${sideName}_$order',
            type: isTerm ? 'term' : 'number_with_sign',
            text: term,
            side: sideName,
            order: order,
            draggable: !isTerm,
            canChangeSign: !isTerm,
          ),
        );
        order++;
      }
    }

    if (rawEq.contains('=')) {
      final parts = rawEq.split('=');
      final leftSide = parts[0].trim();
      final rightSide = parts[1].trim();

      parseSide(leftSide, 'left');
      pieces.add(
        EquationLabPiece(
          id: 'equals',
          type: 'equals',
          text: '=',
          side: 'center',
          order: 1,
        ),
      );
      parseSide(rightSide, 'right');
    } else {
      parseSide(rawEq, 'left');
    }

    // Return pieces only if we found something useful
    return pieces.length > 1 ||
            (pieces.length == 1 && pieces.first.type != 'number_with_sign')
        ? pieces
        : [];
  }
}

class EquationLabPiece {
  final String id;
  final String type; // 'term', 'number_with_sign', 'equals', 'number'
  final String text;
  final String side; // 'left', 'center', 'right'
  final int order;
  final bool draggable;
  final bool canChangeSign;
  final bool isMultiplier;
  final bool isDivisor;
  final bool isGhost;
  final bool isCanceling;

  EquationLabPiece({
    required this.id,
    required this.type,
    required this.text,
    required this.side,
    this.order = 10,
    this.draggable = false,
    this.canChangeSign = false,
    this.isMultiplier = false,
    this.isDivisor = false,
    this.isGhost = false,
    this.isCanceling = false,
  });

  EquationLabPiece copyWith({
    String? id,
    String? type,
    String? text,
    String? side,
    int? order,
    bool? draggable,
    bool? canChangeSign,
    bool? isMultiplier,
    bool? isDivisor,
    bool? isGhost,
    bool? isCanceling,
  }) {
    return EquationLabPiece(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      side: side ?? this.side,
      order: order ?? this.order,
      draggable: draggable ?? this.draggable,
      canChangeSign: canChangeSign ?? this.canChangeSign,
      isMultiplier: isMultiplier ?? this.isMultiplier,
      isDivisor: isDivisor ?? this.isDivisor,
      isGhost: isGhost ?? this.isGhost,
      isCanceling: isCanceling ?? this.isCanceling,
    );
  }
}

class ValidationResult {
  final bool success;
  final String? error;
  ValidationResult({required this.success, this.error});
}

class EquationLabLevel {
  final int id;
  final String actionType; // 'drag', 'chat', 'end'
  final String botPrompt;
  final List<EquationLabPiece> pieces;
  final ValidationResult Function(List<EquationLabPiece>)? validate;
  final String? hint;
  final List<String> expectedAnswers;
  final double correctX; // Value of x to balance the equation

  EquationLabLevel({
    required this.id,
    required this.actionType,
    required this.botPrompt,
    required this.pieces,
    this.validate,
    this.hint,
    this.expectedAnswers = const [],
    this.correctX = 0.0,
  });
}

class HistorySnapshot {
  final int step;
  final List<EquationLabPiece> piecesSnapshot;
  final String instruction;
  final String userAction;

  HistorySnapshot({
    required this.step,
    required this.piecesSnapshot,
    required this.instruction,
    required this.userAction,
  });
}

// --- GLOBAL LEVELS DEFAULT DATA ---

final List<EquationLabLevel> equationLabLevels = [
  EquationLabLevel(
    id: 0,
    actionType: 'drag',
    correctX: 5.0,
    botPrompt:
        "¡Hola! Vamos a resolver: 2x +5 = 15. Primero agrupamos. Arrastra el término '+5' al otro lado de la igualdad.",
    pieces: [
      EquationLabPiece(
        id: 'term_2x',
        type: 'term',
        text: '2x',
        side: 'left',
        order: 1,
      ),
      EquationLabPiece(
        id: 'term_5',
        type: 'number_with_sign',
        text: '+5',
        side: 'left',
        draggable: true,
        canChangeSign: true,
        order: 2,
      ),
      EquationLabPiece(
        id: 'equals',
        type: 'equals',
        text: '=',
        side: 'center',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_15',
        type: 'number',
        text: '15',
        side: 'right',
        order: 1,
      ),
    ],
    validate: (pieces) {
      final leftSide = pieces.where((p) => p.side == 'left').toList();
      final rightSide = pieces.where((p) => p.side == 'right').toList();

      bool leftHasOnlyTerms =
          leftSide.isNotEmpty && leftSide.every((p) => p.type == 'term');
      bool rightHasOnlyNumbers =
          rightSide.isNotEmpty &&
          rightSide.every(
            (p) => p.type == 'number' || p.type == 'number_with_sign',
          );

      if (leftHasOnlyTerms && rightHasOnlyNumbers) {
        // The piece with id 'term_5' must have crossed to the right with its sign
        // auto-inverted to '-5' (our drag-across logic handles this automatically).
        final matches = pieces.where((p) => p.id == 'term_5').toList();
        if (matches.isEmpty || matches.first.side != 'right') {
          return ValidationResult(success: false, error: "not_moved");
        }
        if (!matches.first.text.startsWith('-')) {
          return ValidationResult(success: false, error: "bad_sign");
        }
        return ValidationResult(success: true);
      }
      return ValidationResult(success: false, error: "not_moved");
    },
    hint:
        "Arrastra el '+5' del lado izquierdo al lado derecho cruzando el '='. Al cruzarlo, el signo cambiará automáticamente.",
  ),
  EquationLabLevel(
    id: 1,
    actionType: 'chat',
    correctX: 5.0,
    botPrompt:
        "¡Bien hecho! Ahora que pasaste el número, resuelve la resta en ese lado y escribe el resultado abajo.",
    expectedAnswers: ['10', 'diez'],
    pieces: [
      EquationLabPiece(
        id: 'term_2x',
        type: 'term',
        text: '2x',
        side: 'left',
        order: 1,
      ),
      EquationLabPiece(
        id: 'equals',
        type: 'equals',
        text: '=',
        side: 'center',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_15',
        type: 'number',
        text: '15',
        side: 'right',
        order: 1,
      ),
      EquationLabPiece(
        id: 'term_5_moved',
        type: 'number',
        text: '- 5',
        side: 'right',
        order: 2,
      ),
    ],
    hint:
        "Solo tienes que hacer la resta matemática en el lado derecho. Escribe el número en la barra inferior.",
  ),
  EquationLabLevel(
    id: 2,
    actionType: 'drag',
    correctX: 5.0,
    botPrompt:
        "¡Exacto! 2x = 10. Ahora, el 2 está multiplicando a la 'x'. Arrástralo al otro lado para dejar la 'x' sola.",
    pieces: [
      EquationLabPiece(
        id: 'num_2',
        type: 'number',
        text: '2',
        side: 'left',
        draggable: true,
        isMultiplier: true,
        order: 1,
      ),
      EquationLabPiece(
        id: 'term_x',
        type: 'term',
        text: 'x',
        side: 'left',
        order: 2,
      ),
      EquationLabPiece(
        id: 'equals',
        type: 'equals',
        text: '=',
        side: 'center',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_10',
        type: 'number',
        text: '10',
        side: 'right',
        order: 1,
      ),
    ],
    validate: (pieces) {
      final leftSide = pieces.where((p) => p.side == 'left').toList();
      final rightSide = pieces.where((p) => p.side == 'right').toList();

      bool leftHasOnlyX =
          leftSide.length == 1 &&
          leftSide.first.type == 'term' &&
          leftSide.first.text == 'x';
      bool rightHasDivisor = rightSide.any((p) => p.isDivisor);

      if (leftHasOnlyX && rightHasDivisor) {
        return ValidationResult(success: true);
      }
      if (leftHasOnlyX && !rightHasDivisor) {
        return ValidationResult(success: false, error: "bad_operation");
      }
      return ValidationResult(success: false, error: "not_moved");
    },
    hint:
        "Si el 2 multiplica a la 'x', pasa al otro lado haciendo lo contrario: dividiendo. Arrástralo justo debajo del 10.",
  ),
  EquationLabLevel(
    id: 3,
    actionType: 'chat',
    correctX: 5.0,
    botPrompt:
        "¡Perfecto! Nos queda una división: 10 / 2. Haz la cuenta mental y escribe el valor final de 'x' abajo.",
    expectedAnswers: ['5', 'cinco'],
    pieces: [
      EquationLabPiece(
        id: 'term_x',
        type: 'term',
        text: 'x',
        side: 'left',
        order: 1,
      ),
      EquationLabPiece(
        id: 'equals',
        type: 'equals',
        text: '=',
        side: 'center',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_10',
        type: 'number',
        text: '10',
        side: 'right',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_2_moved',
        type: 'number',
        text: '2',
        side: 'right',
        isDivisor: true,
        order: 1,
      ),
    ],
    hint: "¿Cuánto es la mitad de 10? Escribe ese número para terminar.",
  ),
  EquationLabLevel(
    id: 4,
    actionType: 'end',
    correctX: 5.0,
    botPrompt:
        "¡Felicidades! Has resuelto la ecuación tú mismo paso a paso. Eres un experto: x = 5.",
    pieces: [
      EquationLabPiece(
        id: 'term_x',
        type: 'term',
        text: 'x',
        side: 'left',
        order: 1,
      ),
      EquationLabPiece(
        id: 'equals',
        type: 'equals',
        text: '=',
        side: 'center',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_5_final',
        type: 'number',
        text: '5',
        side: 'right',
        order: 1,
      ),
    ],
  ),
];

// --- MAIN WIDGET ---

class EquationLabWidget extends StatefulWidget {
  final VoidCallback onExit;
  final BannyChatService? chatService;

  const EquationLabWidget({super.key, required this.onExit, this.chatService});

  @override
  State<EquationLabWidget> createState() => _EquationLabWidgetState();
}

class _EquationLabWidgetState extends State<EquationLabWidget>
    with TickerProviderStateMixin {
  String view = 'game';
  int currentLevel = -1;
  List<EquationLabPiece> pieces = [];
  String inputText = "";
  bool _isAnimating = false;
  final TextEditingController inputController = TextEditingController();

  bool showPopup = true;
  String popupTitle = "Instrucción";
  String popupText = "";

  List<HistorySnapshot> history = [];
  bool showReplay = false;

  final GlobalKey _boardKey = GlobalKey();

  StreamSubscription? _chatSubscription;
  Timer? _telemetryDebounceTimer;
  final FlutterTts flutterTts = FlutterTts();

  Future<void> _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  void _queueAiTelemetry(
    String status,
    String recentAction,
    String message, {
    int debounceSeconds = 4,
  }) {
    if (widget.chatService?.isConnected != true) return;

    _telemetryDebounceTimer?.cancel();
    _telemetryDebounceTimer = Timer(Duration(seconds: debounceSeconds), () {
      if (!mounted) return;
      final contextPayload = {
        "status": status,
        "current_equation": _piecesToString(pieces),
        "recent_action": recentAction,
        "recent_actions": history.length > 3
            ? history
                  .sublist(history.length - 3)
                  .map((h) => h.userAction)
                  .toList()
            : history.map((h) => h.userAction).toList(),
      };
      widget.chatService!.sendMessage(message, context: contextPayload);
    });
  }

  @override
  void initState() {
    super.initState();
    _initTts();
    _initLevel();

    if (widget.chatService != null) {
      _chatSubscription = widget.chatService!.messageStream.listen((data) {
        if (data['type'] == 'message') {
          final content = data['content'] as String;
          _handleIncomingMessage(content);
        }
      });
    }
  }

  void _handleIncomingMessage(String payloadStr) {
    String spokenText = payloadStr;
    String uiAction = "none";
    String uiValue = "";

    try {
      final jsonResponse = json.decode(payloadStr) as Map<String, dynamic>;
      spokenText = jsonResponse['text'] ?? "Error parseando texto";
      uiAction = jsonResponse['ui_action'] ?? "none";
      uiValue = jsonResponse['ui_value'] ?? "";
    } catch (e) {
      debugPrint("No es un JSON de la IA estructurado: \$e");
      spokenText = payloadStr; // Fallback
    }

    setState(() {
      showPopup = true;
      popupTitle = "Banny (IA)";
      popupText = spokenText;
    });
    _speak(popupText);

    if (uiAction == "set_equation" && uiValue.isNotEmpty) {
      final parsedPieces = EquationParser.parse(uiValue);
      if (parsedPieces.isNotEmpty) {
        setState(() {
          pieces = parsedPieces;
          history = [];
          if (view == 'home') {
            view = 'game';
            currentLevel = -1;
          }
        });
        _saveToHistory(-1, pieces, "El tutor modificó el tablero");
      }
    } else if (uiAction == "apply_operation" && uiValue.isNotEmpty) {
      final parsedPiece = EquationParser.parse(uiValue);
      if (parsedPiece.isNotEmpty) {
        final newLeftPiece = parsedPiece.first.copyWith(
          id: 'added_left_\${DateTime.now().millisecondsSinceEpoch}',
          side: 'left',
          order: pieces.where((p) => p.side == 'left').length + 1,
          draggable: true,
          canChangeSign: true,
        );
        final newRightPiece = parsedPiece.first.copyWith(
          id: 'added_right_\${DateTime.now().millisecondsSinceEpoch}',
          side: 'right',
          order: pieces.where((p) => p.side == 'right').length + 1,
          draggable: true,
          canChangeSign: true,
        );

        setState(() {
          pieces.add(newLeftPiece);
          pieces.add(newRightPiece);
        });
        _saveToHistory(-1, pieces, "El tutor aplicó \$uiValue en ambos lados");
      }
    } else if (uiAction == "highlight" && uiValue.isNotEmpty) {
      // Implementación futura: resaltar pieza específica
    }
  }

  @override
  void dispose() {
    _telemetryDebounceTimer?.cancel();
    _chatSubscription?.cancel();
    inputController.dispose();
    super.dispose();
  }

  void _initLevel() {
    if (view == 'game') {
      setState(() {
        if (currentLevel != -1) {
          pieces = equationLabLevels[currentLevel].pieces
              .map((e) => e.copyWith())
              .toList();
          showPopup = true;
          popupTitle = "Instrucción";
          popupText = equationLabLevels[currentLevel].botPrompt;
          inputText = "";
          inputController.clear();
          if (currentLevel == 0 && history.isEmpty) {
            _saveToHistory(0, pieces, "Inicio del problema");
          }
        }
      });
      if (currentLevel != -1) {
        _speak(equationLabLevels[currentLevel].botPrompt);
      }

      // Notify AI of the new step with full context so its messages are relevant
      if (currentLevel != -1 && widget.chatService?.isConnected == true) {
        final level = equationLabLevels[currentLevel];
        Future.microtask(() {
          _queueAiTelemetry(
            "new_step",
            "Llegó al paso ${currentLevel + 1}",
            "El estudiante avanzó al paso ${currentLevel + 1} de ${equationLabLevels.length - 1}. "
                "Ecuación actual: ${_piecesToString(pieces)}. "
                "Lo que debe hacer ahora según las instrucciones: \"${level.botPrompt}\"."
                "En DOS frases, anima al estudiante y explica brevemente por qué este paso es necesario.",
          );
        });
      }
    }
  }

  void _saveToHistory(
    int levelId,
    List<EquationLabPiece> snapPieces,
    String userActionText,
  ) {
    history.add(
      HistorySnapshot(
        step: levelId,
        piecesSnapshot: snapPieces.map((p) => p.copyWith()).toList(),
        instruction: levelId == -1
            ? "Resuelve paso a paso."
            : equationLabLevels[levelId].botPrompt,
        userAction: userActionText,
      ),
    );
    setState(() {});
  }

  void _resetGame() {
    setState(() {
      currentLevel = 0;
      history.clear();
      showReplay = false;
    });
    _initLevel();
  }

  void _handlePieceTap(EquationLabPiece piece) {
    if (currentLevel != -1 &&
        equationLabLevels[currentLevel].actionType != 'drag') {
      return;
    }
    if (!piece.canChangeSign) return;

    setState(() {
      final index = pieces.indexWhere((p) => p.id == piece.id);
      if (index >= 0) {
        String newText = piece.text;
        if (newText.startsWith('+')) {
          newText = newText.replaceFirst('+', '-');
        } else if (newText.startsWith('-')) {
          newText = newText.replaceFirst('-', '+');
        }
        pieces[index] = piece.copyWith(text: newText);
      }
    });

    if (currentLevel == -1) {
      final index = pieces.indexWhere((p) => p.id == piece.id);
      String newText = index >= 0 ? pieces[index].text : piece.text;
      String op = newText.startsWith('-') ? "a negativo" : "a positivo";
      String val = newText.replaceAll(RegExp(r'[+-]'), '').trim();
      String actionDesc = "Cambió el signo del $val $op";

      _saveToHistory(-1, pieces, actionDesc);
      _queueAiTelemetry(
        "progress",
        actionDesc,
        "He cambiado el signo del $val $op. ¿Esto ayuda a mantener la balanza equilibrada o fue un buen paso?",
      );
    } else {
      _checkDragWinCondition();
    }
  }

  void _handlePieceDragEnd(EquationLabPiece piece, Offset dropOffset) {
    if (currentLevel != -1 &&
        equationLabLevels[currentLevel].actionType != 'drag') {
      return;
    }
    if (!piece.draggable || _isAnimating) return;

    RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Check global position
    final size = box.size;
    final centerGlobal = box.localToGlobal(Offset(size.width / 2, 0));
    final dropX = dropOffset.dx;

    final newSide = dropX < centerGlobal.dx ? 'left' : 'right';
    final sideWidth = size.width / 2;
    final sideStartX = newSide == 'left'
        ? box.localToGlobal(Offset.zero).dx
        : centerGlobal.dx;
    final dropRatio = (dropX - sideStartX) / sideWidth;

    final index = pieces.indexWhere((p) => p.id == piece.id);
    if (index < 0) return;

    bool beDivisor = false;
    if (piece.isMultiplier && newSide == 'right') {
      beDivisor = true;
    }

    String newText = piece.text;
    bool changedSign = false;
    if (piece.side != newSide && piece.canChangeSign) {
      if (newText.startsWith('+')) {
        newText = newText.replaceFirst('+', '-');
        changedSign = true;
      } else if (newText.startsWith('-')) {
        newText = newText.replaceFirst('-', '+');
        changedSign = true;
      }
    }

    if (changedSign) {
      // Phantom Cancellation Animation
      setState(() {
        _isAnimating = true;
        pieces[index] = piece.copyWith(
          isGhost: true,
        ); // mark as ghost for fade out
        pieces.add(
          EquationLabPiece(
            id: '${piece.id}_ghost_${DateTime.now().millisecondsSinceEpoch}',
            type: piece.type,
            text: newText,
            side: piece.side,
            order: piece.order + 1,
            isGhost: true, // mark as ghost
          ),
        );
        pieces.add(
          EquationLabPiece(
            id: '${piece.id}_dest_${DateTime.now().millisecondsSinceEpoch}',
            type: piece.type,
            text: newText,
            side: newSide,
            order: dropRatio < 0.5 ? 0 : 100,
            isDivisor: beDivisor,
            draggable: piece.draggable,
            canChangeSign: piece.canChangeSign,
          ),
        );

        showPopup = true;
        popupTitle = "Tutor";
        popupText =
            "Se cancelan para mantener la igualdad (=).\n\n¡Exacto! Al aplicar $newText en ambos lados, en la izquierda se cancelan.";
      });

      String op = newText.startsWith('-') ? "restando" : "sumando";
      String val = newText.replaceAll(RegExp(r'[+-]'), '').trim();
      _queueAiTelemetry(
        "progress",
        "Aplicó igualdad",
        "El estudiante aplicó $newText a ambos lados de la ecuación para mantener el balance, y las piezas se están cancelando visualmente. Explícale brevemente y de forma natural la regla matemática de esta acción (lo que haces a un lado de la igualdad, lo debes hacer al otro) y por qué se aplica aquí.",
        debounceSeconds:
            0, // Enviar inmediatamente para que la IA hable durante la animación
      );

      // 1. Wait 3s (so AI can start explaining), then trigger strike-through (isCanceling = true)
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!mounted) return;
        setState(() {
          for (int i = 0; i < pieces.length; i++) {
            if (pieces[i].isGhost) {
              pieces[i] = pieces[i].copyWith(isCanceling: true);
            }
          }
        });

        // 2. Wait 3.5s for the strike-through to be seen and text to be read, then remove them and continue
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (!mounted) return;
          setState(() {
            pieces.removeWhere((p) => p.isCanceling || p.isGhost);
            _isAnimating = false;
          });

          if (currentLevel == -1) {
            String actionDesc = "Pasó el $val $op al otro lado";
            _saveToHistory(-1, pieces, actionDesc);
            _autoSplitMultiplierTerms();
          } else {
            _checkDragWinCondition();
            _autoSplitMultiplierTerms();
          }
        });
      });
    } else {
      // Normal drag (e.g. multipliers, or within the same side)
      setState(() {
        pieces[index] = piece.copyWith(
          side: newSide,
          text: newText,
          order: dropRatio < 0.5 ? 0 : 100,
          isDivisor: beDivisor,
        );
      });

      if (currentLevel == -1) {
        String actionDesc = "Movió una pieza";
        String aiMessage = "Movió un bloque. ¿Qué opinas?";
        if (piece.side != newSide) {
          if (beDivisor) {
            actionDesc = "Pasó un número a dividir";
            aiMessage =
                "He pasado un número a dividir. Pregúntame si sé cuál es el resultado de la división, por favor.";
          } else {
            actionDesc = "Pasó una pieza al otro lado";
          }
        }
        _saveToHistory(-1, pieces, actionDesc);
        _queueAiTelemetry("progress", actionDesc, aiMessage);
        _autoSplitMultiplierTerms();
      } else {
        _checkDragWinCondition();
        _autoSplitMultiplierTerms();
      }
    }
  }

  void _handlePieceDrop(
    EquationLabPiece? draggedPiece,
    EquationLabPiece targetPiece,
  ) {
    if (draggedPiece == null) return;
    if (draggedPiece.id == targetPiece.id) return;

    // Check if both are same type
    bool bothNumbers =
        (draggedPiece.type == 'number' ||
            draggedPiece.type == 'number_with_sign') &&
        (targetPiece.type == 'number' ||
            targetPiece.type == 'number_with_sign');
    bool bothTerms = draggedPiece.type == 'term' && targetPiece.type == 'term';

    if (bothNumbers || bothTerms) {
      // Valid Merge
      setState(() {
        if (bothNumbers) {
          double val1 =
              double.tryParse(
                draggedPiece.text.replaceAll(' ', '').replaceAll('+', ''),
              ) ??
              0.0;
          double val2 =
              double.tryParse(
                targetPiece.text.replaceAll(' ', '').replaceAll('+', ''),
              ) ??
              0.0;

          // Si la pieza que era movida es negativa por su texto original (e.g. "- 5")
          if (draggedPiece.text.contains('-')) val1 = -val1.abs();
          if (targetPiece.text.contains('-')) val2 = -val2.abs();

          double sum = val1 + val2;

          String newText = sum.toStringAsFixed(
            sum.truncateToDouble() == sum ? 0 : 2,
          );
          if (sum >= 0 && targetPiece.canChangeSign) {
            newText = '+$newText';
          }

          final index = pieces.indexWhere((p) => p.id == targetPiece.id);
          if (index >= 0) {
            pieces[index] = targetPiece.copyWith(text: newText);
          }
          pieces.removeWhere((p) => p.id == draggedPiece.id);
        } else if (bothTerms) {
          String varName = draggedPiece.text.replaceAll(
            RegExp(r'[^a-zA-Z]'),
            '',
          );
          String targetVarName = targetPiece.text.replaceAll(
            RegExp(r'[^a-zA-Z]'),
            '',
          );

          if (varName == targetVarName) {
            String coeffStr1 = draggedPiece.text
                .replaceAll(varName, '')
                .replaceAll(' ', '');
            String coeffStr2 = targetPiece.text
                .replaceAll(targetVarName, '')
                .replaceAll(' ', '');

            double coeff1 = 1.0;
            if (coeffStr1 == '-') {
              coeff1 = -1.0;
            } else if (coeffStr1.isNotEmpty && coeffStr1 != '+') {
              coeff1 = double.tryParse(coeffStr1) ?? 1.0;
            }

            double coeff2 = 1.0;
            if (coeffStr2 == '-') {
              coeff2 = -1.0;
            } else if (coeffStr2.isNotEmpty && coeffStr2 != '+') {
              coeff2 = double.tryParse(coeffStr2) ?? 1.0;
            }

            double sum = coeff1 + coeff2;
            String prefix = "";
            if (sum == 1.0) {
              prefix = targetPiece.canChangeSign ? "+" : "";
            } else if (sum == -1.0) {
              prefix = "-";
            } else if (sum == 0.0) {
              prefix = "0";
              varName = ""; // Si es 0, que quede solo "0"
            } else {
              prefix = sum.toStringAsFixed(
                sum.truncateToDouble() == sum ? 0 : 2,
              );
              if (sum > 0 && targetPiece.canChangeSign) {
                prefix = '+$prefix';
              }
            }
            String newText = '$prefix$varName';

            final index = pieces.indexWhere((p) => p.id == targetPiece.id);
            if (index >= 0) {
              pieces[index] = targetPiece.copyWith(text: newText);
            }
            pieces.removeWhere((p) => p.id == draggedPiece.id);
          } else {
            _triggerRepelFeedback();
            return;
          }
        }
      });
      if (currentLevel == -1) {
        String actionDesc = "Agrupó/fusionó bloques compatibles";
        if (bothNumbers) {
          String val1 = draggedPiece.text.replaceAll(' ', '');
          String val2 = targetPiece.text.replaceAll(' ', '');
          actionDesc = "Fusionó el $val1 con el $val2";
        }
        _saveToHistory(-1, pieces, actionDesc);
        _queueAiTelemetry(
          "progress",
          actionDesc,
          "He agrupado algunos bloques que eran del mismo tipo para simplificar ($actionDesc). ¿Voy bien?",
        );
      } else {
        _checkDragWinCondition();
      }
    } else {
      // Invalid Merge (Repel)
      _triggerRepelFeedback();
    }
  }

  void _triggerRepelFeedback() {
    setState(() {
      showPopup = true;
      popupTitle = "Pista del Tutor";
      popupText =
          "¡Cuidado! No puedes sumar manzanas con naranjas. Términos con 'x' solo se suman con otros términos con 'x'.";
    });
    _handleInvalidMove(
      "Intentó sumar términos de diferente tipo (número y variable)",
    );
  }

  void _handleInvalidMove(String reason) {
    if (widget.chatService?.isConnected == true) {
      _queueAiTelemetry(
        "struggling",
        reason,
        "He movido una pieza y parece que cometí un error. ¿Me ayudas a entender por qué usando el método Socrático y la metáfora de la balanza?",
      );
    }
  }

  void _checkDragWinCondition() {
    if (equationLabLevels[currentLevel].actionType != 'drag') return;

    final level = equationLabLevels[currentLevel];
    if (level.validate == null) return;

    final result = level.validate!(pieces);

    if (result.success) {
      if (widget.chatService?.isConnected == true) {
        _queueAiTelemetry(
          "success",
          "Completó el paso correctamente",
          "¡Lo logré! Completé tu instrucción y resolví este paso correctamente.",
        );
      }
      setState(() {
        showPopup = true;
        popupTitle = "¡Excelente!";
        popupText = "Validando movimiento...";
      });

      _saveToHistory(currentLevel + 1, pieces, "Movió la pieza correctamente");
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            currentLevel++;
            _initLevel();
          });
        }
      });
    } else {
      String error = level.hint ?? "";
      if (result.error == "bad_sign") {
        error =
            "¡Ups! El signo cambia automáticamente al cruzar el '='. Arrastra la pieza completamente hasta el otro lado.";
        _handleInvalidMove(
          "Movió un término sin que cruzara del todo el signo '='",
        );
      } else if (result.error == "bad_operation") {
        error =
            "Recuerda: lo contrario de multiplicar es dividir. Ponlo debajo del número.";
        _handleInvalidMove("Intentó hacer una operación matemática incorrecta");
      } else {
        _handleInvalidMove("Movimiento no esperado");
      }
      setState(() {
        showPopup = true;
        popupTitle = "Pista del Tutor";
        popupText = error;
      });
    }
  }

  /// Automatically splits a term like '2x' into a draggable [2] multiplier block
  /// and a [x] variable block, once the left side has only terms remaining.
  void _autoSplitMultiplierTerms() {
    // Only split when no plain numbers remain on the left
    final leftNumbers = pieces
        .where(
          (p) =>
              p.side == 'left' &&
              (p.type == 'number' || p.type == 'number_with_sign'),
        )
        .toList();
    if (leftNumbers.isNotEmpty) return;

    bool didSplit = false;
    String splitCoeff = '';
    final piecesToCheck = List<EquationLabPiece>.from(pieces);
    for (final piece in piecesToCheck) {
      if (piece.type != 'term') continue;
      final match = RegExp(
        r'^([+-]?\d+\.?\d*)([a-zA-Z])$',
      ).firstMatch(piece.text.replaceAll(' ', ''));
      if (match == null) continue;
      final coeff = match.group(1)!;
      final variable = match.group(2)!;
      final coeffVal = double.tryParse(coeff) ?? 1.0;
      if (coeffVal.abs() == 1.0) continue; // Already x or -x, no need to split

      final idx = pieces.indexWhere((p) => p.id == piece.id);
      if (idx < 0) continue;
      pieces.removeAt(idx);
      pieces.insertAll(idx, [
        EquationLabPiece(
          id: '${piece.id}_coeff',
          type: 'number',
          text: coeff,
          side: piece.side,
          order: piece.order,
          draggable: true,
          isMultiplier: true,
        ),
        EquationLabPiece(
          id: '${piece.id}_var',
          type: 'term',
          text: variable,
          side: piece.side,
          order: piece.order + 1,
        ),
      ]);
      splitCoeff = coeff;
      didSplit = true;
    }

    if (didSplit) {
      setState(() {
        showPopup = true;
        popupTitle = "Siguiente paso";
        popupText =
            "¡Muy bien! El $splitCoeff que multiplica a la variable quedó libre. "
            "Arrástralo al otro lado para dejar la variable sola.";
      });
    }
  }

  String _piecesToString(List<EquationLabPiece> list) {
    if (list.isEmpty) return "Ninguna ecuación";
    final left = list.where((p) => p.side == 'left').toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final center = list.where((p) => p.side == 'center').toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final right = list.where((p) => p.side == 'right').toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    String formatSide(List<EquationLabPiece> sidePieces) {
      return sidePieces
          .map((p) {
            if (p.isDivisor) return "/ ${p.text}";
            return p.text;
          })
          .join(' ');
    }

    String eq = "${formatSide(left)} ${formatSide(center)} ${formatSide(right)}"
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return eq.isEmpty ? "Problema vacío" : eq;
  }

  void _handleSendMessage() {
    if (inputText.trim().isEmpty) return;

    if (widget.chatService?.isConnected == true) {
      final contextPayload = {
        "current_equation": _piecesToString(pieces),
        "recent_actions": history.length > 3
            ? history
                  .sublist(history.length - 3)
                  .map((h) => h.userAction)
                  .toList()
            : history.map((h) => h.userAction).toList(),
      };

      widget.chatService!.sendMessage(
        inputText.trim(),
        context: contextPayload,
      );
      inputController.clear();
      setState(() {
        final textSent = inputText.trim();
        inputText = "";
        showPopup = true;
        popupTitle = "Tú";
        popupText = textSent;
      });
      return;
    }
    if (currentLevel == -1) {
      // Si estamos en Teoría Interactiva pero no hay conexión a Banny
      setState(() {
        showPopup = true;
        popupTitle = "Sin conexión";
        popupText =
            "No se pudo conectar con Banny. Revisa que el backend esté ejecutándose.";
        inputText = "";
      });
      inputController.clear();
      return;
    }

    if (currentLevel < 0 ||
        equationLabLevels[currentLevel].actionType != 'chat') {
      return;
    }

    final userText = inputText.trim();
    final level = equationLabLevels[currentLevel];

    bool isCorrect = level.expectedAnswers.any(
      (ans) => userText.toLowerCase().contains(ans),
    );

    if (isCorrect) {
      setState(() {
        showPopup = true;
        popupTitle = "¡Correcto!";
        popupText = "Respuesta correcta. Avanzando...";
      });

      // Saving next level pieces
      final nextLevelPieces = equationLabLevels[currentLevel + 1].pieces
          .map((p) => p.copyWith())
          .toList();
      _saveToHistory(currentLevel + 1, nextLevelPieces, 'Escribió: $userText');

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            currentLevel++;
            _initLevel();
          });
        }
      });
    } else {
      setState(() {
        showPopup = true;
        popupTitle = "Pista del Tutor";
        popupText = "Hmm, ese número no es el resultado. ${level.hint ?? ''}";
      });
    }
    inputController.clear();
    setState(() => inputText = "");
  }

  // --- RENDER METHODS ---

  Widget _buildPieceWidget(
    EquationLabPiece piece, {
    bool isDraggingFeedback = false,
  }) {
    return _EquationPieceWidget(
      piece: piece,
      isDraggingFeedback: isDraggingFeedback,
      onTap: () => _handlePieceTap(piece),
      onAccept: (draggedPiece) => _handlePieceDrop(draggedPiece, piece),
      onDragEnd: (DraggableDetails details) =>
          _handlePieceDragEnd(piece, details.offset),
    );
  }

  double _evaluateSide(List<EquationLabPiece> sidePieces, double xValue) {
    if (sidePieces.isEmpty) return 0.0;

    double total = 0;
    double product = 1;
    bool hasProduct = false;
    double divisor = 1;

    for (var p in sidePieces) {
      double val = 0;
      if (p.type == 'number' || p.type == 'number_with_sign') {
        val = double.tryParse(p.text.replaceAll(' ', '')) ?? 0.0;
      } else if (p.type == 'term') {
        String coeffStr = p.text
            .replaceAll(RegExp(r'[a-zA-Z]'), '')
            .replaceAll(' ', '');
        double coeff = 1.0;
        if (coeffStr == '-') {
          coeff = -1.0;
        } else if (coeffStr.isNotEmpty && coeffStr != '+') {
          coeff = double.tryParse(coeffStr) ?? 1.0;
        }
        val = coeff * xValue;
      }

      if (p.isMultiplier) {
        product *= val;
        hasProduct = true;
      } else if (p.isDivisor) {
        divisor *= (val != 0 ? val : 1);
      } else {
        total += val;
      }
    }

    if (hasProduct) {
      if (total == 0) {
        total = product;
      } else {
        total *= product;
      }
    }

    return total / divisor;
  }

  double _calculateTiltAngle() {
    if (pieces.isEmpty) return 0.0;

    double correctX = 1.0;
    if (currentLevel >= 0 && currentLevel < equationLabLevels.length) {
      correctX = equationLabLevels[currentLevel].correctX;
    }

    List<EquationLabPiece> leftPieces = pieces
        .where((p) => p.side == 'left')
        .toList();
    List<EquationLabPiece> rightPieces = pieces
        .where((p) => p.side == 'right')
        .toList();

    double leftWeight = _evaluateSide(leftPieces, correctX);
    double rightWeight = _evaluateSide(rightPieces, correctX);

    double diff =
        rightWeight -
        leftWeight; // Positive diff = right is heavier = tilt clockwise

    double maxAngle = 0.25; // radians
    double angle = diff * 0.05;
    if (angle > maxAngle) angle = maxAngle;
    if (angle < -maxAngle) angle = -maxAngle;

    return angle;
  }

  Widget _buildBoard() {
    final leftPieces = pieces.where((p) => p.side == 'left').toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final centerPieces = pieces.where((p) => p.side == 'center').toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final rightMultipliers =
        pieces.where((p) => p.side == 'right' && !p.isDivisor).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    final rightDivisors =
        pieces.where((p) => p.side == 'right' && p.isDivisor).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    return Center(
      // We wrap the Row in an AnimatedRotation to give it a physical balance feel
      child: AnimatedRotation(
        turns: _calculateTiltAngle() / (2 * pi),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: leftPieces
                            .map((p) => _buildPieceWidget(p))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: centerPieces
                          .map((p) => _buildPieceWidget(p))
                          .toList(),
                    ),
                  ),
                  if (currentLevel == 2 && pieces.any((p) => p.isDivisor))
                    Container(
                      width: 60,
                      height: 3,
                      color: Colors.black87,
                      margin: const EdgeInsets.only(top: 10),
                    ),
                  // Balance pole removed per request
                ],
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: rightMultipliers
                                .map((p) => _buildPieceWidget(p))
                                .toList(),
                          ),
                        ),
                        if (rightDivisors.isNotEmpty) ...[
                          Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.black87.withValues(alpha: 0.5),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: rightDivisors
                                  .map((p) => _buildPieceWidget(p))
                                  .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopup() {
    if (!showPopup || showReplay) return const SizedBox.shrink();

    return Positioned(
      top: 140, // Moved lower to avoid app bar overlap
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.blue[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[900]!.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    popupTitle == "Instrucción"
                        ? Icons.smart_toy
                        : Icons.lightbulb_outline,
                    color: Colors.blueAccent[400],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            popupTitle,
                            style: TextStyle(
                              color: Colors.blueAccent[100],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => showPopup = false),
                            child: Icon(
                              Icons.close,
                              color: Colors.blueAccent.withValues(alpha: 0.6),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        popupText,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.home_outlined,
                      color: Colors.black87.withValues(alpha: 0.7),
                    ),
                    onPressed: widget.onExit,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Laboratorio de Ecuaciones",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (history.length > 1)
                    IconButton(
                      icon: Icon(Icons.history, color: Colors.blueAccent[200]),
                      onPressed: () => setState(() => showReplay = true),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.black87.withValues(alpha: 0.7),
                    ),
                    onPressed: _resetGame,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.black87.withValues(alpha: 0.7),
                    ),
                    onPressed: widget.onExit,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black87.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    bool isChatMode = currentLevel == -1
        ? true
        : equationLabLevels[currentLevel].actionType == 'chat';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isChatMode ? Colors.blueAccent[400]! : Colors.grey[300]!,
              width: isChatMode ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: inputController,
                  enabled: true,
                  onChanged: (val) => setState(() => inputText = val),
                  onSubmitted: (_) => _handleSendMessage(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Escribe tu pregunta o cálculo aquí...",
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: inputText.trim().isNotEmpty
                    ? _handleSendMessage
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplayModal() {
    if (!showReplay) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black87.withValues(alpha: 0.95),
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.blueAccent[400],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Repetición de Pasos",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => setState(() => showReplay = false),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black87.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final snap = history[index];
                  // Local helper to render static piece array
                  final leftP =
                      snap.piecesSnapshot
                          .where((p) => p.side == 'left')
                          .toList()
                        ..sort((a, b) => a.order.compareTo(b.order));
                  final centerP =
                      snap.piecesSnapshot
                          .where((p) => p.side == 'center')
                          .toList()
                        ..sort((a, b) => a.order.compareTo(b.order));
                  final rightP =
                      snap.piecesSnapshot
                          .where((p) => p.side == 'right')
                          .toList()
                        ..sort((a, b) => a.order.compareTo(b.order));

                  Widget mapPieces(List<EquationLabPiece> list) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: list
                          .map(
                            (p) => Text(
                              p.text,
                              style: TextStyle(
                                color: p.canChangeSign
                                    ? Colors.blueAccent[400]
                                    : p.isDivisor
                                    ? Colors.amber[300]
                                    : Colors.black87,

                                fontSize: p.isDivisor ? 16 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .map(
                            (w) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: w,
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[900]!.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black87.withValues(alpha: 0.1),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 12),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "PASO $index",
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 120,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              mapPieces(leftP),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  mapPieces(centerP),
                                  if (snap.piecesSnapshot.any(
                                    (p) => p.isDivisor,
                                  ))
                                    Container(
                                      width: 20,
                                      height: 2,
                                      color: Colors.amber[300],
                                      margin: const EdgeInsets.only(left: 20),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  mapPieces(
                                    rightP.where((p) => !p.isDivisor).toList(),
                                  ),
                                  mapPieces(
                                    rightP.where((p) => p.isDivisor).toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.blueGrey[900]!.withValues(alpha: 0.8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[700],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Colors.black87.withValues(alpha: 0.7),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snap.instruction,
                                      style: TextStyle(
                                        color: Colors.blueGrey[200],
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[900]!.withValues(
                                          alpha: 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue[700]!.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: Colors.blueAccent[200],
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            snap.userAction,
                                            style: TextStyle(
                                              color: Colors.blueAccent[200],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.white, Colors.grey[100]!],
                      center: Alignment.center,
                      radius: 1.0,
                    ),
                  ),
                ),

                // Interactive board wrapper
                Positioned.fill(
                  key: _boardKey,
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: _buildBoard(),
                  ),
                ),

                // Dashed center line
                if (currentLevel >= 0 &&
                    equationLabLevels[currentLevel].actionType == 'drag')
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: MediaQuery.of(context).size.width / 2,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.black87.withValues(alpha: 0.2),
                            width: 2,
                            style: BorderStyle.none,
                          ),
                        ),
                        // Dash trick is hard to do natively without custom painter, fallback to semi transparent solid
                      ),
                      child: CustomPaint(painter: DashedLinePainter()),
                    ),
                  ),

                _buildHeader(),
                _buildPopup(),
                _buildReplayModal(),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}

// --- HELPER CLASSES ---

class _EquationPieceWidget extends StatefulWidget {
  final EquationLabPiece piece;
  final bool isDraggingFeedback;
  final VoidCallback onTap;
  final Function(EquationLabPiece) onAccept;
  final Function(DraggableDetails) onDragEnd;

  const _EquationPieceWidget({
    required this.piece,
    this.isDraggingFeedback = false,
    required this.onTap,
    required this.onAccept,
    required this.onDragEnd,
  });

  @override
  State<_EquationPieceWidget> createState() => _EquationPieceWidgetState();
}

class _EquationPieceWidgetState extends State<_EquationPieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_EquationPieceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger pop animation if sign changed between '+' and '-'
    if (oldWidget.piece.text != widget.piece.text) {
      if ((oldWidget.piece.text.contains('+') &&
              widget.piece.text.contains('-')) ||
          (oldWidget.piece.text.contains('-') &&
              widget.piece.text.contains('+'))) {
        _controller.forward(from: 0);
      }
    }
    // Trigger pop + bar slide when piece becomes a divisor
    if (!oldWidget.piece.isDivisor && widget.piece.isDivisor) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final piece = widget.piece;
    List<Widget> content = [];

    Color textColor = piece.canChangeSign
        ? Colors.blueAccent[400]!
        : Colors.black87;
    double fontSize = piece.type == 'equals' ? 40 : 50;

    if (piece.isDivisor) {
      textColor = Colors.black87;
      fontSize = 32;
    }

    Widget textWidget = Material(
      type: MaterialType.transparency,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: textColor,
          decoration: TextDecoration.none,
          fontFamily: 'Roboto',
        ),
        child: Text(piece.text),
      ),
    );

    if (piece.isGhost) {
      // Fade out ghosts slightly to indicate they are temporary
      textWidget = Opacity(opacity: 0.6, child: textWidget);
    }

    if (piece.isCanceling) {
      // Add a red strike-through line
      textWidget = Stack(
        alignment: Alignment.center,
        children: [
          textWidget,
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.rotate(
                angle: -0.2, // slight angle for strike-through
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      height: 4,
                      width: fontSize * 1.5,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    if (piece.isDivisor) {
      content.add(
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated fraction bar that grows from center outward
                ClipRect(
                  child: Align(
                    widthFactor: value,
                    child: Container(height: 3, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                child!,
              ],
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: textWidget,
          ),
        ),
      );
    } else {
      content.add(textWidget);
    }

    Widget container = AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final scale = _flipAnimation.value;
        final transform = Matrix4.diagonal3Values(scale, scale, 1.0);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: piece.type == 'equals' || piece.isDivisor
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: widget.isDraggingFeedback
                  ? null
                  : (piece.type != 'equals' && !piece.isDivisor)
                  ? LinearGradient(
                      colors: [Colors.blue.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.isDraggingFeedback
                  ? Colors.grey[50]!
                  : (piece.type != 'equals' && !piece.isDivisor
                        ? Colors.white
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              border: widget.isDraggingFeedback
                  ? Border.all(color: Colors.blueAccent[400]!, width: 2)
                  : null,
              boxShadow: widget.isDraggingFeedback
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: content),
          ),
        );
      },
    );

    if (!widget.isDraggingFeedback && piece.draggable) {
      return DragTarget<EquationLabPiece>(
        onWillAcceptWithDetails: (details) => details.data.id != piece.id,
        onAcceptWithDetails: (details) {
          widget.onAccept(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          bool isTarget = candidateData.isNotEmpty;
          return Draggable<EquationLabPiece>(
            data: piece,
            feedback: Material(
              color: Colors.transparent,
              child: WobblyFeedback(
                child: _EquationPieceWidget(
                  piece: piece,
                  isDraggingFeedback: true,
                  onTap: () {},
                  onAccept: (_) {},
                  onDragEnd: (_) {},
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.1, child: container),
            onDragEnd: widget.onDragEnd,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: isTarget
                    ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
                    : Matrix4.identity(),
                child: container,
              ),
            ),
          );
        },
      );
    }

    if (!widget.isDraggingFeedback && piece.canChangeSign) {
      return GestureDetector(onTap: widget.onTap, child: container);
    }

    return container;
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 5, startY = 0;
    final paint = Paint()
      ..color = Colors.black87.withValues(alpha: 0.2)
      ..strokeWidth = 2;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WobblyFeedback extends StatefulWidget {
  final Widget child;
  const WobblyFeedback({super.key, required this.child});

  @override
  State<WobblyFeedback> createState() => _WobblyFeedbackState();
}

class _WobblyFeedbackState extends State<WobblyFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Rotación suave entre -0.05 y 0.05 radianes
        final angle = (_controller.value - 0.5) * 0.1;
        return Transform.rotate(angle: angle, child: child);
      },
      child: widget.child,
    );
  }
}

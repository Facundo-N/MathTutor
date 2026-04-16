import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import '../providers/user_provider.dart';
import '../services/tts_service.dart';

import '../services/banny_chat_service.dart';
import '../models/ai_exercise_model.dart';
import './exercise_templates/multiple_choice_template.dart';
import './exercise_templates/drag_drop_template.dart';
import './exercise_templates/tap_destroy_template.dart';
import './exercise_templates/fill_blank_template.dart';

// NUEVOS EJERCICIOS
import './exercise_templates/destructor_ecuaciones_template.dart';
import './exercise_templates/beatmath_template.dart';
import './exercise_templates/destruirecuaciones_conseleccion_template.dart';
import './exercise_templates/candymath_template.dart';
import './exercise_templates/academia_ninja_template.dart';
import './exercise_templates/dardos_template.dart';

// NUEVO: Flujo de Aprendizaje Coordinado
import './learning_flow_orchestrator.dart';
import './math_keyboard.dart';

// --- DATA MODELS ---

class EquationParser {
  static List<EquationLabPiece> parse(String equationStr) {
    // Normalizar sÃ­mbolos del teclado matemÃ¡tico antes de parsear
    equationStr = equationStr
        .replaceAll('Ã·', '/')
        .replaceAll('Ã—', '*')
        .replaceAll(',', '.')
        .trim();

    // Descartar texto plano (palabras sin operadores ni nÃºmeros)
    bool looksLikeMath =
        RegExp(r'[\+\-\*\/=xX\^Â²Â³]').hasMatch(equationStr) ||
        RegExp(r'\d').hasMatch(equationStr);

    if (!looksLikeMath) return [];

    // Usar la ecuaciÃ³n directamente â€” ya fue normalizada arriba
    String rawEq = equationStr.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (rawEq.isEmpty || RegExp(r'^[a-zA-Z]+$').hasMatch(rawEq)) return [];

    final List<EquationLabPiece> pieces = [];

    void parseSide(String sideStr, String sideName) {
      final matches = RegExp(
        r'([+-]?\s*\d*[a-zA-Z]+(\^?\d+|[Â²Â³])?)|([+-]?\s*\d+)',
      ).allMatches(sideStr);
      int order = 1;
      for (final match in matches) {
        String term = match.group(0)?.replaceAll(' ', '') ?? '';
        if (term.isEmpty) continue;

        bool hasVar = RegExp(r'[a-zA-Z]').hasMatch(term);

        if (hasVar) {
          // Detectar si es coeficiente + variable: e.g. "2x", "-3y", "+2x^2"
          final coeffVarMatch = RegExp(
            r'^([+-]?\d+)([a-zA-Z]+(\^?\d+|[Â²Â³])?)$',
          ).firstMatch(term);

          if (coeffVarMatch != null) {
            // Hay coeficiente numÃ©rico: separar en 2 piezas
            final coeffText = coeffVarMatch.group(1)!; // ej. "2" o "-3"
            final varText = coeffVarMatch.group(2)!; // ej. "x" o "x^2"

            // Pieza del coeficiente: verde, draggable
            pieces.add(
              EquationLabPiece(
                id: '${sideName}_${order}_coeff',
                type: 'coeff',
                text: coeffText,
                side: sideName,
                order: order,
                draggable: true,
                canChangeSign: true,
              ),
            );
            order++;

            // Pieza de la variable: oscura, NO draggable
            pieces.add(
              EquationLabPiece(
                id: '${sideName}_${order}_var',
                type: 'term', // 'term' = variable block (cyan dark style)
                text: varText,
                side: sideName,
                order: order,
                draggable: false,
                canChangeSign: false,
              ),
            );
          } else {
            // Solo variable sin coeficiente numÃ©rico explÃ­cito (e.g. "x", "+x", "-x^2")
            pieces.add(
              EquationLabPiece(
                id: '${sideName}_$order',
                type: 'term',
                text: term,
                side: sideName,
                order: order,
                // Si la variable no tiene un nÃºmero visible, no separamos, y en este diseÃ±o original no es draggable
                draggable: false,
                canChangeSign: false,
              ),
            );
          }
        } else {
          // NÃºmero puro: draggable
          pieces.add(
            EquationLabPiece(
              id: '${sideName}_$order',
              type: 'number_with_sign',
              text: term,
              side: sideName,
              order: order,
              draggable: true,
              canChangeSign: true,
            ),
          );
        }
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
    correctX: 2.0,
    botPrompt:
        "Â¡Hola! Vamos a resolver: 3x + 6 = 12. Primero agrupamos. Arrastra el tÃ©rmino '+6' al otro lado de la igualdad.",
    pieces: [
      EquationLabPiece(
        id: 'term_3x',
        type: 'term',
        text: '3x',
        side: 'left',
        order: 1,
      ),
      EquationLabPiece(
        id: 'term_6',
        type: 'number_with_sign',
        text: '+6',
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
        id: 'num_12',
        type: 'number',
        text: '12',
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
        // The piece with id 'term_6' must have crossed to the right
        final matches = pieces.where((p) => p.id == 'term_6').toList();
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
        "Arrastra el '+6' del lado izquierdo al lado derecho cruzando el '='. Al cruzarlo, el signo cambiarÃ¡ automÃ¡ticamente.",
  ),
  EquationLabLevel(
    id: 1,
    actionType: 'chat',
    correctX: 2.0,
    botPrompt:
        "Â¡Bien hecho! Ahora que pasaste el nÃºmero, resuelve la resta en ese lado y escribe el resultado abajo.",
    expectedAnswers: ['6', 'seis'],
    pieces: [
      EquationLabPiece(
        id: 'term_3x',
        type: 'term',
        text: '3x',
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
        id: 'num_12',
        type: 'number',
        text: '12',
        side: 'right',
        order: 1,
      ),
      EquationLabPiece(
        id: 'term_6_moved',
        type: 'number',
        text: '- 6',
        side: 'right',
        order: 2,
      ),
    ],
    hint:
        "Solo tienes que hacer la resta matemÃ¡tica en el lado derecho. Escribe el nÃºmero en la barra inferior.",
  ),
  EquationLabLevel(
    id: 2,
    actionType: 'drag',
    correctX: 2.0,
    botPrompt:
        "Â¡Exacto! 3x = 6. Ahora, el 3 estÃ¡ multiplicando a la 'x'. ArrÃ¡stralo al otro lado para dejar la 'x' sola.",
    pieces: [
      EquationLabPiece(
        id: 'num_3',
        type: 'number',
        text: '3',
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
        id: 'num_6',
        type: 'number',
        text: '6',
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
        "Si el 3 multiplica a la 'x', pasa al otro lado haciendo lo contrario: dividiendo. ArrÃ¡stralo justo debajo del 6.",
  ),
  EquationLabLevel(
    id: 3,
    actionType: 'chat',
    correctX: 2.0,
    botPrompt:
        "Â¡Perfecto! Nos queda una divisiÃ³n: 6 / 3. Haz la cuenta mental y escribe el valor final de 'x' abajo.",
    expectedAnswers: ['2', 'dos'],
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
        id: 'num_6',
        type: 'number',
        text: '6',
        side: 'right',
        order: 1,
      ),
      EquationLabPiece(
        id: 'num_3_moved',
        type: 'number',
        text: '3',
        side: 'right',
        isDivisor: true,
        order: 1,
      ),
    ],
    hint: "Â¿CuÃ¡nto es 6 dividido entre 3? Escribe ese nÃºmero para terminar.",
  ),
  EquationLabLevel(
    id: 4,
    actionType: 'end',
    correctX: 2.0,
    botPrompt:
        "Â¡Felicidades! Has resuelto la ecuaciÃ³n tÃº mismo paso a paso. Eres un experto: x = 2.",
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
        id: 'num_2_final',
        type: 'number',
        text: '2',
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

  /// Tema visual: true = oscuro, false = claro
  final bool isDarkMode;

  /// Callback para que el padre cambie el tema al presionar el botÃ³n sol/luna
  final VoidCallback? onToggleTheme;

  /// EcuaciÃ³n inicial (puede ser 'adaptive')
  final String? equation;

  /// Payload inicial en JSON (Ãºtil para inyectar exercise_type desde el tutorial)
  final String? initialPayloadStr;

  /// Botones adicionales para la barra superior
  final List<Widget>? actions;

  const EquationLabWidget({
    super.key,
    required this.onExit,
    this.chatService,
    this.isDarkMode = true,
    this.onToggleTheme,
    this.equation,
    this.initialPayloadStr,
    this.actions,
  });

  @override
  State<EquationLabWidget> createState() => _EquationLabWidgetState();
}

class _EquationLabWidgetState extends State<EquationLabWidget>
    with TickerProviderStateMixin {
  String view = 'loading'; // 'game', 'selector', 'loading', 'home'
  int currentLevel = -1;
  List<EquationLabPiece> pieces = [];
  String inputText = "";
  bool _isAnimating = false;
  final TextEditingController inputController = TextEditingController();

  bool showPopup = false; // Cambiado a false por defecto para el selector
  String popupTitle = "InstrucciÃ³n";
  String popupText = "";

  List<HistorySnapshot> history = [];
  bool showReplay = false;

  AIExercise? aiExercise;
  bool _showingEmptyPrompt = false;
  bool _exerciseDone = false; // NEW: Track if the exercise is finished

  final GlobalKey _boardKey = GlobalKey();

  StreamSubscription? _chatSubscription;
  Timer? _telemetryDebounceTimer;
  final TTSService _tts = TTSService();
  late AnimationController _auroraCtrl;

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;

    // Retraso de 5 segundos solicitado para sincronización
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    // ⭐ Integración segura: Priorizar Kokoro (backend) pero sin bloquear la UI
    try {
      if (await _tts.isBackendAvailable()) {
        unawaited(_tts.speak(text));
      } else {
        unawaited(_tts.speak(text));
      }
    } catch (e) {
      debugPrint('⚠️ Error en _speak: $e');
    }
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
    _auroraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    _initEquation();

    if (widget.initialPayloadStr != null) {
      // Inyectar el ejercicio visual inmediatamente desde el constructor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleIncomingMessage(widget.initialPayloadStr!);
        }
      });
    }

    if (widget.chatService != null) {
      _chatSubscription = widget.chatService!.messageStream.listen((data) {
        if (data['type'] == 'message') {
          final content = data['content'] as String;
          _handleIncomingMessage(content);
        }
      });
    }
  }

  Future<void> _initEquation() async {
    if (widget.equation == 'adaptive') {
      setState(() => view = 'loading');
      try {
        final boardProvider = context.read<BoardProvider>();
        final userProvider = context.read<UserProvider>();
        final userId = userProvider.userId ?? 'user_123';

        await boardProvider.loadAdaptiveProblem(userId);

        if (mounted) {
          final eq = boardProvider.currentBoard?.originalEquation ?? '';
          final parsed = EquationParser.parse(eq);
          setState(() {
            pieces = parsed;
            view = 'game';
            currentLevel = -1;
            _showingEmptyPrompt = parsed.isEmpty;
          });
          _saveToHistory(-1, pieces, "Carga de problema adaptativo");

          final story = boardProvider.currentBoard?.storyContext;
          if (story != null) {
            _handleIncomingMessage(
              jsonEncode({"text": story, "ui_action": "none"}),
            );
          }
        }
      } catch (e) {
        debugPrint("Error cargando adaptive en widget: $e");
        setState(() => view = 'home');
      }
    } else if (widget.equation != null && widget.equation!.isNotEmpty) {
      final parsed = EquationParser.parse(widget.equation!);
      if (parsed.isNotEmpty) {
        setState(() {
          pieces = parsed;
          view = 'game';
          _showingEmptyPrompt = false;
          currentLevel = -1;
        });
        _saveToHistory(-1, pieces, "Carga de ecuaciÃ³n inicial");
      } else {
        setState(() {
          _showingEmptyPrompt = true;
          view = 'game';
        });
      }
    } else {
      // Por defecto, empezar con el prompt "Ingresa tu ejercicio"
      setState(() {
        currentLevel = -1;
        view = 'game';
        pieces = [];
        _showingEmptyPrompt = true;
      });
    }
  }

  void _handleIncomingMessage(String payloadStr) {
    String spokenText = payloadStr;
    String uiAction = "none";
    String uiValue = "";

    try {
      final jsonResponse = json.decode(payloadStr) as Map<String, dynamic>;

      // Fase 3: Lanzar ejercicio interactivo desde chat
      if (jsonResponse['launch_exercise'] == true &&
          jsonResponse['equation'] != null) {
        final equation = jsonResponse['equation'] as String;
        final topic = jsonResponse['topic'] as String? ?? 'linear';

        Navigator.pushNamed(
          context,
          '/learning-flow',
          arguments: {'topicId': topic, 'initialEquation': equation},
        );
        return;
      }

      // â­ Nueva lÃ³gica: Detectar Ejercicio DinÃ¡mico (Motor GrÃ¡fico)
      if (jsonResponse.containsKey('exercise_type')) {
        setState(() {
          aiExercise = AIExercise.fromJson(jsonResponse);
          showPopup = false;
          view = 'game';
          _showingEmptyPrompt = false; // Ocultar prompt al iniciar ejercicio
        });
        if (jsonResponse.containsKey('story_context') ||
            jsonResponse.containsKey('instruction')) {
          _speak(
            jsonResponse['story_context'] ?? jsonResponse['instruction'] ?? "",
          );
        }
        return;
      }

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
      if (view == 'loading') view = 'game';
    });
    _speak(popupText);

    if (uiAction == "set_equation" && uiValue.isNotEmpty) {
      final parsedPieces = EquationParser.parse(uiValue);
      if (parsedPieces.isNotEmpty) {
        setState(() {
          pieces = parsedPieces;
          history = [];
          _showingEmptyPrompt = false; // Ocultar prompt al recibir ecuaciÃ³n
          if (view == 'home') {
            view = 'game';
            currentLevel = -1;
          }
        });
        _saveToHistory(-1, pieces, "El tutor modificÃ³ el tablero");
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
        _saveToHistory(-1, pieces, "El tutor aplicÃ³ \$uiValue en ambos lados");
      }
    } else if (uiAction == "highlight" && uiValue.isNotEmpty) {
      // ImplementaciÃ³n futura: resaltar pieza especÃ­fica
    }
  }

  @override
  void dispose() {
    _auroraCtrl.dispose();
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
          _showingEmptyPrompt = false; // Ocultar prompt al iniciar un nivel
          showPopup = true;
          popupTitle = "InstrucciÃ³n";
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
            "LlegÃ³ al paso ${currentLevel + 1}",
            "El estudiante avanzÃ³ al paso ${currentLevel + 1} de ${equationLabLevels.length - 1}. "
                "EcuaciÃ³n actual: ${_piecesToString(pieces)}. "
                "Lo que debe hacer ahora segÃºn las instrucciones: \"${level.botPrompt}\"."
                "En DOS frases, anima al estudiante y explica brevemente por quÃ© este paso es necesario.",
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
      String actionDesc = "CambiÃ³ el signo del $val $op";

      _saveToHistory(-1, pieces, actionDesc);
      _queueAiTelemetry(
        "progress",
        actionDesc,
        "He cambiado el signo del $val $op. Â¿Esto ayuda a mantener la balanza equilibrada o fue un buen paso?",
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

    // If crossing sides, always append at the END of the destination side.
    // If staying on same side, use drop ratio for natural reordering.
    int computedOrder;
    if (piece.side != newSide) {
      final destPieces = pieces.where(
        (p) => p.side == newSide && p.id != piece.id,
      );
      computedOrder = destPieces.isEmpty
          ? 1
          : destPieces.map((p) => p.order).reduce((a, b) => a > b ? a : b) + 1;
    } else {
      computedOrder = dropRatio < 0.5 ? 0 : 100;
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
            order: computedOrder,
            isDivisor: beDivisor,
            draggable: piece.draggable,
            canChangeSign: piece.canChangeSign,
          ),
        );

        showPopup = true;
        popupTitle = "Tutor";
        popupText =
            "Se cancelan para mantener la igualdad (=).\n\nÂ¡Exacto! Al aplicar $newText en ambos lados, en la izquierda se cancelan.";
      });

      String op = newText.startsWith('-') ? "restando" : "sumando";
      String val = newText.replaceAll(RegExp(r'[+-]'), '').trim();
      _queueAiTelemetry(
        "progress",
        "AplicÃ³ igualdad",
        "El estudiante aplicÃ³ $newText a ambos lados de la ecuaciÃ³n para mantener el balance, y las piezas se estÃ¡n cancelando visualmente. ExplÃ­cale brevemente y de forma natural la regla matemÃ¡tica de esta acciÃ³n (lo que haces a un lado de la igualdad, lo debes hacer al otro) y por quÃ© se aplica aquÃ­.",
        debounceSeconds:
            0, // Enviar inmediatamente para que la IA hable durante la animaciÃ³n
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
            String actionDesc = "PasÃ³ el $val $op al otro lado";
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
          order: computedOrder,
          isDivisor: beDivisor,
        );
      });

      if (currentLevel == -1) {
        String actionDesc = "MoviÃ³ una pieza";
        String aiMessage = "MoviÃ³ un bloque. Â¿QuÃ© opinas?";
        if (piece.side != newSide) {
          if (beDivisor) {
            actionDesc = "PasÃ³ un nÃºmero a dividir";
            aiMessage =
                "He pasado un nÃºmero a dividir. PregÃºntame si sÃ© cuÃ¡l es el resultado de la divisiÃ³n, por favor.";
          } else {
            actionDesc = "PasÃ³ una pieza al otro lado";
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
        String actionDesc = "AgrupÃ³/fusionÃ³ bloques compatibles";
        if (bothNumbers) {
          String val1 = draggedPiece.text.replaceAll(' ', '');
          String val2 = targetPiece.text.replaceAll(' ', '');
          actionDesc = "FusionÃ³ el $val1 con el $val2";
        }
        _saveToHistory(-1, pieces, actionDesc);
        _queueAiTelemetry(
          "progress",
          actionDesc,
          "He agrupado algunos bloques que eran del mismo tipo para simplificar ($actionDesc). Â¿Voy bien?",
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
          "Â¡Cuidado! No puedes sumar manzanas con naranjas. TÃ©rminos con 'x' solo se suman con otros tÃ©rminos con 'x'.";
    });
    _handleInvalidMove(
      "IntentÃ³ sumar tÃ©rminos de diferente tipo (nÃºmero y variable)",
    );
  }

  void _handleInvalidMove(String reason) {
    if (widget.chatService?.isConnected == true) {
      _queueAiTelemetry(
        "struggling",
        reason,
        "He movido una pieza y parece que cometÃ­ un error. Â¿Me ayudas a entender por quÃ© usando el mÃ©todo SocrÃ¡tico y la metÃ¡fora de la balanza?",
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
          "CompletÃ³ el paso correctamente",
          "Â¡Lo logrÃ©! CompletÃ© tu instrucciÃ³n y resolvÃ­ este paso correctamente.",
        );
      }
      setState(() {
        showPopup = true;
        popupTitle = "Â¡Excelente!";
        popupText = "Validando movimiento...";
      });

      _saveToHistory(currentLevel + 1, pieces, "MoviÃ³ la pieza correctamente");
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
            "Â¡Ups! El signo cambia automÃ¡ticamente al cruzar el '='. Arrastra la pieza completamente hasta el otro lado.";
        _handleInvalidMove(
          "MoviÃ³ un tÃ©rmino sin que cruzara del todo el signo '='",
        );
      } else if (result.error == "bad_operation") {
        error =
            "Recuerda: lo contrario de multiplicar es dividir. Ponlo debajo del nÃºmero.";
        _handleInvalidMove(
          "IntentÃ³ hacer una operaciÃ³n matemÃ¡tica incorrecta",
        );
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
            "Â¡Muy bien! El $splitCoeff que multiplica a la variable quedÃ³ libre. "
            "ArrÃ¡stralo al otro lado para dejar la variable sola.";
      });
    }
  }

  String _piecesToString(List<EquationLabPiece> list) {
    if (list.isEmpty) return "Ninguna ecuaciÃ³n";
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
    return eq.isEmpty ? "Problema vacÃ­o" : eq;
  }

  void _showLearningFlowOrchestrator(
    String topicId, {
    String? initialEquation,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LearningFlowOrchestrator(
              topicId: topicId,
              initialEquation: initialEquation,
              onFlowComplete: (data) {
                Navigator.pop(context); // Cierra el orchestrator al terminar
                if (data != null) {
                  setState(() {
                    aiExercise = AIExercise.fromJson(data);
                    _showingEmptyPrompt = false;
                    view = 'game';
                  });
                }
              },
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  String? _detectTopic(String msg) {
    final lower = msg.toLowerCase();

    // 1. DetecciÃ³n por palabras clave (segÃºn el plan de integraciÃ³n)
    // â”€â”€ Lineal â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (lower.contains('lineal') ||
        lower.contains('ecuacion lineal') ||
        lower.contains('ecuaciÃ³n lineal') ||
        lower.contains('ax+b') ||
        lower.contains('ecuacion de primer') ||
        lower.contains('primer grado')) {
      return 'linear';
    }
    // â”€â”€ Distributiva â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (lower.contains('distributiva') ||
        lower.contains('distribuir') ||
        lower.contains('parentesis') ||
        lower.contains('parÃ©ntesis') ||
        lower.contains('propiedad distributi')) {
      return 'distributive';
    }
    // â”€â”€ FactorizaciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (lower.contains('factorizar') ||
        lower.contains('factorizacion') ||
        lower.contains('factorizaciÃ³n') ||
        lower.contains('factor comun') ||
        lower.contains('factor comÃºn') ||
        lower.contains('polinomio')) {
      return 'factorization';
    }
    // â”€â”€ CuadrÃ¡tica â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (lower.contains('cuadratica') ||
        lower.contains('cuadrÃ¡tica') ||
        lower.contains('segundo grado') ||
        lower.contains('x^2') ||
        lower.contains('xÂ²') ||
        lower.contains('exponente 2') ||
        lower.contains('formula cuadratica') ||
        lower.contains('bhaskara')) {
      return 'quadratic';
    }
    // â”€â”€ CÃºbica â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (lower.contains('cubica') ||
        lower.contains('cÃºbica') ||
        lower.contains('x^3') ||
        lower.contains('xÂ³') ||
        lower.contains('tercer grado') ||
        lower.contains('tercera potencia') ||
        lower.contains('al cubo')) {
      return 'cubic';
    }

    // 2. DetecciÃ³n por patrones matemÃ¡ticos (Regex)
    final mathMsg = lower.replaceAll(' ', '');

    // Cúbica: contiene ³ o ^3
    if (mathMsg.contains('³') ||
        mathMsg.contains('^3') ||
        mathMsg.contains('Â³')) {
      return 'cubic';
    }

    // Factorización: trinomios o polinomios sin el signo igual (ej: x^2+5x+6)
    if ((mathMsg.contains('²') ||
            mathMsg.contains('Â²') ||
            mathMsg.contains('^2')) &&
        !mathMsg.contains('=')) {
      return 'factorization';
    }

    // Cuadrática: contiene ² o ^2 con un signo igual
    if (mathMsg.contains('²') ||
        mathMsg.contains('Â²') ||
        mathMsg.contains('^2')) {
      return 'quadratic';
    }

    // Distributiva: contiene paréntesis con operaciones dentro, ej: 3(x+2)
    if (RegExp(r'\d*\([^\)]+\)').hasMatch(mathMsg) || mathMsg.contains('(')) {
      return 'distributive';
    }

    // Lineal: contiene '=', y no tiene '^' ni '(' ni exponentes
    if (mathMsg.contains('=') &&
        !mathMsg.contains('^') &&
        !mathMsg.contains('(') &&
        !mathMsg.contains('Â²') &&
        !mathMsg.contains('Â³') &&
        !mathMsg.contains('²') &&
        !mathMsg.contains('³')) {
      // Validar si es una ecuación lineal razonable (tiene algo a los lados del igual)
      if (RegExp(r'[^=]+=[^=]+').hasMatch(mathMsg)) {
        return 'linear';
      }
    }

    return null;
  }

  void _handleSendMessage() {
    if (inputText.trim().isEmpty) return;

    final rawInput = inputText.trim();

    // â”€â”€ 0. Detectar si el usuario pide un tema especÃ­fico â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final topicId = _detectTopic(rawInput);
    if (topicId != null) {
      _showLearningFlowOrchestrator(topicId, initialEquation: rawInput);
      inputController.clear();
      setState(() => inputText = "");
      return;
    }

    // â”€â”€ 1. Intentar parsear siempre como ecuaciÃ³n (con o sin backend) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final parsedPieces = EquationParser.parse(rawInput);
    if (parsedPieces.isNotEmpty) {
      // SI es una ecuaciÃ³n nueva, cargarla directamente en el modo clÃ¡sico
      setState(() {
        pieces = parsedPieces;
        view = 'game';
        _showingEmptyPrompt = false;
        currentLevel = -1;
      });
      _saveToHistory(-1, pieces, "IngresÃ³ la ecuaciÃ³n: $rawInput");

      // Enviar tambiÃ©n al chat para que Banny comente
      if (widget.chatService?.isConnected == true) {
        widget.chatService!.sendMessage("EnsÃ©Ã±ame a resolver: $rawInput");
      }

      inputController.clear();
      setState(() => inputText = "");
      return;
    }

    // â”€â”€ 2. Enviar al chatService si estÃ¡ conectado (conversaciÃ³n normal) â”€â”€â”€â”€â”€â”€â”€
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

      widget.chatService!.sendMessage(rawInput, context: contextPayload);
      inputController.clear();
      setState(() {
        inputText = "";
        if (parsedPieces.isEmpty) {
          // Si era texto libre, tambiÃ©n ocultamos el prompt si estaba visible
          _showingEmptyPrompt = false;
          // Solo mostrar "TÃº: ..." si no era una ecuaciÃ³n (era texto libre)
          showPopup = true;
          popupTitle = "TÃº";
          popupText = rawInput;
        }
      });
      return;
    }
    if (currentLevel == -1) {
      // Si estamos en TeorÃ­a Interactiva pero no hay conexiÃ³n a Banny
      setState(() {
        showPopup = true;
        popupTitle = "Sin conexiÃ³n";
        popupText =
            "No se pudo conectar con Banny. Revisa que el backend estÃ© ejecutÃ¡ndose.";
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
        popupTitle = "Â¡Correcto!";
        popupText = "Respuesta correcta. Avanzando...";
      });

      // Saving next level pieces
      final nextLevelPieces = equationLabLevels[currentLevel + 1].pieces
          .map((p) => p.copyWith())
          .toList();
      _saveToHistory(currentLevel + 1, nextLevelPieces, 'EscribiÃ³: $userText');

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
        popupText = "Hmm, ese nÃºmero no es el resultado. ${level.hint ?? ''}";
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
      isDarkMode: widget.isDarkMode,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_showingEmptyPrompt && pieces.isEmpty && !_exerciseDone)
            _buildGlassmorphismPrompt(),

          AnimatedOpacity(
            opacity: ((_showingEmptyPrompt && pieces.isEmpty) || _exerciseDone)
                ? 0.0
                : 1.0,
            duration: const Duration(milliseconds: 500),
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
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
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
          ),

          // Banny Chat Bar (Bottom)
          if (aiExercise == null && !_exerciseDone) _buildBannyBottomBar(),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismPrompt() {
    final dark = widget.isDarkMode;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 64,
              color: dark
                  ? Colors.white.withValues(alpha: 0.5)
                  : const Color(0xFF60A5FA),
            ),
            const SizedBox(height: 16),
            Text(
              "Por favor ingresa tu ejercicio",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: dark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Escribe la ecuaciÃ³n en la barra de abajo",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: dark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final dark = widget.isDarkMode;
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF1E293B).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: dark ? Colors.white10 : Colors.blue.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🎉", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  "¡Ejercicio Completado!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : Colors.blue[900],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "Nuevo ejercicio",
                    icon: Icons.add_rounded,
                    onPressed: () {
                      setState(() {
                        aiExercise = null;
                        _exerciseDone = false;
                        _showingEmptyPrompt = true;
                        pieces = [];
                        inputText = "";
                        inputController.clear();
                      });
                    },
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: "Volver",
                    icon: Icons.home_rounded,
                    onPressed: () => widget.onExit(),
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final dark = widget.isDarkMode;
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? (dark ? Colors.blueAccent : Colors.blue[600])
            : (dark ? Colors.white10 : Colors.grey[200]),
        foregroundColor: isPrimary
            ? Colors.white
            : (dark ? Colors.white : Colors.black87),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isPrimary ? 4 : 0,
      ),
    );
  }

  Widget _buildBannyBottomBar() {
    final dark = widget.isDarkMode;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: dark ? Colors.white10 : Colors.black12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.blueAccent.withValues(alpha: 0.2)
                        : Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: dark ? Colors.blueAccent[100] : Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 14),

                // Input area
                Expanded(
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: dark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputController,
                            onChanged: (val) => setState(() => inputText = val),
                            onSubmitted: (_) => _handleSendMessage(),
                            decoration: InputDecoration(
                              hintText: "Pausa y pregunta a Banny...",
                              hintStyle: TextStyle(
                                color: dark ? Colors.white38 : Colors.black38,
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: TextStyle(
                              color: dark ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calculate_rounded,
                            color: dark ? Colors.white60 : Colors.black45,
                            size: 24,
                          ),
                          onPressed: () => _showMathKeyboard(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Send button
                ElevatedButton(
                  onPressed: inputText.trim().isNotEmpty
                      ? _handleSendMessage
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTemplateWidget() {
    if (aiExercise == null) return const SizedBox.shrink();

    final dark = widget.isDarkMode;
    void onSolved(bool correct, String feedback) {
      setState(() {
        if (correct) {
          _exerciseDone = true;
          // Omitimos showPopup para evitar duplicidad con la pantalla de completado
        } else {
          popupTitle = "Pista del Tutor";
          popupText = feedback;
          showPopup = true;
        }
      });
    }

    switch (aiExercise!.exerciseType) {
      // NUEVOS JUEGOS
      case 'destructor_ecuaciones':
        return DestructorEcuacionesTemplate(
          exercise: aiExercise!,
          onStepCompleted: () {},
          onExerciseCompleted: () => onSolved(true, "Â¡DestrucciÃ³n completa!"),
          onLivesChanged: (lives) {},
        );
      case 'beatmath':
        return BeatMathTemplate(
          exerciseData: aiExercise!.toJson(),
          onComplete: () => onSolved(true, "Â¡Batiste a las matemÃ¡ticas!"),
        );
      case 'destruir_seleccion':
        return DestruirEcuacionesSeleccionTemplate(
          exerciseData: aiExercise!.toJson(),
          onExerciseCompleted: () =>
              onSolved(true, "¡Ecuaciones seleccionadas y destruidas!"),
        );
      case 'candymath':
        return CandyMathTemplate(
          exercise: aiExercise!,
          onStepCompleted: () {},
          onExerciseCompleted: () => onSolved(true, "Â¡Dulce victoria!"),
          onLivesChanged: (lives) {},
        );
      case 'academia_ninja':
        return AcademiaNinjaTemplate(
          exercise: aiExercise!,
          onStepCompleted: () {},
          onExerciseCompleted: () =>
              onSolved(true, "Â¡Eres un verdadero Ninja del Ãlgebra!"),
          onLivesChanged: (lives) {},
        );
      case 'dardos':
        return DardosTemplate(
          exercise: aiExercise!,
          onStepCompleted: () {},
          onExerciseCompleted: () => onSolved(true, "Â¡En el blanco!"),
          onLivesChanged: (lives) {},
        );

      // ORIGINALES
      case 'drag_drop':
        return DragDropTemplate(
          exercise: aiExercise!,
          isDarkMode: dark,
          onSolved: onSolved,
        );
      case 'tap_destroy':
        return TapDestroyTemplate(
          exercise: aiExercise!,
          isDarkMode: dark,
          onSolved: onSolved,
        );
      case 'fill_blank':
        return FillBlankTemplate(
          exercise: aiExercise!,
          isDarkMode: dark,
          onSolved: onSolved,
        );
      case 'multiple_choice':
      default:
        return MultipleChoiceTemplate(
          exercise: aiExercise!,
          isDarkMode: dark,
          onSolved: onSolved,
        );
    }
  }

  Widget _buildDynamicExerciseLayer({Key? key}) {
    if (aiExercise == null) return SizedBox.shrink(key: key);

    return Container(
      key: key,
      color: Colors.black.withValues(alpha: 0.6),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: _getTemplateWidget(),
    );
  }

  Widget _buildLoadingOverlay({Key? key}) {
    final dark = widget.isDarkMode;
    return Container(
      key: key,
      color: dark
          ? Colors.black.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.9),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                dark ? Colors.blueAccent : Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Banny está pensando...",
              style: TextStyle(
                color: dark ? Colors.white70 : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMathKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MathKeyboard(
          controller: inputController,
          onKeyPressed: (char) {
            final text = inputController.text;
            final selection = inputController.selection;

            if (selection.start >= 0 && selection.end >= 0) {
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                char,
              );
              inputController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: selection.start + char.length,
                ),
              );
            } else {
              inputController.text = text + char;
              inputController.selection = TextSelection.collapsed(
                offset: inputController.text.length,
              );
            }
            setState(() => inputText = inputController.text);
          },
          onBackspace: () {
            final text = inputController.text;
            final selection = inputController.selection;

            if (selection.start >= 0 &&
                selection.end >= 0 &&
                selection.start != selection.end) {
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                '',
              );
              inputController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: selection.start),
              );
            } else if (text.isNotEmpty && selection.start > 0) {
              final newText = text.replaceRange(
                selection.start - 1,
                selection.start,
                '',
              );
              inputController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: selection.start - 1),
              );
            } else if (text.isNotEmpty && selection.start == -1) {
              inputController.text = text.substring(0, text.length - 1);
              inputController.selection = TextSelection.collapsed(
                offset: inputController.text.length,
              );
            }
            setState(() => inputText = inputController.text);
          },
          onSubmit: () {
            Navigator.of(context).pop();
            if (inputText.trim().isNotEmpty) {
              _handleSendMessage();
            }
          },
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Widget _buildPopup() {
    if (!showPopup) return const SizedBox.shrink();
    final dark = widget.isDarkMode;

    return Positioned(
      top: 140,
      left: 16,
      right: 16,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.blueAccent.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.4 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: dark
                              ? [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF0EA5E9),
                                ]
                              : [
                                  const Color(0xFF60A5FA),
                                  const Color(0xFF38BDF8),
                                ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        popupTitle == "InstrucciÃ³n"
                            ? Icons.smart_toy_rounded
                            : Icons.lightbulb_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                                  color: dark
                                      ? const Color(0xFF93C5FD)
                                      : const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => showPopup = false),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? Colors.white.withAlpha(
                                            (0.08 * 255).round(),
                                          )
                                        : Colors.black.withAlpha(
                                            (0.05 * 255).round(),
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: dark
                                        ? Colors.white.withAlpha(
                                            (0.5 * 255).round(),
                                          )
                                        : Colors.black45,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            popupText,
                            style: TextStyle(
                              color: dark
                                  ? Colors.white.withAlpha((0.8 * 255).round())
                                  : Colors.black87,
                              fontSize: 13,
                              height: 1.5,
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
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return const SizedBox.shrink(); // Removido como parte de la unificaciÃ³n
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
                          "RepeticiÃ³n de Pasos",
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

  Widget _buildCurrentContent() {
    if (view == 'loading') {
      return _buildLoadingOverlay(key: const ValueKey('loading'));
    }
    if (aiExercise != null) {
      return _buildDynamicExerciseLayer(
        key: ValueKey('exercise_${aiExercise!.exerciseType}'),
      );
    }
    return InteractiveViewer(
      key: const ValueKey('board_viewer'),
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.5,
      maxScale: 3.0,
      child: _buildBoard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDarkMode;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF020617) : Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    gradient: dark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF020617),
                              Color(0xFF0A1628),
                              Color(0xFF0D1B3E),
                            ],
                          )
                        : RadialGradient(
                            colors: [Colors.white, Colors.grey[100]!],
                            center: Alignment.center,
                            radius: 1.0,
                          ),
                  ),
                ),

                // Aurora animated orbs (ambos temas)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _auroraCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _LabAuroraPainter(
                        t: _auroraCtrl.value,
                        isDarkMode: dark,
                      ),
                    ),
                  ),
                ),

                // Interactive board wrapper
                Positioned.fill(
                  key: _boardKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.0, 0.03),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentContent(),
                  ),
                ),

                // Dashed center line
                if (currentLevel >= 0 &&
                    equationLabLevels[currentLevel].actionType == 'drag' &&
                    aiExercise == null &&
                    view != 'loading')
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: MediaQuery.of(context).size.width / 2,
                    child: CustomPaint(painter: DashedLinePainter()),
                  ),

                // Popups de Banny
                if (showPopup) _buildPopup(),

                // Pantalla de Completado Global (Sobre todo)
                if (_exerciseDone) _buildCompletionScreen(),

                _buildReplayModal(),

                // Barra superior flotante
                _buildTopBar(),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final dark = widget.isDarkMode;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (dark ? Colors.black : Colors.white).withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Exit Button
            _topBarBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: widget.onExit,
            ),

            // Center Title (Optional, showing 'Lab de Ecuaciones')
            if (aiExercise != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (dark ? Colors.black : Colors.white).withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (dark ? Colors.white : Colors.black).withValues(
                      alpha: 0.1,
                    ),
                  ),
                ),
                child: Text(
                  (aiExercise!.uiConfig?['title'] ?? 'LAB DE ECUACIONES')
                      .toUpperCase(),
                  style: TextStyle(
                    color: dark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

            // Right Actions
            Row(
              children: [
                // Theme Toggle
                if (widget.onToggleTheme != null)
                  _topBarBtn(
                    icon: dark
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round,
                    onPressed: widget.onToggleTheme!,
                    color: dark
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFF6366F1),
                  ),

                // Extra actions passed from parent
                if (widget.actions != null) ...widget.actions!,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBarBtn({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final dark = widget.isDarkMode;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          border: Border.all(
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          color: color ?? (dark ? Colors.white : Colors.black87),
          size: 20,
        ),
      ),
    );
  }
}

// --- HELPER CLASSES ---

class _EquationPieceWidget extends StatefulWidget {
  final EquationLabPiece piece;
  final bool isDraggingFeedback;
  final bool isDarkMode;
  final VoidCallback onTap;
  final Function(EquationLabPiece) onAccept;
  final Function(DraggableDetails) onDragEnd;

  const _EquationPieceWidget({
    required this.piece,
    this.isDraggingFeedback = false,
    this.isDarkMode = true,
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

    // Colores reactivos al tema
    final bool dark = widget.isDarkMode;
    Color textColor;

    // Usuario solicitÃ³ nÃºmeros blancos en modo oscuro
    if (dark) {
      textColor = Colors.white;
    } else {
      if (piece.type == 'equals') {
        textColor = Colors.black87;
      } else if (piece.canChangeSign) {
        // NÃºmeros arrastrables: azul en claro
        textColor = Colors.blueAccent[700]!;
      } else {
        textColor = Colors.black87;
      }
    }

    double fontSize = piece.type == 'equals' ? 40 : 50;
    if (piece.isDivisor) {
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
                    child: Container(
                      height: 3,
                      color: dark ? Colors.white70 : Colors.black87,
                    ),
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
              // Fondo del bloque segÃºn tema
              gradient:
                  (piece.type != 'equals' &&
                      !piece.isDivisor &&
                      !widget.isDraggingFeedback)
                  ? LinearGradient(
                      colors: dark
                          ? (piece.canChangeSign
                                // Draggable (nÃºmeros): gradiente verde vibrante en oscuro
                                ? [
                                    const Color(0xFF15803D), // green-700
                                    const Color(0xFF166534), // green-800
                                  ]
                                // TÃ©rmino fijo (x): pizarra profunda
                                : [
                                    const Color(0xFF1E293B), // slate-800
                                    const Color(0xFF0F172A), // slate-900
                                  ])
                          : (piece.canChangeSign
                                // Draggable (nÃºmeros): blanco/celeste muy suave
                                ? [Colors.white, const Color(0xFFF0F9FF)]
                                : [Colors.white, const Color(0xFFF8FAFC)]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: (piece.type == 'equals' || piece.isDivisor)
                  ? Colors.transparent
                  : widget.isDraggingFeedback
                  ? (dark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.grey[100])
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: piece.type != 'equals'
                  ? Border.all(
                      color: dark
                          ? (piece.canChangeSign
                                ? const Color(0xFF22C55E).withValues(
                                    alpha: 0.8,
                                  ) // verde
                                : Colors.white.withValues(alpha: 0.15))
                          : (piece.canChangeSign
                                ? Colors.blue.shade300
                                : const Color(0xFFE2E8F0)),
                      width: piece.canChangeSign ? 1.8 : 1.0,
                    )
                  : null,
              boxShadow: dark && piece.type != 'equals'
                  ? [
                      BoxShadow(
                        color: piece.canChangeSign
                            ? const Color(0xFF22C55E).withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
        // RotaciÃ³n suave entre -0.05 y 0.05 radianes
        final angle = (_controller.value - 0.5) * 0.1;
        return Transform.rotate(angle: angle, child: child);
      },
      child: widget.child,
    );
  }
}

// â”€â”€â”€ Aurora Painter para Equation Lab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LabAuroraPainter extends CustomPainter {
  final double t;
  final bool? isDarkMode;
  _LabAuroraPainter({required this.t, this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (
        baseX: 0.10, baseY: 0.08, ampX: 0.22, ampY: 0.16,
        freqX: 1.0, freqY: 0.7,
        radius: size.shortestSide * 0.60,
        dark: const Color(0x4A2563EB), // azul intenso en oscuro
        light: const Color(0x3393C5FD), // azul suave en claro
      ),
      (
        baseX: 0.88, baseY: 0.60, ampX: 0.20, ampY: 0.18,
        freqX: 0.6, freqY: 1.1,
        radius: size.shortestSide * 0.50,
        dark: const Color(0x380EA5E9), // celeste en oscuro
        light: const Color(0x2938BDF8), // celeste suave en claro
      ),
      (
        baseX: 0.15, baseY: 0.85, ampX: 0.18, ampY: 0.14,
        freqX: 0.8, freqY: 0.5,
        radius: size.shortestSide * 0.55,
        dark: const Color(0x2F3B82F6), // azul mediano en oscuro
        light: const Color(0x2260A5FA), // azul claro en claro
      ),
    ];

    for (final orb in orbs) {
      final cx =
          size.width * (orb.baseX + orb.ampX * sin(2 * pi * t * orb.freqX));
      final cy =
          size.height * (orb.baseY + orb.ampY * cos(2 * pi * t * orb.freqY));

      canvas.drawCircle(
        Offset(cx, cy),
        orb.radius,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90)
          ..color = (isDarkMode ?? true) ? orb.dark : orb.light,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LabAuroraPainter old) =>
      old.t != t || old.isDarkMode != isDarkMode;
}

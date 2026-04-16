import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/tutorial_screen.dart';
import './template_picker_screen.dart';
import './guided_exercise_screen.dart';
import '../models/ai_exercise_model.dart';
import '../providers/user_provider.dart';
import '../services/math_api_service.dart';

// Import all mini-game templates
import './exercise_templates/destructor_ecuaciones_template.dart';
import './exercise_templates/beatmath_template.dart';
import './exercise_templates/academia_ninja_template.dart';
import './exercise_templates/destruirecuaciones_conseleccion_template.dart';
import './exercise_templates/candymath_template.dart';
import './exercise_templates/dardos_template.dart';

enum LearningPhase { tutorial, guidedExercise, loading, miniGame }

class LearningFlowOrchestrator extends StatefulWidget {
  final String topicId;
  final String? initialEquation;
  final Function(Map<String, dynamic>?) onFlowComplete;

  const LearningFlowOrchestrator({
    super.key,
    required this.topicId,
    this.initialEquation,
    required this.onFlowComplete,
  });

  @override
  State<LearningFlowOrchestrator> createState() =>
      _LearningFlowOrchestratorState();
}

class _LearningFlowOrchestratorState extends State<LearningFlowOrchestrator> {
  LearningPhase _currentPhase = LearningPhase.tutorial;
  // null = todavía esperando respuesta del backend
  String? _selectedTemplateId;
  String? _selectedEquation;
  Completer<Map<String, dynamic>>? _templateCompleter;
  // La ecuación concreta que se usará en el ejercicio guiado (seleccionada al inicio)
  late String _guidedEquation;

  // ⭐ NUEVO: Ecuación descompuesta devuelta por el backend
  Map<String, dynamic>? _decomposedExercise;

  @override
  void initState() {
    super.initState();
    _templateCompleter = Completer<Map<String, dynamic>>();

    // Seleccionar una ecuación aleatoria que sea CONSISTENTE toda la sesión
    final equations = _topicEquationsForTopic(widget.topicId);
    _guidedEquation = widget.initialEquation ?? equations[Random().nextInt(equations.length)];

    // Diferimos la selección al primer frame para poder usar context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectMiniGame();
    });
  }

  /// Retorna ecuaciones del topic dado (helper para initState)
  List<String> _topicEquationsForTopic(String topicId) {
    const Map<String, List<String>> defaults = {
      'linear':       ['2x + 5 = 15', '3x - 4 = 11', 'x + 10 = 25', '4x = 20', '5x - 2 = 13'],
      'distributive': ['2(x + 3) = 14', '3(x - 2) = 12', '4(x + 1) = 20', '5(x - 4) = 5'],
      'factorization':['x^2 + 4x = 0', '2x^2 - 6x = 0', 'x^2 + 5x = 0'],
      'quadratic':    ['x^2 - 9 = 0', 'x^2 - 16 = 0', 'x^2 - 25 = 0'],
      'cubic':        ['x^3 = 8', 'x^3 = 27', 'x^3 = 64'],
    };
    return defaults[topicId] ?? ['x + 1 = 2'];
  }

  Future<void> _selectMiniGame() async {
    final userProvider = context.read<UserProvider>();
    final userId = userProvider.userId ?? 'anonymous';

    try {
      final result = await MathApiService.selectTemplate(
        userId: userId,
        topicId: widget.topicId,
      );

      if (mounted) {
        _templateCompleter?.complete(result);
      }
    } catch (e) {
      debugPrint('Error selecting mini game: $e — usando destruir_seleccion como último recurso');
      if (mounted) {
        _templateCompleter?.complete({
          'template_id': 'destruir_seleccion',
          'equation': '2x - 4 = 10',
        });
      }
    }
  }

  final Map<String, List<String>> _topicEquations = {
    'linear': [
      '2x + 5 = 15',
      '3x - 4 = 11',
      'x + 10 = 25',
      '4x = 20',
      '5x - 2 = 13',
    ],
    'distributive': [
      '2(x + 3) = 14',
      '3(x - 2) = 12',
      '4(x + 1) = 20',
      '5(x - 4) = 5',
      '2(x + 5) = 18',
    ],
    'factorization': [
      'x^2 + 4x = 0',
      '2x^2 - 6x = 0',
      'x^2 + 5x = 0',
      '3x^2 + 9x = 0',
      'x^2 - 7x = 0',
    ],
    'quadratic': [
      'x^2 - 9 = 0',
      'x^2 - 16 = 0',
      'x^2 - 25 = 0',
      'x^2 - 36 = 0',
      'x^2 - 1 = 0',
    ],
    'cubic': ['x^3 = 8', 'x^3 = 27', 'x^3 = 64', 'x^3 = 1', 'x^3 = 125'],
  };

  void _advancePhase() {
    if (_currentPhase == LearningPhase.tutorial) {
      setState(() => _currentPhase = LearningPhase.guidedExercise);
    } else if (_currentPhase == LearningPhase.guidedExercise) {
      setState(() => _currentPhase = LearningPhase.loading);
    }
  }

  dynamic _generateInitialExercise() {
    // Si tenemos la ecuación descompuesta del backend, la usamos como base
    if (_decomposedExercise != null) {
      final blocks = _decomposedExercise!['blocks'];
      final equation = _decomposedExercise!['equation'] ?? _guidedEquation;
      final answer = _decomposedExercise!['answer'] ?? "x = ?";

      if (_selectedTemplateId == 'beatmath' ||
          _selectedTemplateId == 'destruir_seleccion') {
        return {
          'id': 1,
          'title': 'Desafío: ${widget.topicId.toUpperCase()}',
          'exercise_type': _selectedTemplateId,
          'equation': equation,
          'blocks': blocks,
          'answer': answer,
          'steps': [
            {
              'equation': equation,
              'question': '¿Qué hacemos primero?',
              'options': []
            },
          ],
        };
      }

      return AIExercise(
        exerciseType: 'drag_drop',
        equation: equation,
        storyContext: '¡Es hora de poner en práctica lo aprendido!',
        pieces: [equation],
        correctAnswer: answer,
        // Pasamos los bloques en uiConfig para que las plantillas los encuentren
        uiConfig: {'blocks': blocks},
      );
    }

    final possibleEquations = _topicEquations[widget.topicId] ?? ['x + 1 = 2'];
    final String eq =
        _selectedEquation ??
        widget.initialEquation ??
        possibleEquations[Random().nextInt(possibleEquations.length)];

    if (_selectedTemplateId == 'beatmath' ||
        _selectedTemplateId == 'destruir_seleccion') {
      return {
        'id': 1,
        'title': 'Desafío: ${widget.topicId.toUpperCase()}',
        'exercise_type': _selectedTemplateId,
        'equation': eq, // BeatMath lo usa directamente
        'steps': [
          {'equation': eq, 'question': '¿Qué hacemos primero?', 'options': []},
        ],
      };
    }

    return AIExercise(
      exerciseType: 'drag_drop',
      equation: eq,
      storyContext: '¡Es hora de poner en práctica lo aprendido!',
      pieces: [eq],
      correctAnswer: '...',
    );
  }

  Widget _buildMiniGame() {

    final exercise = _generateInitialExercise();

    if (_selectedTemplateId == 'destructor_ecuaciones') {
      return DestructorEcuacionesTemplate(
        exercise: exercise as AIExercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(exercise.toJson()),
        onLivesChanged: (_) {},
      );
    } else if (_selectedTemplateId == 'beatmath') {
      return BeatMathTemplate(
        exerciseData: exercise as Map<String, dynamic>,
        onComplete: () => widget.onFlowComplete(exercise),
      );
    } else if (_selectedTemplateId == 'academia_ninja') {
      return AcademiaNinjaTemplate(
        exercise: exercise as AIExercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(exercise.toJson()),
        onLivesChanged: (_) {},
      );
    } else if (_selectedTemplateId == 'destruir_seleccion') {
      return DestruirEcuacionesSeleccionTemplate(
        exerciseData: exercise as Map<String, dynamic>,
        onExerciseCompleted: () => widget.onFlowComplete(exercise),
      );
    } else if (_selectedTemplateId == 'candymath') {
      return CandyMathTemplate(
        exercise: exercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(
          exercise is AIExercise
              ? exercise.toJson()
              : exercise as Map<String, dynamic>,
        ),
        onLivesChanged: (_) {},
      );
    } else if (_selectedTemplateId == 'dardos') {
      return DardosTemplate(
        exercise: exercise as AIExercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(exercise.toJson()),
        onLivesChanged: (_) {},
      );
    } else {
      return Center(
        child: ElevatedButton(
          onPressed: () => widget.onFlowComplete(null),
          child: const Text("Finalizar"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: switch (_currentPhase) {
        LearningPhase.tutorial => TutorialScreen(
          key: const ValueKey('tutorial'),
          topicId: widget.topicId,
          onTutorialComplete: _advancePhase,
        ),
        LearningPhase.guidedExercise => GuidedExerciseScreen(
          key: const ValueKey('guided_exercise'),
          topicId: widget.topicId,
          tutorialEquation: _guidedEquation, // ✅ Ecuación aleatoria fija, elegida al inicio
          onExerciseComplete: _advancePhase,
        ),
        LearningPhase.loading => TemplatePickerScreen(
          key: const ValueKey('template_picker'),
          templateFuture: _templateCompleter!.future,
          topicId: widget.topicId,
          onComplete: (templateId, equation) async {
            // ⭐ NUEVO: Antes de pasar al minijuego, obtenemos la descomposición
            // Usamos _guidedEquation para mantener la consistencia con la fase anterior
            try {
              final decomposed = await MathApiService.decomposeEquation(
                equation: _guidedEquation,
              );
              if (mounted) {
                setState(() {
                  _selectedTemplateId = templateId;
                  _selectedEquation = _guidedEquation; // Forzamos la practicada
                  _decomposedExercise = decomposed;
                  _currentPhase = LearningPhase.miniGame;
                });
              }
            } catch (e) {
              debugPrint('⚠️ Error al descomponer ecuación, usando fallback local: $e');
              if (mounted) {
                setState(() {
                  _selectedTemplateId = templateId;
                  _selectedEquation = _guidedEquation;
                  _currentPhase = LearningPhase.miniGame;
                });
              }
            }
          },
        ),
        LearningPhase.miniGame => KeyedSubtree(
          key: const ValueKey('minigame'),
          child: _buildMiniGame(),
        ),
      },
    );
  }
}

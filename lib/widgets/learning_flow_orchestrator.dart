import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/tutorial_screen.dart';
import './topic_loading_screen.dart';
import '../models/ai_exercise_model.dart';
import '../providers/user_provider.dart';

// Import all mini-game templates
import './exercise_templates/destructor_ecuaciones_template.dart';
import './exercise_templates/beatmath_template.dart';
import './exercise_templates/academia_ninja_template.dart';
import './exercise_templates/destruirecuaciones_conseleccion_template.dart';
import './exercise_templates/candymath_template.dart';
import './exercise_templates/dardos_template.dart';

enum LearningPhase { tutorial, loading, miniGame }

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
  late Type _selectedMiniGameType;

  // Mapa de plantillas por tema (según el plan)
  final Map<String, List<Type>> _templatesByTopic = {
    'linear': [
      DestructorEcuacionesTemplate,
      BeatMathTemplate,
    ],
    'distributive': [
      AcademiaNinjaTemplate,
      DestruirEcuacionesSeleccionTemplate,
      BeatMathTemplate,
    ],
    'factorization': [
      CandyMathTemplate,
      DardosTemplate,
      AcademiaNinjaTemplate,
      BeatMathTemplate,
    ],
    'quadratic': [
      DestructorEcuacionesTemplate,
      CandyMathTemplate,
      BeatMathTemplate,
    ],
    'cubic': [
      BeatMathTemplate,
      DestructorEcuacionesTemplate,
    ],
  };

  // Mapa de afinidad visual: si el usuario tiene este interés/estilo, se prioriza este template
  final Map<String, Type> _styleAffinity = {
    // Intereses del onboarding → plantilla favorita
    'musica': BeatMathTemplate,
    'music': BeatMathTemplate,
    'beat': BeatMathTemplate,
    'dulce': CandyMathTemplate,
    'candy': CandyMathTemplate,
    'juego': AcademiaNinjaTemplate,
    'ninja': AcademiaNinjaTemplate,
    'sport': DardosTemplate,
    'deporte': DardosTemplate,
    'dardos': DardosTemplate,
    // preferredVisualStyle del perfil
    'energetic': BeatMathTemplate,
    'sweet': CandyMathTemplate,
    'action': AcademiaNinjaTemplate,
    'calm': DestructorEcuacionesTemplate,
    'balanced': DestructorEcuacionesTemplate,
  };

  @override
  void initState() {
    super.initState();
    // Diferimos la selección al primer frame para poder usar context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectMiniGame();
    });
    // Asignamos un tipo por defecto por si hay un frame antes del callback
    _selectedMiniGameType =
        (_templatesByTopic[widget.topicId] ?? [DestructorEcuacionesTemplate])
            .first;
  }

  void _selectMiniGame() {
    final possibleTemplates =
        _templatesByTopic[widget.topicId] ?? [DestructorEcuacionesTemplate];

    // ── Prioridad por preferencias del usuario ──────────────────────────────
    final userProvider = context.read<UserProvider>();
    final profile = userProvider.profile;

    Type? preferred;

    if (profile != null) {
      // 1. Ver si el estilo visual preferido tiene afinidad
      final styleKey = profile.preferredVisualStyle.toLowerCase();
      if (_styleAffinity.containsKey(styleKey) &&
          possibleTemplates.contains(_styleAffinity[styleKey])) {
        preferred = _styleAffinity[styleKey];
      }

      // 2. Ver si alguno de los intereses específicos tiene afinidad
      if (preferred == null) {
        for (final interest in profile.specificInterests) {
          final key = interest.toLowerCase();
          for (final affKey in _styleAffinity.keys) {
            if (key.contains(affKey)) {
              final candidate = _styleAffinity[affKey];
              if (candidate != null && possibleTemplates.contains(candidate)) {
                preferred = candidate;
                break;
              }
            }
          }
          if (preferred != null) break;
        }
      }
    }

    // 3. Si no encontramos afinidad, elegir aleatoriamente
    if (mounted) {
      setState(() {
        _selectedMiniGameType =
            preferred ?? possibleTemplates[Random().nextInt(possibleTemplates.length)];
      });
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
    'cubic': [
      'x^3 = 8',
      'x^3 = 27',
      'x^3 = 64',
      'x^3 = 1',
      'x^3 = 125',
    ],
  };

  void _advancePhase() {
    if (_currentPhase == LearningPhase.tutorial) {
      setState(() => _currentPhase = LearningPhase.loading);
    } else if (_currentPhase == LearningPhase.loading) {
      setState(() => _currentPhase = LearningPhase.miniGame);
    }
  }

  dynamic _generateInitialExercise() {
    final possibleEquations = _topicEquations[widget.topicId] ?? ['x + 1 = 2'];
    final String eq = widget.initialEquation ??
        possibleEquations[Random().nextInt(possibleEquations.length)];

    if (_selectedMiniGameType == BeatMathTemplate ||
        _selectedMiniGameType == DestruirEcuacionesSeleccionTemplate) {
      return {
        'id': 1,
        'title': 'Desafío: ${widget.topicId.toUpperCase()}',
        'exercise_type': _selectedMiniGameType == BeatMathTemplate
            ? 'beatmath'
            : 'destruir_seleccion',
        'equation': eq, // BeatMath lo usa directamente
        'steps': [
          {'equation': eq, 'question': '¿Qué hacemos primero?', 'options': []}
        ]
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

    if (_selectedMiniGameType == DestructorEcuacionesTemplate) {
      return DestructorEcuacionesTemplate(
        exercise: exercise as AIExercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(exercise.toJson()),
        onLivesChanged: (_) {},
      );
    } else if (_selectedMiniGameType == BeatMathTemplate) {
      return BeatMathTemplate(
        exerciseData: exercise as Map<String, dynamic>,
        onComplete: () => widget.onFlowComplete(exercise),
      );
    } else if (_selectedMiniGameType == AcademiaNinjaTemplate) {
      return AcademiaNinjaTemplate(
        exercise: exercise as AIExercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(exercise.toJson()),
        onLivesChanged: (_) {},
      );
    } else if (_selectedMiniGameType == DestruirEcuacionesSeleccionTemplate) {
      return DestruirEcuacionesSeleccionTemplate(
        exerciseData: exercise as Map<String, dynamic>,
        onComplete: () => widget.onFlowComplete(exercise),
      );
    } else if (_selectedMiniGameType == CandyMathTemplate) {
      return CandyMathTemplate(
        exercise: exercise,
        onStepCompleted: () {},
        onExerciseCompleted: () => widget.onFlowComplete(
            exercise is AIExercise
                ? exercise.toJson()
                : exercise as Map<String, dynamic>),
        onLivesChanged: (_) {},
      );
    } else if (_selectedMiniGameType == DardosTemplate) {
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
        LearningPhase.loading => TopicLoadingScreen(
            key: const ValueKey('loading'),
            topicId: widget.topicId,
            onComplete: _advancePhase,
          ),
        LearningPhase.miniGame => KeyedSubtree(
            key: const ValueKey('minigame'),
            child: _buildMiniGame(),
          ),
      },
    );
  }
}

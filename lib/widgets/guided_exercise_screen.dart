// lib/widgets/guided_exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/guided_exercise_model.dart';
import '../models/tutorial_scene_model.dart';
import '../services/math_api_service.dart';
import '../services/tts_service.dart';
import 'animated_bunny.dart';
import 'tutorial/tutorial_math_display.dart';

enum GuidedExerciseState {
  loading,
  playing,
  stepSuccess,
  completed,
  error,
}

class GuidedExerciseScreen extends StatefulWidget {
  final String topicId;
  final String? tutorialEquation;
  final VoidCallback onExerciseComplete;

  const GuidedExerciseScreen({
    super.key,
    required this.topicId,
    required this.onExerciseComplete,
    this.tutorialEquation,
  });

  @override
  State<GuidedExerciseScreen> createState() => _GuidedExerciseScreenState();
}

class _GuidedExerciseScreenState extends State<GuidedExerciseScreen> {
  final TTSService _ttsService = TTSService();
  final GlobalKey<AnimatedBunnyState> _bunnyKey = GlobalKey<AnimatedBunnyState>();

  GuidedExerciseState _state = GuidedExerciseState.loading;
  GuidedExercise? _exercise;
  int _currentStepIndex = 0;
  int _errorCount = 0;

  // Visual feedback states
  String? _wrongDroppedBlockId;
  
  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    setState(() => _state = GuidedExerciseState.loading);
    try {
      final exercise = await MathApiService.generateGuidedExercise(
        userId: 'temp_user', 
        topicId: widget.topicId,
        tutorialEquation: widget.tutorialEquation,
      );
      
      if (mounted) {
        setState(() {
          _exercise = exercise;
          _state = GuidedExerciseState.playing;
          _currentStepIndex = 0;
        });
        _playCurrentStepTTS();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = GuidedExerciseState.error);
      }
    }
  }

  void _playCurrentStepTTS() {
    if (_exercise == null || _currentStepIndex >= _exercise!.steps.length) return;
    final step = _exercise!.steps[_currentStepIndex];
    _ttsService.speak(step.ttsText);
  }

  void _handleBlockDragged(String blockId) {
    if (_state != GuidedExerciseState.playing) return;
    final step = _exercise!.steps[_currentStepIndex];

    if (step.targetBlockId != null && blockId == step.targetBlockId) {
      // Correct drop
      _handleCorrectMove();
    } else {
      // Wrong drop
      _handleWrongMove(blockId);
    }
  }

  void _handleCorrectMove() async {
    final step = _exercise!.steps[_currentStepIndex];
    
    // Stop speaking hint, start speaking success
    await _ttsService.stop();
    _ttsService.speak(step.successMessage);

    setState(() {
      _state = GuidedExerciseState.stepSuccess;
      _wrongDroppedBlockId = null;
      _errorCount = 0;
    });

    _executeBunnyAction(BunnyAction.celebrate);

    // Wait for celebration and TTS slightly
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (_currentStepIndex < _exercise!.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _state = GuidedExerciseState.playing;
      });
      _playCurrentStepTTS();
      _executeBunnyAction(_exercise!.steps[_currentStepIndex].bunnyAction);
    } else {
      setState(() {
        _state = GuidedExerciseState.completed;
      });
      _ttsService.speak("¡Excelente trabajo! Ya estás listo para jugar solo.");
      _executeBunnyAction(BunnyAction.celebrate);
    }
  }

  void _handleWrongMove(String blockId) async {
    final step = _exercise!.steps[_currentStepIndex];
    
    setState(() {
      _wrongDroppedBlockId = blockId;
      _errorCount++;
    });

    await _ttsService.stop();
    
    if (_errorCount >= 3) {
      // Auto-advance logic
      _ttsService.speak("Te ayudaré con este paso.");
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _handleCorrectMove();
    } else {
      _ttsService.speak(step.errorMessage);
      
      // Reset animation
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _wrongDroppedBlockId = null);
      }
    }
  }

  void _executeBunnyAction(BunnyAction action) {
    if (_bunnyKey.currentState == null) return;
    switch (action) {
      case BunnyAction.greet:
      case BunnyAction.celebrate:
        _bunnyKey.currentState!.greet();
        break;
      case BunnyAction.magicFlip:
        _bunnyKey.currentState!.doMagicFlip();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF021124), Color(0xFF0A2540)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Práctica: ¡Tu turno!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onExerciseComplete,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Siguiente',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_state == GuidedExerciseState.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              "Preparando tu ejercicio...",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0),
          ],
        ),
      );
    }

    if (_state == GuidedExerciseState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            const Text(
              "Hubo un problema al cargar el ejercicio.",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExercise,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      );
    }

    if (_state == GuidedExerciseState.completed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBunny(
              key: _bunnyKey,
              isSpeaking: false,
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              "¡Completaste tu primer ejercicio!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onExerciseComplete,
              icon: const Icon(Icons.play_arrow),
              label: const Text("¡Vamos al juego!"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ).animate().fadeIn(delay: 1000.ms).moveY(begin: 20),
          ],
        ),
      );
    }

    // Playing or StepSuccess State
    final step = _exercise!.steps[_currentStepIndex];

    List<MathBlock> currentBlocks = [];
    if (_state == GuidedExerciseState.stepSuccess) {
      // Mostrar el resultado del paso recién completado
      currentBlocks = step.blocksAfter.map((b) => b.toMathBlock()).toList();
    } else {
      // Mostrar el estado inicial del paso actual usando blocks_before del backend
      if (step.blocksBefore.isNotEmpty) {
        currentBlocks = step.blocksBefore.map((b) => b.toMathBlock()).toList();
      } else if (_currentStepIndex > 0) {
        // Fallback: usar el resultado del paso anterior
        currentBlocks = _exercise!.steps[_currentStepIndex - 1].blocksAfter.map((b) => b.toMathBlock()).toList();
      } else {
        // Último fallback: parsear la ecuación directamente del ejercicio
        currentBlocks = _parseEquationToBlocks(_exercise!.equation);
      }
    }


    Widget blockDisplay = TutorialMathDisplay(
      blocks: currentBlocks,
      isInteractiveMode: true,
      interactiveTargetId: step.targetBlockId,
      onBlockDragged: _handleBlockDragged,
    );

    if (_wrongDroppedBlockId != null) {
      blockDisplay = blockDisplay.animate(key: ValueKey(_wrongDroppedBlockId))
        .shake(hz: 8, curve: Curves.easeInOutCubic, duration: 400.ms);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(child: _buildPlayerArea(blockDisplay, step)),
          _buildSubtitleArea(step.instruction),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerArea(Widget blockDisplay, GuidedStep step) {
    // Usamos el diseño exacto de TutorialScreen
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Center(
              child: blockDisplay,
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              alignment: Alignment(-0.8, 0.8), // Abajo a la izquierda como base
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: 300.0), // Tamaño Banny ajustado
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeInOut,
                  builder: (context, size, child) {
                    return ListenableBuilder(
                      listenable: _ttsService,
                      builder: (context, _) {
                        return AnimatedBunny(
                          key: _bunnyKey,
                          width: size,
                          height: size,
                          isSpeaking: _ttsService.isPlaying,
                        );
                      },
                    );
                  },
                ).animate()
                 .fadeIn(duration: 800.ms, delay: 300.ms)
                 .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOut),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleArea(String instruction) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(instruction),
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFBBF24),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  // Parsea la ecuación como texto para mostrar blocks básicos de manera separada (fallback cliente)
  List<MathBlock> _parseEquationToBlocks(String equation) {
    final blocks = <MathBlock>[];
    final parts = equation.split('=');
    final leftStr = parts.isNotEmpty ? parts[0].replaceAll(' ', '') : '';
    final rightStr = parts.length > 1 ? parts[1].replaceAll(' ', '') : '';

    // Regex actualizado: captura x^2, x^3 ANTES de caracteres individuales
    final regex = RegExp(r'[+-]?[a-zA-Z]\^[23]|[+-]?\d+|[+-]?[a-zA-Z]|[=+*/()-]');
    
    void tokenize(String sideStr, String prefix) {
      final matches = regex.allMatches(sideStr);
      int i = 0;
      for (final match in matches) {
        String t = match.group(0)!;
        MathBlockType type;
        
        // Detectar x^2 / x^3
        if (RegExp(r'[a-zA-Z]\^[23]$').hasMatch(t.replaceAll(RegExp(r'^[+-]'), ''))) {
          type = MathBlockType.blockDark;
          // Normalizar superíndice
          t = t.replaceAll('^2', '²').replaceAll('^3', '³');
        } else if (t.length == 1 && '+-*/'.contains(t)) {
          type = MathBlockType.operator;
        } else if (t.contains('x') || t.contains('y') || t.contains('(')) {
          type = MathBlockType.blockDark;
        } else {
          type = MathBlockType.blockGreen;
        }
        
        String val = t;
        if (val.startsWith('+') && val.length > 1) val = val.replaceFirst('+', '+ ');
        
        blocks.add(MathBlock(id: '${prefix}_$i', value: val, type: type));
        i++;
      }
    }

    tokenize(leftStr, 'left');
    blocks.add(MathBlock(id: 'eq', value: '=', type: MathBlockType.operator));
    tokenize(rightStr, 'right');

    if (blocks.isEmpty || (blocks.length == 1 && blocks[0].value == '=')) {
      return [
        MathBlock(id: 'left_eq', value: equation.split('=')[0], type: MathBlockType.blockDark),
        MathBlock(id: 'eq', value: '=', type: MathBlockType.operator),
        MathBlock(id: 'right_eq', value: '?', type: MathBlockType.blockGreen),
      ];
    }
    return blocks;
  }

}


// lib/screens/tutorial_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/tutorial_scene_model.dart';
import '../providers/user_provider.dart';
import '../services/banny_chat_service.dart';
import '../widgets/animated_bunny.dart';
import '../widgets/chat_widget.dart';
import '../widgets/tutorial/tutorial_math_display.dart';
import '../widgets/equation_lab.dart';
import '../services/tts_service.dart';

class TutorialScreen extends StatefulWidget {
  final String
  topicId; // ej: 'linear', 'distributive', 'factorization', 'quadratic', 'cubic'
  final VoidCallback? onTutorialComplete;

  const TutorialScreen({
    super.key,
    this.topicId = 'linear',
    this.onTutorialComplete,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  // ── Estado del reproductor ─────────────────────────────────────────────────
  bool _isPlaying = true;
  double _progress = 0.0;
  bool _showContinueBtn = false;
  bool _isInteractiveMode = false;

  // ── Contenido de la escena ────────────────────────────────────────────────
  String _subtitle = 'Preparando la lección...';
  String _speechBubble = '';
  List<MathBlock> _currentBlocks = [];
  Alignment _bunnyAlignment = const Alignment(0.0, 0.0);
  double _bunnySize = 420.0;

  // ── Chat AI ────────────────────────────────────────────────────────────────
  final List<ChatMessage> _chatMessages = [];
  bool _isTyping = false;
  BannyChatService? _chatService;
  StreamSubscription? _chatSubscription;

  // ── Controladores ──────────────────────────────────────────────────────────
  Timer? _sceneTimer;
  final GlobalKey<AnimatedBunnyState> _bunnyKey = GlobalKey();

  // Caché de las escenas elegidas
  late final List<TutorialScene> _scenes;

  // Escena actual para iterar
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _scenes = _getScenesForTopic(widget.topicId);

    // Iniciar automáticamente el tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initChatService();
        _playNextScene();
      }
    });
  }

  Future<void> _initChatService() async {
    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.userId ?? 'tutorial_user';
      _chatService = BannyChatService(userId: userId);
      await _chatService!.connect();

      _chatSubscription = _chatService!.messageStream.listen((data) {
        if (!mounted) return;
        if (data['type'] == 'message') {
          _handleAIResponse(data['content'] as String);
        }
      });

      // Mensaje de bienvenida automático de Banny
      setState(() {
        _chatMessages.add(
          ChatMessage(
            id: 'welcome',
            text:
                '¡Hola! 👋 Soy Banny, tu tutor. Puedes pausar el tutorial en cualquier momento y preguntarme lo que quieras sobre lo que estás viendo.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      debugPrint('[Tutorial] No se pudo conectar al chat: $e');
      // Modo offline: agregar mensaje de bienvenida sin conexión
      if (mounted) {
        setState(() {
          _chatMessages.add(
            ChatMessage(
              id: 'welcome_offline',
              text:
                  '¡Hola! 👋 Soy Banny. Pausa el tutorial y escríbeme si tienes dudas. (Sin conexión al servidor)',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  List<TutorialScene> _getScenesForTopic(String topic) {
    switch (topic) {
      case 'distributive':
        return distributiveTutorialScenes;
      case 'factorization':
        return factorizationTutorialScenes;
      case 'quadratic':
        return quadraticTutorialScenes;
      case 'cubic':
        return cubicTutorialScenes;
      case 'linear':
      default:
        return linearTutorialScenes;
    }
  }

  @override
  void dispose() {
    _sceneTimer?.cancel();
    _chatSubscription?.cancel();
    _chatService?.disconnect();
    super.dispose();
  }

  // ─── CHAT AI ───────────────────────────────────────────────────────────────

  void _onUserSendMessage(String text) {
    setState(() {
      _chatMessages.add(
        ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    if (_chatService?.isConnected == true) {
      // Enviar pregunta con contexto de la escena actual
      final contextPayload = {
        'mode': 'tutorial',
        'topic': widget.topicId,
        'scene_index': _currentIndex,
        'subtitle': _subtitle,
        'speech_bubble': _speechBubble,
        'is_paused': !_isPlaying,
      };
      _chatService!.sendMessage(text, context: contextPayload);
    } else {
      // Fallback inteligente sin conexión
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _addBannyMessage(_getOfflineResponse(text));
      });
    }
  }

  void _handleAIResponse(String payloadStr) {
    String text = payloadStr;
    bool hasVisualExercise = false;

    try {
      final json = jsonDecode(payloadStr) as Map<String, dynamic>;
      text = json['text'] ?? payloadStr;

      // Fase 3: Respuesta Visual (Si el backend manda un ejercicio)
      if (json.containsKey('exercise_type')) {
        hasVisualExercise = true;
      }
    } catch (_) {}

    _addBannyMessage(text);

    if (hasVisualExercise) {
      // Damos un pequeño delay para que el teclado se cierre y Banny "hable" antes del modal (opcional)
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _showVisualExplanationModal(payloadStr);
      });
    }
  }

  void _showVisualExplanationModal(String payloadStr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          // Ocupa el 80% de la pantalla para dejar ver el tutorial de fondo
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(
              0xFF0F172A,
            ).withValues(alpha: 0.8), // Modo oscuro glassmorphism por defecto
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  // Instanciamos la pizarra interactiva de Banny con los datos enviados
                  EquationLabWidget(
                    isDarkMode: true,
                    initialPayloadStr: payloadStr,
                    onExit: () => Navigator.of(context).pop(),
                  ),

                  // Botón de cerrar superior flotante (por si acaso, aunque la pizarra ya tiene botones)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addBannyMessage(String text) {
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _chatMessages.add(
        ChatMessage(
          id: 'banny_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  /// Respuestas básicas offline basadas en palabras clave
  String _getOfflineResponse(String question) {
    final q = question.toLowerCase();
    if (q.contains('signo') ||
        q.contains('cambiar') ||
        q.contains('negativo')) {
      return 'Cuando un término cruza el signo "=", su signo se invierte. Si era +6, pasa a ser -6. Esto mantiene el equilibrio de la ecuación. ⚖️';
    }
    if (q.contains('por qué') || q.contains('para qué')) {
      return 'Buscamos dejar la variable "x" sola en un lado. Para eso, vamos moviendo los demás términos al otro lado. 🎯';
    }
    if (q.contains('arrastrar') || q.contains('mover')) {
      return 'Toca y arrastra el bloque que brilla hacia el otro lado del signo "=". Al soltarlo, el signo cambia automáticamente. ✨';
    }
    return 'Esa es una muy buena pregunta. Observa detenidamente lo que hace Banny en la escena. Puedes retroceder presionando "Reiniciar". 🤔';
  }

  /// Al pausar: envía contexto automático para que Banny comente la escena
  void _sendPauseContext() {
    if (_chatService?.isConnected != true) return;
    if (_currentIndex < 0 || _currentIndex >= _scenes.length) return;

    final contextPayload = {
      'mode': 'tutorial_pause',
      'topic': widget.topicId,
      'scene_index': _currentIndex,
      'subtitle': _subtitle,
      'speech_bubble': _speechBubble,
    };

    _chatService!.sendMessage(
      '¿Puedes explicar brevemente lo que acabas de mostrar en la escena?',
      context: contextPayload,
    );
    setState(() => _isTyping = true);
  }

  // ─── LÓGICA DE REPRODUCCIÓN ───────────────────────────────────────────────

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;

      if (_isPlaying) {
        if (_showContinueBtn) _showContinueBtn = false;
        if (_currentIndex >= _scenes.length - 1) {
          _currentIndex = -1;
        }
        _playNextScene();
      } else {
        _sceneTimer?.cancel();
        _sendPauseContext();
      }
    });
  }

  Future<void> _playNextScene() async {
    if (!mounted || !_isPlaying) return;

    _currentIndex++;

    if (_currentIndex >= _scenes.length) {
      setState(() {
        _isPlaying = false;
        _showContinueBtn = true;
      });
      return;
    }

    final index = _currentIndex;
    final scene = _scenes[index];

    setState(() {
      _progress = (index + 1) / _scenes.length;
      _subtitle = scene.subtitle;
      _speechBubble = scene.speechBubble;
      _currentBlocks = scene.mathBlocks;
      _bunnyAlignment = scene.bunnyAlignment;
      _bunnySize = scene.bunnySize;
    });

    _executeBunnyAction(scene.bunnyAction);

    // ── Sincronización Jessica ──────────────────────────────────────────────
    // Hablar el subtítulo y esperar a que Jessica termine antes de avanzar.
    // Si el usuario pausa durante el habla, cancelamos el Timer posterior.
    await TTSService().speakAndWait(scene.subtitle);

    if (!mounted || !_isPlaying) return; // Respetamos pausa durante el habla

    if (_isInteractiveMode && scene.interactiveTargetId != null) {
      return;
    }

    _sceneTimer = Timer(scene.duration, () {
      if (_isPlaying) _playNextScene();
    });
  }

  void _onBlockDragged(String blockId) {
    if (!_isInteractiveMode || _currentIndex >= _scenes.length) return;

    final scene = _scenes[_currentIndex];
    if (scene.interactiveTargetId == null) return;

    if (blockId == scene.interactiveTargetId) {
      _executeBunnyAction(BunnyAction.celebrate);
      _playNextScene();
    } else {
      setState(() {
        _speechBubble =
            scene.errorFeedback ?? '¡Ese no es el bloque que debemos mover!';
      });
      _executeBunnyAction(BunnyAction.startTalking);
    }
  }

  void _executeBunnyAction(BunnyAction action) {
    if (!mounted || _bunnyKey.currentState == null) return;

    final bState = _bunnyKey.currentState!;

    switch (action) {
      case BunnyAction.none:
        break;
      case BunnyAction.greet:
        bState.greet();
        break;
      case BunnyAction.startTalking:
        break;
      case BunnyAction.stopTalking:
        break;
      case BunnyAction.magicFlip:
        bState.doMagicFlip();
        break;
      case BunnyAction.celebrate:
        bState.greet();
        break;
    }
  }

  // ─── INTERFAZ DE USUARIO ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF021124), Color(0xFF0A2540)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Expanded(child: _buildPlayerArea()),
                          _buildSubtitleArea(),
                          if (_showContinueBtn)
                            _buildContinueButton()
                          else
                            _buildChatPanel(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Tutorial: Cómo jugar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          // Barra de progreso + play/pause minimalista en el header
          _buildMinimalControls(),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _skipTutorial,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Saltar',
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

  /// Controles mínimos: barra de progreso + botón play/pause en el header
  Widget _buildMinimalControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra de progreso pequeña
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              widthFactor: _progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Botón play/pause
        GestureDetector(
          onTap: _togglePlayPause,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              _isPlaying
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
              key: ValueKey(_isPlaying),
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerArea() {
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
            // Ecuación Central
            Center(
              child: TutorialMathDisplay(
                blocks: _currentBlocks,
                isInteractiveMode: _isInteractiveMode,
                interactiveTargetId:
                    _isInteractiveMode &&
                        _currentIndex >= 0 &&
                        _currentIndex < _scenes.length
                    ? _scenes[_currentIndex].interactiveTargetId
                    : null,
                onBlockDragged: _onBlockDragged,
              ),
            ),

            // Zona de DROP visible en modo interactivo
            if (_isInteractiveMode &&
                _currentIndex >= 0 &&
                _currentIndex < _scenes.length &&
                _scenes[_currentIndex].interactiveTargetId != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (d) => _onBlockDragged(d.data),
                  builder: (context, candidateData, rejectedData) {
                    final active = candidateData.isNotEmpty;
                    return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 64,
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF22C55E)
                                  : Colors.white.withValues(alpha: 0.2),
                              width: active ? 2.5 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  active
                                      ? Icons.check_circle_rounded
                                      : Icons.drag_indicator_rounded,
                                  color: active
                                      ? const Color(0xFF22C55E)
                                      : Colors.white54,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  active
                                      ? '¡Suelta aquí!'
                                      : 'Arrastra el bloque aquí ↓',
                                  style: TextStyle(
                                    color: active
                                        ? const Color(0xFF22C55E)
                                        : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        );
                  },
                ),
              ),

            // Personaje Banny
            AnimatedAlign(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              alignment: _bunnyAlignment,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: _bunnySize),
                          duration: const Duration(milliseconds: 2000),
                          curve: Curves.easeInOut,
                          builder: (context, size, child) {
                            return AnimatedBunny(
                              key: _bunnyKey,
                              width: size,
                              height: size,
                              isSpeaking:
                                  _speechBubble.isNotEmpty && _isPlaying,
                            );
                          },
                        )
                        .animate()
                        .fadeIn(duration: 800.ms, delay: 300.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOut,
                        ),
              ),
            ),

            // Overlay de Pausa (toque para continuar)
            if (!_isPlaying && !_showContinueBtn)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Continuar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleArea() {
    final bool waitingForDrag =
        _isInteractiveMode &&
        _currentIndex >= 0 &&
        _currentIndex < _scenes.length &&
        _scenes[_currentIndex].interactiveTargetId != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: waitingForDrag
          ? Container(
                  key: const ValueKey('interactive_banner'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Color(0xFFFBBF24),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _speechBubble.isNotEmpty
                              ? _speechBubble
                              : '¡Tu turno! Arrastra el bloque que brilla ✨',
                          style: const TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideX(begin: -0.1, end: 0, duration: 400.ms)
          : Container(
              key: const ValueKey('subtitle_normal'),
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
                _subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
    );
  }

  // ── PANEL DE CHAT (reemplaza al TutorialPlayerControls) ────────────────────
  Widget _buildChatPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del chat
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _chatService?.isConnected == true
                        ? const Color(0xFF22C55E)
                        : Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_chatService?.isConnected == true
                                    ? const Color(0xFF22C55E)
                                    : Colors.orange)
                                .withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isPlaying
                      ? 'Pausa para preguntarle a Banny 🐰'
                      : 'Banny está listo para ayudarte 🐰',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Widget de chat compacto (igual al de Equation Labs)
          Expanded(
            child: ChatWidget(
              messages: _chatMessages,
              onSendMessage: _onUserSendMessage,
              isTyping: _isTyping,
              isOnline: true, // siempre habilitado (offline fallback interno)
              isCompact: true,
              hintText: _isPlaying
                  ? 'Pausa y pregunta a Banny...'
                  : '¿Tienes alguna duda sobre esta parte?',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child:
          GestureDetector(
                onTap: () {
                  if (!_isInteractiveMode) {
                    setState(() {
                      _isInteractiveMode = true;
                      _showContinueBtn = false;
                      _currentIndex = -1;
                      _isPlaying = true;
                    });
                    _playNextScene();
                  } else {
                    if (widget.onTutorialComplete != null) {
                      widget.onTutorialComplete!();
                    } else {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isInteractiveMode
                            ? '¡Estoy listo para jugar!'
                            : '¡Ahora intenta tú!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.sports_esports, color: Colors.white),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(
                begin: 0.5,
                end: 0,
                curve: Curves.easeOutBack,
                duration: 600.ms,
              ),
    );
  }

  void _skipTutorial() {
    _sceneTimer?.cancel();
    _chatSubscription?.cancel();
    _chatService?.disconnect();
    TTSService().stop(); // Detener a Jessica si está hablando
    
    if (widget.onTutorialComplete != null) {
      widget.onTutorialComplete!();
    } else {
      Navigator.pop(context);
    }
  }
}

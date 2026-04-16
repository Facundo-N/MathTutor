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
import '../widgets/math_keyboard.dart';
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
  
  bool _wasAutoPaused = false; // Bandera para cuando el sistema pausa al final del paso en la fase concreta

  // ── Contenido de la escena ────────────────────────────────────────────────
  String _subtitle = 'Preparando la lección...';
  String _speechBubble = '';
  List<MathBlock> _currentBlocks = [];
  Alignment _bunnyAlignment = const Alignment(0.0, 0.0);
  double _bunnySize = 0.0; // Se inicializa en didChangeDependencies

  // ── Chat AI ────────────────────────────────────────────────────────────────
  final List<ChatMessage> _chatMessages = [];

  BannyChatService? _chatService;
  StreamSubscription? _chatSubscription;

  // ── Controladores ──────────────────────────────────────────────────────────
  Timer? _sceneTimer;
  final GlobalKey<AnimatedBunnyState> _bunnyKey = GlobalKey();
  final TextEditingController inputController = TextEditingController();
  String inputText = "";

  // Caché de las escenas elegidas
  late List<TutorialScene> _scenes;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inicializar tamaño de Banny de forma responsiva
    if (_bunnySize == 0.0) {
      final screenH = MediaQuery.of(context).size.height;
      _bunnySize = (screenH * 0.35).clamp(180.0, 420.0);
    }
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
    inputController.dispose();
    super.dispose();
  }

  // ─── CHAT AI ───────────────────────────────────────────────────────────────

  void _handleSendMessage() {
    if (inputText.trim().isEmpty) return;

    final text = inputText.trim();
    setState(() {
      _chatMessages.add(
        ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      inputText = "";
      inputController.clear();

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

  }

  // ─── LÓGICA DE REPRODUCCIÓN ───────────────────────────────────────────────

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _wasAutoPaused = false; // Usuario presionó botón manually

      if (_isPlaying) {
        if (_showContinueBtn) _showContinueBtn = false;
        if (_currentIndex >= _scenes.length - 1) {
          _currentIndex = -1;
        }
        // Si estamos pausados y damos play en concreto, queremos avanzar!
        _playNextScene();
      } else {
        _sceneTimer?.cancel();
        if (!_wasAutoPaused) {
           _sendPauseContext();
        }
      }
    });
  }

  Future<void> _playNextScene() async {
    if (!mounted || !_isPlaying) return;

    _currentIndex++;

    if (_currentIndex >= _scenes.length) {
      // Fin del tutorial, mostrar botón gigante de Siguiente!
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

    _sceneTimer = Timer(scene.duration, () {
      if (_isPlaying) _playNextScene();
    });
  }

  void _onBlockDragged(String blockId) {
    // Ya no usamos el modo interactivo con arrastre durante el tutorial guiado
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
    final screenH = MediaQuery.of(context).size.height;
    final isSmallScreen = screenH < 700;

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
          child: Column(
            children: [
              _buildHeader(isSmallScreen: isSmallScreen),
              Expanded(
                child: Column(
                  children: [
                    // 1. Player Area
                    Expanded(
                      child: _buildPlayerArea(isSmallScreen: isSmallScreen),
                    ),

                    // 2. Subtítulo (debajo del player)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: isSmallScreen ? 4 : 8,
                      ),
                      child: _buildSubtitleArea(isSmallScreen: isSmallScreen),
                    ),

                    // 3. Chat o Botón de Continuar (al fondo)
                    if (_showContinueBtn)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, isSmallScreen ? 6 : 12),
                        child: _buildContinueButton(isSmallScreen: isSmallScreen),
                      )
                    else
                      _buildChatPanel(isSmallScreen: isSmallScreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isSmallScreen}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, isSmallScreen ? 6 : 10, 12, isSmallScreen ? 4 : 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: isSmallScreen ? 22 : 28,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: isSmallScreen ? 8 : 16),
          Expanded(
            child: Text(
              'Tutorial: Cómo jugar',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 15 : 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Barra de progreso + play/pause minimalista en el header
          _buildMinimalControls(isSmallScreen: isSmallScreen),
          SizedBox(width: isSmallScreen ? 4 : 8),
          TextButton(
            onPressed: _skipTutorial,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12,
                vertical: 4,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Saltar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Controles mínimos: barra de progreso + botón play/pause en el header
  Widget _buildMinimalControls({required bool isSmallScreen}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barra de progreso pequeña
        Container(
          width: isSmallScreen ? 56 : 80,
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
        SizedBox(width: isSmallScreen ? 6 : 12),
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
              size: isSmallScreen ? 28 : 36,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerArea({required bool isSmallScreen}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En lugar del height total de la pantalla, usamos el área real disponible (constraints.maxHeight).
        // Así Banny siempre será proporcional al área de juego y no tapará las ecuaciones.
        final availableHeight = constraints.maxHeight;
        final adaptiveBunnySize = (availableHeight * (isSmallScreen ? 0.55 : 0.65)).clamp(100.0, 420.0);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 0),
          width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
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
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
        child: Stack(
          children: [
            // Ecuación Central
            Center(
              child: TutorialMathDisplay(
                blocks: _currentBlocks,
                isInteractiveMode: false,
                interactiveTargetId: null,
                onBlockDragged: _onBlockDragged,
              ),
            ),

            // Personaje Banny
            AnimatedAlign(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              alignment: _bunnyAlignment,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: adaptiveBunnySize),
                  duration: const Duration(milliseconds: 2000),
                  curve: Curves.easeInOut,
                  builder: (context, size, child) {
                    return ListenableBuilder(
                      listenable: TTSService(),
                      builder: (context, _) {
                        return AnimatedBunny(
                          key: _bunnyKey,
                          width: size,
                          height: size,
                          isSpeaking: _speechBubble.isNotEmpty &&
                              _isPlaying &&
                              TTSService().isPlaying,
                        );
                      },
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
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.9),
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
      },
    );
  }

  Widget _buildSubtitleArea({required bool isSmallScreen}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: const ValueKey('subtitle_normal'),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 14 : 24,
          vertical: isSmallScreen ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          border: Border.all(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFFBBF24),
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          maxLines: isSmallScreen ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildContinueButton({required bool isSmallScreen}) {
    return Padding(
      padding: EdgeInsets.only(top: isSmallScreen ? 6 : 12, bottom: isSmallScreen ? 4 : 8),
      child: GestureDetector(
            onTap: () {
              if (widget.onTutorialComplete != null) {
                widget.onTutorialComplete!();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
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
                    '¡Ahora intenta tú!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 15 : 18,
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

  // ── NUEVO PANEL DE CHAT (Clon de EquationLab) ──────────────────────────────
  Widget _buildChatPanel({required bool isSmallScreen}) {
    // Última burbuja: muestra el mensaje más reciente o el saludo de Banny
    final lastMsg = _chatMessages.isNotEmpty ? _chatMessages.last : null;
    final bubbleText = lastMsg?.text ??
        '¡Hola! 👋 Soy Banny, tu tutor. Pausa y pregúntame lo que quieras.';

    final double avatarSize = isSmallScreen ? 36 : 48;
    final double inputHeight = isSmallScreen ? 44 : 60;
    final double sendBtnPad = isSmallScreen ? 10 : 14;
    final double hPad = MediaQuery.of(context).padding.bottom + (isSmallScreen ? 10 : 16);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Indicador — sólo si hay espacio
        if (!isSmallScreen)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Row(
              children: [
                const Text('🟠', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 8),
                Text(
                  lastMsg != null ? 'Banny respondió' : 'Pausa y pregunta a Banny',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.psychology, size: 14, color: Colors.white54),
              ],
            ),
          ),

        // Burbuja del último mensaje
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 10 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              bubbleText,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isSmallScreen ? 12 : 14,
                height: 1.4,
              ),
              maxLines: isSmallScreen ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        SizedBox(height: isSmallScreen ? 6 : 12),

        // Barra inferior unificada
        Container(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 10 : 16,
            isSmallScreen ? 10 : 16,
            isSmallScreen ? 10 : 16,
            hPad,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: const Border(top: BorderSide(color: Colors.white10)),
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
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: avatarSize * 0.5,
                  color: Colors.blueAccent[100],
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 14),

              // Input area
              Expanded(
                child: Container(
                  height: inputHeight,
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputController,
                          onChanged: (val) => setState(() => inputText = val),
                          onSubmitted: (_) => _handleSendMessage(),
                          decoration: InputDecoration(
                            hintText: isSmallScreen
                                ? 'Pregunta a Banny...'
                                : 'Pausa y pregunta a Banny...',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 13 : 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.calculate_rounded,
                          color: Colors.white60,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        onPressed: () => _showMathKeyboard(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 14),

              // Send button
              ElevatedButton(
                onPressed: inputText.trim().isNotEmpty ? _handleSendMessage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: const CircleBorder(),
                  padding: EdgeInsets.all(sendBtnPad),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 18 : 24,
                ),
              ),
            ],
          ),
        ),
      ],
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
          onClose: () => Navigator.pop(context),
          onSubmit: () {
            _handleSendMessage();
            Navigator.pop(context);
          },
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
            if (selection.start > 0 && selection.start == selection.end) {
              final newText = text.replaceRange(
                selection.start - 1,
                selection.start,
                '',
              );
              inputController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: selection.start - 1,
                ),
              );
            } else if (selection.start >= 0 && selection.end > selection.start) {
              final newText = text.replaceRange(selection.start, selection.end, '');
              inputController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: selection.start),
              );
            }
            setState(() => inputText = inputController.text);
          },
        );
      },
    );
  }
}

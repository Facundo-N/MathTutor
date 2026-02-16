// lib/screens/banny_chat_screen.dart (VERSIÓN CORREGIDA - SIN ERRORES)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/banny_chat_service.dart';

class BannyChatScreen extends StatefulWidget {
  final String userId;

  const BannyChatScreen({super.key, this.userId = 'user_123'});

  @override
  State<BannyChatScreen> createState() => _BannyChatScreenState();
}

class _BannyChatScreenState extends State<BannyChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController messageController = TextEditingController();
  final ScrollController chatScrollController = ScrollController();
  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  List<BannyChatMessage> messages = [];

  late BannyChatService _bannyChatService;
  String? currentAIResponse;
  String? currentUserExercise;

  bool isOnline = false;
  bool isTyping = false;
  bool isAIResponding = false;
  double sheetSize = 0.0;
  bool showBoard = false;
  bool isExercise = false;

  String? detectedEquation;
  List<FlSpot>? graphData;
  String? graphTitle;

  late AnimationController cardAnimationController;
  late Animation<double> cardSlideAnimation;
  late Animation<double> cardScaleAnimation;

  int currentVisibleStep = 0;
  List<StepAnimationControllers> stepAnimations = [];

  late FlutterTts _flutterTts;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    addInitialMessage();

    cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    cardSlideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(
        parent: cardAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    cardScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: cardAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _initializeTTS();
    _initializeBannyChat();
  }

  Future<void> _initializeTTS() async {
    _flutterTts = FlutterTts();

    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      print('❌ TTS Error: $msg');
      if (mounted) setState(() => isSpeaking = false);
    });

    print('✅ TTS inicializado');
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    try {
      await _flutterTts.stop();
      final cleanText = _cleanTextForTTS(text);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      print('❌ Error TTS: $e');
    }
  }

  String _cleanTextForTTS(String text) {
    return text
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\\', '')
        .replaceAll(RegExp(r'\$+'), '')
        .replaceAll('frac', 'fracción')
        .replaceAll('^', ' elevado a ')
        .replaceAll('=', ' igual a ')
        .trim();
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
      if (mounted) setState(() => isSpeaking = false);
    } catch (e) {
      print('❌ Error deteniendo TTS: $e');
    }
  }

  bool _isExercise(String text) {
    final patterns = [
      r'\d+\s*[\+\-\*\/\=]\s*\d+',
      r'\d*[xX]\s*[\+\-\=]',
      r'[\+\-\*\/\(\)]\s*[\d\w]',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern).hasMatch(text)) return true;
    }

    final questionWords = [
      'qué',
      'cómo',
      'cuándo',
      'dónde',
      'por qué',
      'quién',
      'explica',
      'ayuda',
      'entiendo',
      'significa',
    ];

    final lowerText = text.toLowerCase();
    for (final word in questionWords) {
      if (lowerText.contains(word)) return false;
    }

    return false;
  }

  String? _extractLatexEquation(String text) {
    text = text.trim();

    final linearPattern = RegExp(r'(\d*)([xX])\s*([+\-])\s*(\d+)\s*=\s*(\d+)');
    final match = linearPattern.firstMatch(text);

    if (match != null) {
      final a = match.group(1)?.isEmpty ?? true ? '' : match.group(1);
      final x = 'x';
      final op = match.group(3);
      final b = match.group(4);
      final c = match.group(5);

      return '$a$x $op $b = $c';
    }

    if (RegExp(r'^\d+\s*[\+\-\*\/]\s*\d+$').hasMatch(text)) {
      return text;
    }

    return text;
  }

  List<FlSpot>? _generateGraphData(String equation) {
    final linearPattern = RegExp(r'[yY]\s*=\s*(\d*)[xX]\s*([+\-])\s*(\d+)');
    final linearMatch = linearPattern.firstMatch(equation);

    if (linearMatch != null) {
      final m =
          double.tryParse(
            linearMatch.group(1)?.isEmpty ?? true ? '1' : linearMatch.group(1)!,
          ) ??
          1;
      final op = linearMatch.group(2);
      final b = double.tryParse(linearMatch.group(3)!) ?? 0;
      final bValue = op == '-' ? -b : b;

      return List.generate(41, (i) {
        final x = (i - 20).toDouble();
        final y = m * x + bValue;
        return FlSpot(x, y);
      });
    }

    final quadraticPattern = RegExp(r'[yY]\s*=\s*(\d*)[xX]\^2');
    if (quadraticPattern.hasMatch(equation)) {
      return List.generate(41, (i) {
        final x = (i - 20) / 2;
        final y = x * x;
        return FlSpot(x, y);
      });
    }

    return null;
  }

  Future<void> _initializeBannyChat() async {
    Future.microtask(() async {
      try {
        print('🔌 Conectando a Banny WebSocket...');

        _bannyChatService = BannyChatService(userId: widget.userId);
        await _bannyChatService.connect();

        if (mounted) {
          setState(() => isOnline = true);
          print('✅ Banny WebSocket conectado');
        }

        _bannyChatService.messageStream.listen(
          (message) {
            if (mounted) _handleBannyMessage(message);
          },
          onError: (error) {
            print('❌ WebSocket error: $error');
            if (mounted) setState(() => isOnline = false);
          },
        );
      } catch (e) {
        print('❌ Error conectando Banny: $e');
        if (mounted) setState(() => isOnline = false);
      }
    });
  }

  void _handleBannyMessage(Map<String, dynamic> message) {
    final content = message['content'] ?? '';
    final sender = message['sender'] ?? 'banny';
    final isError = message['error'] ?? false;

    setState(() {
      isTyping = false;
      isAIResponding = false;

      messages.add(
        BannyChatMessage(
          id: DateTime.now().toString(),
          text: content,
          isUser: sender == 'user',
          timestamp: DateTime.now(),
          isError: isError,
        ),
      );

      if (!isError && sender != 'user') {
        currentAIResponse = content;
        showBoard = true;

        if (isExercise && currentUserExercise != null) {
          detectedEquation = _extractLatexEquation(currentUserExercise!);
          graphData = _generateGraphData(content);

          if (graphData != null) {
            graphTitle = 'Gráfico de la función';
          }
        }

        currentVisibleStep = 0;
        _animateStepsSequentially();
      }
    });

    scrollToBottom();

    if (showBoard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && sheetController.isAttached) {
          sheetController.animateTo(
            isExercise ? 0.85 : 0.55,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !isError) _speak(content);
      });
    }
  }

  void _animateStepsSequentially() async {
    final steps = _parseSteps(currentAIResponse ?? '');
    if (steps.isEmpty) return;

    for (var anim in stepAnimations) {
      anim.dispose();
    }
    stepAnimations.clear();

    for (int i = 0; i < steps.length; i++) {
      stepAnimations.add(StepAnimationControllers(vsync: this));
    }

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(Duration(milliseconds: i == 0 ? 400 : 1200));

      if (mounted) {
        setState(() {
          currentVisibleStep = i + 1;
        });

        stepAnimations[i].startAnimations();

        if (i < steps.length) {
          await Future.delayed(const Duration(milliseconds: 300));
          _speak(steps[i]);
        }
      }
    }
  }

  void addInitialMessage() {
    setState(() {
      messages.add(
        BannyChatMessage(
          id: '1',
          text:
              '¡Hola! Soy Banny, tu tutor de IA. Podés enviarme ejercicios matemáticos o hacer preguntas 😊',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void addMessage(String text, bool isUser) {
    setState(() {
      messages.add(
        BannyChatMessage(
          id: DateTime.now().toString(),
          text: text,
          isUser: isUser,
          timestamp: DateTime.now(),
        ),
      );
    });
    scrollToBottom();
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty || !isOnline) return;

    _stopSpeaking();

    final isExerciseDetected = _isExercise(text);

    setState(() {
      isExercise = isExerciseDetected;
      currentUserExercise = isExerciseDetected ? text : null;
      detectedEquation = null;
      graphData = null;
      currentVisibleStep = 0;
    });

    addMessage(text, true);
    messageController.clear();

    setState(() {
      isTyping = true;
      isAIResponding = true;
      showBoard = isExerciseDetected;
    });

    if (isExerciseDetected) {
      cardAnimationController.forward(from: 0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && sheetController.isAttached) {
          sheetController.animateTo(
            0.35,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }

    _bannyChatService.sendMessage(text);
    scrollToBottom();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (chatScrollController.hasClients) {
        chatScrollController.animateTo(
          chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    chatScrollController.dispose();
    cardAnimationController.dispose();

    for (var anim in stepAnimations) {
      anim.dispose();
    }

    _flutterTts.stop();
    _bannyChatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF6B5CE7).withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  buildHeader(),
                  Expanded(
                    child: Stack(
                      children: [
                        buildChatMessages(),
                        if (showBoard)
                          NotificationListener<DraggableScrollableNotification>(
                            onNotification: (notification) {
                              setState(() => sheetSize = notification.extent);
                              return true;
                            },
                            child: buildDraggableSheet(),
                          ),
                      ],
                    ),
                  ),
                  buildMessageInput(),
                ],
              ),
              buildConnectionIndicator(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNav(),
    );
  }

  // ==================== UI WIDGETS ====================

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Banny - AI Tutor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (isSpeaking) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isSpeaking)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.stop, color: Colors.white, size: 20),
                onPressed: _stopSpeaking,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.remove, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChatMessages() {
    return ListView.builder(
      controller: chatScrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: showBoard ? 450 : 100,
      ),
      itemCount: messages.length + (isTyping && !isAIResponding ? 1 : 0),
      itemBuilder: (context, index) {
        if (isTyping && !isAIResponding && index == messages.length) {
          return buildTypingIndicator();
        }
        return buildMessageBubble(messages[index]);
      },
    );
  }

  Widget buildMessageBubble(BannyChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
                )
              : null,
          color: message.isUser
              ? null
              : (message.isError ? Colors.red.shade100 : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: message.isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: message.isUser
                  ? const Color(0xFF6B5CE7).withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 15,
            color: message.isUser
                ? Colors.white
                : (message.isError ? Colors.red.shade900 : Colors.black87),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget buildDraggableSheet() {
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.0,
      minChildSize: 0.0,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FE), Colors.white],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5CE7).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              buildDragHandle(),
              if (isExercise && currentUserExercise != null)
                buildUserExerciseCard(),
              buildAIResponseHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: isAIResponding
                    ? buildAILoadingState()
                    : buildAIResponseContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildDragHandle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget buildUserExerciseCard() {
    return AnimatedBuilder(
      animation: cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, cardSlideAnimation.value),
          child: Transform.scale(scale: cardScaleAnimation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, const Color(0xFF6B5CE7).withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF6B5CE7), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5CE7).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'TU EJERCICIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5CE7),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (detectedEquation != null)
              Math.tex(
                detectedEquation!,
                mathStyle: MathStyle.display,
                textStyle: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              )
            else
              Text(
                currentUserExercise!,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 2,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget buildAIResponseHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isSpeaking
                  ? const Icon(Icons.volume_up, color: Colors.white, size: 24)
                  : const Text('🤖', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExercise ? 'Resolución Visual' : 'Respuesta de Banny',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSpeaking
                      ? '🔊 Explicando paso a paso...'
                      : 'Con gráficos y animaciones',
                  style: TextStyle(
                    fontSize: 13,
                    color: isSpeaking
                        ? const Color(0xFF6B5CE7)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAILoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6B5CE7).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B5CE7),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isExercise
                ? 'Generando visualización...'
                : 'Banny está pensando...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAIResponseContent(ScrollController scrollController) {
    if (currentAIResponse == null || currentAIResponse!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isExercise
                  ? 'Esperando solución...'
                  : 'Hacé una pregunta para ver\nla respuesta aquí',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      children: [
        if (isExercise && currentUserExercise != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B5CE7).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '¡Pizarra Interactiva!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Resuelve el ejercicio de forma táctil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/board',
                            arguments: currentUserExercise,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6B5CE7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.open_in_new, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Abrir Pizarra',
                              style: TextStyle(
                                fontSize: 16,
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

        if (isExercise) const SizedBox(height: 24),

        if (graphData != null) buildGraphCard(),
        if (graphData != null) const SizedBox(height: 24),
        buildFormattedAIResponse(currentAIResponse!),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget buildGraphCard() {
    if (graphData == null) return const SizedBox.shrink();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6B5CE7).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5CE7).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Color(0xFF6B5CE7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                graphTitle ?? 'Gráfico',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('x'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('y'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: graphData!,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6B5CE7).withOpacity(0.3),
                          const Color(0xFF8B7CE8).withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormattedAIResponse(String response) {
    final hasSteps = response.contains(RegExp(r'(Paso \d+|Step \d+|\d+\.)'));

    if (hasSteps) {
      final steps = _parseSteps(response);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          if (index >= currentVisibleStep) {
            return const SizedBox.shrink();
          }

          return buildAnimatedStepCard(index, step);
        }).toList(),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6B5CE7).withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5CE7).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          _cleanTextForDisplay(response),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.6,
          ),
        ),
      );
    }
  }

  String _cleanTextForDisplay(String text) {
    return text
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\\', '')
        .trim();
  }

  Widget buildAnimatedStepCard(int index, String content) {
    if (index >= stepAnimations.length) {
      return const SizedBox.shrink();
    }

    final animations = stepAnimations[index];

    return AnimatedBuilder(
      animation: Listenable.merge([
        animations.slideController,
        animations.rotationController,
        animations.pulseController,
      ]),
      builder: (context, child) {
        final slideValue = animations.slideAnimation.value;
        final rotationValue = animations.rotationAnimation.value;
        final pulseValue = animations.pulseAnimation.value;

        return Transform.translate(
          offset: Offset(0, 30 * (1 - slideValue)),
          child: Opacity(
            opacity: slideValue,
            child: Transform.scale(
              scale: 0.9 + (0.1 * slideValue),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6B5CE7).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF6B5CE7,
                      ).withOpacity(0.08 * slideValue),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform.rotate(
                          angle: rotationValue * 2 * math.pi,
                          child: Transform.scale(
                            scale: pulseValue,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.lerp(
                                      const Color(0xFF6B5CE7),
                                      const Color(0xFF8B7CE8),
                                      rotationValue,
                                    )!,
                                    Color.lerp(
                                      const Color(0xFF8B7CE8),
                                      const Color(0xFF6B5CE7),
                                      rotationValue,
                                    )!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6B5CE7,
                                    ).withOpacity(0.4 * pulseValue),
                                    blurRadius: 12 * pulseValue,
                                    offset: Offset(0, 4 * pulseValue),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  (index + 1).toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PASO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B5CE7),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _cleanTextForDisplay(content),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _parseSteps(String response) {
    final stepPattern = RegExp(
      r'(Paso \d+:|Step \d+:|\d+\.)\s*([^\n]+(?:\n(?!Paso|Step|\d+\.)[^\n]+)*)',
      multiLine: true,
    );

    final matches = stepPattern.allMatches(response);

    return matches
        .map((match) {
          return match.group(2)?.trim() ?? '';
        })
        .where((step) => step.isNotEmpty)
        .toList();
  }

  Widget buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'Escribe un ejercicio o pregunta...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    isExercise ? Icons.calculate : Icons.chat_bubble_outline,
                    color: Colors.grey,
                  ),
                ),
                enabled: isOnline,
                onSubmitted: (_) => sendMessage(),
                onChanged: (text) {
                  final detected = _isExercise(text);
                  if (detected != isExercise) {
                    setState(() => isExercise = detected);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B5CE7).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: isOnline ? sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildConnectionIndicator() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isOnline ? Colors.green : Colors.orange).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'AI 🧠' : 'OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildNavItem(icon: Icons.home_outlined, isActive: false),
              buildNavItem(icon: Icons.chat_bubble_outline, isActive: true),
              buildNavItem(icon: Icons.bar_chart_rounded, isActive: false),
              buildNavItem(icon: Icons.person_outline, isActive: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNavItem({required IconData icon, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.grey.shade400,
        size: 24,
      ),
    );
  }
}

// ==================== WIDGET ANIMATEDMATHBOARD (CORREGIDO) ====================

class AnimatedMathBoard extends StatefulWidget {
  final String operation;
  final List<String> steps;
  final Function(String)? onStepComplete;

  const AnimatedMathBoard({
    super.key,
    required this.operation,
    required this.steps,
    this.onStepComplete,
  });

  @override
  State<AnimatedMathBoard> createState() => _AnimatedMathBoardState();
}

class _AnimatedMathBoardState extends State<AnimatedMathBoard>
    with TickerProviderStateMixin {
  List<MathElement> elements = [];
  int currentStep = 0;
  bool _isDisposed =
      false; // ⭐ NUEVO: Flag para evitar setState después de dispose

  @override
  void initState() {
    super.initState();
    _parseAndAnimate();
  }

  @override
  void dispose() {
    _isDisposed = true; // ⭐ NUEVO: Marcar como disposed
    super.dispose();
  }

  void _parseAndAnimate() {
    if (widget.operation.contains(RegExp(r'[xX]'))) {
      _animateEquation();
    } else if (widget.operation.contains('+')) {
      _animateFusion();
    } else if (widget.operation.contains('-')) {
      _animateEating();
    } else if (widget.operation.contains('*')) {
      _animateMultiplication();
    }
  }

  Future<void> _animateFusion() async {
    final parts = widget.operation.split('+');
    if (parts.length != 2) return;

    final num1 = int.tryParse(parts[0].trim()) ?? 0;
    final num2 =
        int.tryParse(parts[1].trim().replaceAll('=', '').replaceAll('?', '')) ??
        0;
    final result = num1 + num2;

    // ⭐ VERIFICAR mounted antes de setState
    if (!mounted || _isDisposed) return;

    setState(() {
      elements = [
        MathElement(id: 'n1', value: '$num1', position: const Offset(80, 150)),
        MathElement(id: 'op', value: '+', position: const Offset(150, 150)),
        MathElement(id: 'n2', value: '$num2', position: const Offset(220, 150)),
      ];
    });

    await Future.delayed(const Duration(seconds: 1));

    // ⭐ VERIFICAR mounted después del delay
    if (!mounted || _isDisposed) return;

    setState(() {
      elements[0].position = const Offset(150, 150);
      elements[2].position = const Offset(150, 150);
      elements[1].opacity = 0.0;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    // ⭐ VERIFICAR mounted después del delay
    if (!mounted || _isDisposed) return;

    setState(() {
      elements[0].opacity = 0.0;
      elements[2].opacity = 0.0;
      elements.add(
        MathElement(
          id: 'result',
          value: '$result',
          position: const Offset(150, 150),
          scale: 1.5,
          color: Colors.green,
        ),
      );
    });

    widget.onStepComplete?.call('Los números se fusionaron en $result');
  }

  Future<void> _animateEating() async {
    final parts = widget.operation.split('-');
    if (parts.length != 2) return;

    final num1 = int.tryParse(parts[0].trim()) ?? 0;
    final num2 =
        int.tryParse(parts[1].trim().replaceAll('=', '').replaceAll('?', '')) ??
        0;
    final result = num1 - num2;

    // ⭐ VERIFICAR mounted antes de setState
    if (!mounted || _isDisposed) return;

    setState(() {
      elements = [
        MathElement(id: 'n1', value: '$num1', position: const Offset(80, 150)),
        MathElement(id: 'op', value: '-', position: const Offset(150, 150)),
        MathElement(id: 'n2', value: '$num2', position: const Offset(220, 150)),
      ];
    });

    await Future.delayed(const Duration(seconds: 1));

    // ⭐ VERIFICAR mounted después del delay
    if (!mounted || _isDisposed) return;

    setState(() {
      elements[0].scale = 1.3;
      elements[2].scale = 0.5;
      elements[2].opacity = 0.3;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // ⭐ VERIFICAR mounted después del delay
    if (!mounted || _isDisposed) return;

    setState(() {
      elements[2].opacity = 0.0;
      elements[1].opacity = 0.0;
      elements[0].value = '$result';
      elements[0].scale = 1.5;
      elements[0].color = Colors.orange;
    });

    widget.onStepComplete?.call('El $num1 se comió al $num2, quedó $result');
  }

  Future<void> _animateMultiplication() async {
    // ⭐ VERIFICAR mounted
    if (!mounted || _isDisposed) return;

    widget.onStepComplete?.call('Multiplicación en proceso...');
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _animateEquation() async {
    // ⭐ VERIFICAR mounted
    if (!mounted || _isDisposed) return;

    widget.onStepComplete?.call('Resolviendo ecuación...');
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFF6B5CE7).withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF6B5CE7).withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5CE7).withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: GridPainter(),
          ),

          ...elements.map(
            (element) => AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              left: element.position.dx,
              top: element.position.dy,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: element.opacity,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 600),
                  scale: element.scale,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [element.color, element.color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: element.color.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      element.value,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MathElement {
  String id;
  String value;
  Offset position;
  double scale;
  double opacity;
  Color color;

  MathElement({
    required this.id,
    required this.value,
    required this.position,
    this.scale = 1.0,
    this.opacity = 1.0,
    this.color = const Color(0xFF6B5CE7),
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(20, size.height / 2),
      Offset(size.width - 20, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================== CLASES AUXILIARES ====================

class StepAnimationControllers {
  late AnimationController slideController;
  late AnimationController rotationController;
  late AnimationController pulseController;

  late Animation<double> slideAnimation;
  late Animation<double> rotationAnimation;
  late Animation<double> pulseAnimation;

  StepAnimationControllers({required TickerProvider vsync}) {
    slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );
    slideAnimation = CurvedAnimation(
      parent: slideController,
      curve: Curves.easeOutCubic,
    );

    rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
    rotationAnimation = CurvedAnimation(
      parent: rotationController,
      curve: Curves.easeOutBack,
    );

    pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );
    pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.elasticOut),
    );
  }

  void startAnimations() {
    slideController.forward();
    rotationController.forward();
    pulseController.forward();
  }

  void dispose() {
    slideController.dispose();
    rotationController.dispose();
    pulseController.dispose();
  }
}

class BannyChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  BannyChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

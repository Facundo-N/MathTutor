// lib/screens/unified_board_chat_screen.dart
// Pantalla unificada: Ahora usa directamente EquationLabWidget para consistencia total

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/banny_chat_service.dart';
import '../providers/board_provider.dart';
import '../widgets/ai_coach_popup.dart';
import '../widgets/equation_lab.dart';
import '../providers/theme_provider.dart';

class UnifiedBoardChatScreen extends StatefulWidget {
  final String equation;
  final String userId;
  final String template;

  const UnifiedBoardChatScreen({
    super.key,
    required this.equation,
    this.userId = 'user_123',
    this.template = 'guiado',
  });

  @override
  State<UnifiedBoardChatScreen> createState() => _UnifiedBoardChatScreenState();
}

class _UnifiedBoardChatScreenState extends State<UnifiedBoardChatScreen> {
  late BannyChatService _chatService;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _chatService = BannyChatService(userId: widget.userId);
    _chatService
        .connect()
        .then((_) {
          if (mounted) {
            setState(() => _isOnline = true);
          }
        })
        .catchError((e) {
          debugPrint("Error connecting chat service: $e");
        });
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }

  void _openAICoach() {
    final boardProvider = context.read<BoardProvider>();
    final steps = boardProvider.getStepsHistory();

    AICoachPopup.show(
      context,
      messages:
          [], // Los mensajes se manejarán dentro del popup o se sincronizarán si es necesario
      onSendMessage: (text) => _chatService.sendMessage(text),
      isTyping: false,
      isOnline: _isOnline,
      solvedSteps: steps,
      exerciseHistory: [widget.equation],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          EquationLabWidget(
            equation: widget.equation,
            onExit: () => Navigator.of(context).pop(),
            chatService: _chatService,
            isDarkMode: isDarkMode,
            onToggleTheme: () => themeProvider.toggleTheme(),
            initialPayloadStr: widget.template != 'guiado'
                ? '{"exercise_type": "${widget.template}", "equation": "${widget.equation}", "story_context": "Practica con la plantilla ${widget.template}", "pieces": [], "correct_answer": "0"}'
                : null,
            actions: [
              _appBarBtn(
                icon: Icons.psychology,
                onPressed: _openAICoach,
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appBarBtn({
    required IconData icon,
    required VoidCallback onPressed,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: highlight
              ? const Color(0xFF6B5CE7).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: highlight
                ? const Color(0xFF6B5CE7).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

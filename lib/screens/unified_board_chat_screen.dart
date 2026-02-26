// lib/screens/unified_board_chat_screen.dart
// Pantalla unificada: Pizarra interactiva (centro) + Chat (abajo) + Popup IA (lateral)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/banny_chat_service.dart';
import '../providers/board_provider.dart';
import '../widgets/interactive_board_widget.dart';
import '../widgets/chat_widget.dart';
import '../widgets/ai_coach_popup.dart';

/// Pantalla principal unificada: pizarra interactiva + chat integrado.
///
/// Layout vertical:
///  - AppBar con botón de IA Coach
///  - Pizarra interactiva (~70% de altura)
///  - Chat compacto (~30% de altura)
class UnifiedBoardChatScreen extends StatefulWidget {
  final String equation;
  final String userId;

  const UnifiedBoardChatScreen({
    super.key,
    required this.equation,
    this.userId = 'user_123',
  });

  @override
  State<UnifiedBoardChatScreen> createState() => _UnifiedBoardChatScreenState();
}

class _UnifiedBoardChatScreenState extends State<UnifiedBoardChatScreen> {
  late BannyChatService _chatService;
  final List<ChatMessage> _messages = [];
  final List<String> _solvedSteps = [];
  final List<String> _exerciseHistory = [];

  bool _isOnline = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    _addWelcomeMessage();
    _exerciseHistory.add(widget.equation);
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: '1',
        text:
            '¡Hola! Soy Banny 🤖\nEstás resolviendo: ${widget.equation}\n¿Necesitas ayuda? Escribime acá abajo.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _initChat() async {
    try {
      _chatService = BannyChatService(userId: widget.userId);
      await _chatService.connect();

      if (mounted) setState(() => _isOnline = true);

      _chatService.messageStream.listen(
        (message) {
          if (mounted) _handleResponse(message);
        },
        onError: (error) {
          if (mounted) setState(() => _isOnline = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
    }
  }

  void _handleResponse(Map<String, dynamic> message) {
    final content = message['content'] ?? '';
    final sender = message['sender'] ?? 'banny';
    final isError = message['error'] ?? false;

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          text: content,
          isUser: sender == 'user',
          timestamp: DateTime.now(),
          isError: isError,
        ),
      );
    });
  }

  void _sendMessage(String text) {
    if (text.isEmpty || !_isOnline) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().toString(),
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });

    _chatService.sendMessage(text);
  }

  void _openAICoach() {
    // Obtener pasos del BoardProvider
    final boardProvider = context.read<BoardProvider>();
    final steps = boardProvider.getStepsHistory();

    AICoachPopup.show(
      context,
      messages: _messages,
      onSendMessage: _sendMessage,
      isTyping: _isTyping,
      isOnline: _isOnline,
      solvedSteps: steps,
      exerciseHistory: _exerciseHistory,
    );
  }

  @override
  void dispose() {
    _chatService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ─── APPBAR ───
            _buildAppBar(),

            // ─── PIZARRA (70%) ───
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: InteractiveBoardWidget(
                  equation: widget.equation,
                  onElementMoved: (info) {
                    setState(() {
                      _solvedSteps.add(info);
                    });
                  },
                ),
              ),
            ),

            // ─── CHAT COMPACTO (30%) ───
            Expanded(
              flex: 3,
              child: ChatWidget(
                messages: _messages,
                onSendMessage: _sendMessage,
                isTyping: _isTyping,
                isOnline: _isOnline,
                isCompact: true,
                hintText: 'Pregúntale a Banny sobre el ejercicio...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5CE7).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('📐', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),

          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pizarra Interactiva',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.greenAccent : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isOnline ? 'Banny conectado' : 'Sin conexión',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón IA Coach (abre popup lateral)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.psychology, color: Colors.white, size: 22),
              tooltip: 'AI Coach',
              onPressed: _openAICoach,
            ),
          ),
        ],
      ),
    );
  }
}

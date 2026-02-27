// lib/widgets/chat_widget.dart
// Widget reutilizable de chat extraído de BannyChatScreen

import 'dart:ui';
import 'package:flutter/material.dart';

/// Modelo de mensaje reutilizable
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

/// Widget de chat reutilizable.
/// [isCompact] = true  → versión reducida para zona inferior de la pantalla unificada
/// [isCompact] = false → versión completa para el popup de IA
class ChatWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isOnline;
  final bool isCompact;
  final ValueChanged<String> onSendMessage;
  final String hintText;
  final VoidCallback? onStopSpeaking;
  final bool isSpeaking;

  const ChatWidget({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.isTyping = false,
    this.isOnline = true,
    this.isCompact = false,
    this.hintText = 'Escribe un ejercicio o pregunta...',
    this.onStopSpeaking,
    this.isSpeaking = false,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatWidget old) {
    super.didUpdateWidget(old);
    if (widget.messages.length != old.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.isOnline) return;
    widget.onSendMessage(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactChat(context);
    }
    return _buildFullChat(context);
  }

  // ─── VERSIÓN COMPACTA (zona inferior de pantalla unificada) ───
  Widget _buildCompactChat(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Mini lista de mensajes (últimos 3)
              if (widget.messages.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    shrinkWrap: true,
                    itemCount:
                        _recentMessages.length + (widget.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (widget.isTyping && index == _recentMessages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildCompactBubble(_recentMessages[index]);
                    },
                  ),
                ),

              // Input
              _buildInput(context),
            ],
          ),
        ),
      ),
    );
  }

  List<ChatMessage> get _recentMessages {
    if (widget.messages.length <= 3) return widget.messages;
    return widget.messages.sublist(widget.messages.length - 3);
  }

  Widget _buildCompactBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            color: message.isUser
                ? Colors.white
                : (message.isError ? Colors.red.shade900 : Colors.black87),
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ─── VERSIÓN COMPLETA (popup de IA o pantalla completa) ───
  Widget _buildFullChat(BuildContext context) {
    return Column(
      children: [
        // Lista de mensajes
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: widget.messages.length + (widget.isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (widget.isTyping && index == widget.messages.length) {
                return _buildTypingIndicator();
              }
              return _buildFullBubble(widget.messages[index]);
            },
          ),
        ),

        // Input
        _buildInput(context),
      ],
    );
  }

  Widget _buildFullBubble(ChatMessage message) {
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
                  ? const Color(0xFF6B5CE7).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
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

  // ─── WIDGETS COMPARTIDOS ───
  Widget _buildInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 8 : 16,
        vertical: widget.isCompact ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: widget.isCompact
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: widget.isCompact ? 8 : 12,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey.shade400,
                    size: widget.isCompact ? 18 : 22,
                  ),
                ),
                enabled: widget.isOnline,
                onSubmitted: (_) => _handleSend(),
                style: TextStyle(fontSize: widget.isCompact ? 13 : 15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: widget.isCompact ? 36 : 44,
            height: widget.isCompact ? 36 : 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B5CE7).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: widget.isCompact ? 16 : 20,
              ),
              onPressed: widget.isOnline ? _handleSend : null,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1.0),
              duration: Duration(milliseconds: 600 + index * 200),
              builder: (context, value, _) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
                    width: 7,
                    height: 7,
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
}

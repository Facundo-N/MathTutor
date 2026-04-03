// lib/widgets/chat_widget.dart
// Widget reutilizable de chat extraído de BannyChatScreen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'math_keyboard.dart';

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

  void _showMathKeyboard(BuildContext context) {
    // Cerrar teclado del sistema antes de abrir el modal
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return MathKeyboard(
          controller: _controller,
          onKeyPressed: (char) {
            final text = _controller.text;
            final selection = _controller.selection;

            if (selection.start >= 0 && selection.end >= 0) {
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                char,
              );
              _controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset: selection.start + char.length,
                ),
              );
            } else {
              _controller.text = text + char;
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
            }
          },
          onBackspace: () {
            final text = _controller.text;
            final selection = _controller.selection;

            if (selection.start >= 0 &&
                selection.end >= 0 &&
                selection.start != selection.end) {
              final newText = text.replaceRange(
                selection.start,
                selection.end,
                '',
              );
              _controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: selection.start),
              );
            } else if (text.isNotEmpty && selection.start > 0) {
              final newText = text.replaceRange(
                selection.start - 1,
                selection.start,
                '',
              );
              _controller.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: selection.start - 1),
              );
            } else if (text.isNotEmpty && selection.start == -1) {
              _controller.text = text.substring(0, text.length - 1);
              _controller.selection = TextSelection.collapsed(
                offset: _controller.text.length,
              );
            }
          },
          onSubmit: () {
            Navigator.of(context).pop();
            _handleSend();
          },
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
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
              : (message.isError
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(14),
          border: message.isUser
              ? null
              : Border.all(
                  color: message.isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 13,
            color: message.isUser
                ? Colors.white
                : (message.isError ? Colors.red.shade300 : Colors.white70),
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
              : (message.isError
                    ? Colors.red.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1)),
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
          border: message.isUser
              ? null
              : Border.all(
                  color: message.isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
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
                : (message.isError ? Colors.red.shade300 : Colors.white70),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ─── WIDGETS COMPARTIDOS ───
  Widget _buildInput(BuildContext context) {
    if (widget.isCompact) {
      // ESTILO: Igual a Equation Labs
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.7),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.blueAccent[100],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: widget.isOnline,
                        onSubmitted: (_) => _handleSend(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.calculate_rounded,
                              color: Colors.blueAccent[100],
                            ),
                            onPressed: () => _showMathKeyboard(context),
                            tooltip: 'Teclado Matemático',
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: widget.isOnline ? _handleSend : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.1,
                        ),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
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

    // ESTILO: Completo (Popup)
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
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
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.calculate_rounded,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () => _showMathKeyboard(context),
                    tooltip: 'Teclado Matemático',
                  ),
                ),
                enabled: widget.isOnline,
                onSubmitted: (_) => _handleSend(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
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
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
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
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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

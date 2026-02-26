// lib/widgets/ai_coach_popup.dart
// Popup lateral de IA Coach con tabs: Chat, Replay, Pasos

import 'package:flutter/material.dart';
import 'chat_widget.dart';

/// Popup lateral (desde la derecha) del IA Coach.
/// Contiene 3 tabs: Chat, Replay, Pasos.
class AICoachPopup extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final bool isOnline;
  final ValueChanged<String> onSendMessage;
  final List<String> solvedSteps;
  final List<String> exerciseHistory;

  const AICoachPopup({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.isTyping = false,
    this.isOnline = true,
    this.solvedSteps = const [],
    this.exerciseHistory = const [],
  });

  /// Abre el popup como overlay lateral desde la derecha.
  static void show(
    BuildContext context, {
    required List<ChatMessage> messages,
    required ValueChanged<String> onSendMessage,
    bool isTyping = false,
    bool isOnline = true,
    List<String> solvedSteps = const [],
    List<String> exerciseHistory = const [],
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AI Coach',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.9,
              margin: const EdgeInsets.only(right: 8, top: 40, bottom: 40),
              child: AICoachPopup(
                messages: messages,
                onSendMessage: onSendMessage,
                isTyping: isTyping,
                isOnline: isOnline,
                solvedSteps: solvedSteps,
                exerciseHistory: exerciseHistory,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  @override
  State<AICoachPopup> createState() => _AICoachPopupState();
}

class _AICoachPopupState extends State<AICoachPopup>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5CE7).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tabs
            _buildTabBar(),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatTab(),
                  _buildReplayTab(),
                  _buildStepsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B5CE7), Color(0xFF8B7CE8)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Banny - AI Coach',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tu tutor inteligente',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Indicador de conexión
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isOnline
                  ? Colors.greenAccent.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isOnline ? Colors.greenAccent : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isOnline ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF6B5CE7).withValues(alpha: 0.05),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6B5CE7),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6B5CE7),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.chat, size: 18), text: 'Chat'),
          Tab(icon: Icon(Icons.replay, size: 18), text: 'Replay'),
          Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Pasos'),
        ],
      ),
    );
  }

  // ─── TAB 1: Chat con Banny ───
  Widget _buildChatTab() {
    return ChatWidget(
      messages: widget.messages,
      onSendMessage: widget.onSendMessage,
      isTyping: widget.isTyping,
      isOnline: widget.isOnline,
      isCompact: false,
      hintText: 'Pregúntale a Banny...',
    );
  }

  // ─── TAB 2: Replay de ejercicios anteriores ───
  Widget _buildReplayTab() {
    if (widget.exerciseHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sin ejercicios previos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los ejercicios que resuelvas\naparecerán aquí para repetir',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.exerciseHistory.length,
      itemBuilder: (context, index) {
        final exercise = widget.exerciseHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF6B5CE7).withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B5CE7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Color(0xFF6B5CE7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  exercise,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.replay, color: Colors.green, size: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 3: Pasos de la sesión actual ───
  Widget _buildStepsTab() {
    if (widget.solvedSteps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sin pasos aún',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza a resolver y tus\nacciones aparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.solvedSteps.length,
      itemBuilder: (context, index) {
        final step = widget.solvedSteps[index];
        final isLast = index == widget.solvedSteps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isLast ? const Color(0xFF6B5CE7) : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isLast
                        ? const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 14,
                          )
                        : const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 40, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLast
                      ? const Color(0xFF6B5CE7).withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: isLast
                      ? Border.all(
                          color: const Color(0xFF6B5CE7).withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLast
                            ? const Color(0xFF6B5CE7)
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../services/banny_chat_service.dart';
import '../widgets/equation_lab.dart';

/// Pantalla que actúa como contenedor principal para EquationLab,
/// inyectando el servicio de chat para mantener la funcionalidad de Banny.
class BannyChatScreen extends StatefulWidget {
  final String userId;
  final bool isDarkMode;

  const BannyChatScreen({
    super.key,
    this.userId = 'user_123',
    this.isDarkMode = true,
  });

  @override
  State<BannyChatScreen> createState() => _BannyChatScreenState();
}

class _BannyChatScreenState extends State<BannyChatScreen> {
  BannyChatService? _bannyChatService;
  bool isOnline = false;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _initializeBannyChat();
  }

  Future<void> _initializeBannyChat() async {
    final service = BannyChatService(userId: widget.userId);
    if (mounted) {
      setState(() {
        _bannyChatService = service;
      });
    }

    try {
      debugPrint('🔌 Conectando a Banny WebSocket...');
      await service.connect();

      if (mounted) {
        setState(() {
          isOnline = service.isConnected;
        });
        debugPrint('✅ Banny WebSocket conectado');
      }
    } catch (e) {
      debugPrint('❌ Error conectando Banny: $e');
      if (mounted) setState(() => isOnline = false);
    }
  }

  @override
  void dispose() {
    _bannyChatService?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannyChatService == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    return Scaffold(
      body: EquationLabWidget(
        chatService: _bannyChatService,
        isDarkMode: _isDarkMode,
        onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
        onExit: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

// lib/models/chat_message_model.dart
class BannyChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? mathExpression; // Para mostrar problemas matemáticos
  final bool isProblemCard; // Si es una tarjeta de problema

  const BannyChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.mathExpression,
    this.isProblemCard = false,
  });
}

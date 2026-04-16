import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

import 'math_api_service.dart';

/// Servicio para comunicarse con Banny (tutor IA) via WebSocket
/// LA API KEY ESTÁ EN EL BACKEND (segura)
class BannyChatService {
  static String get wsUrl => MathApiService.wsBaseUrl;

  WebSocketChannel? _channel;
  late String _userId;
  bool _isConnected = false;

  // Stream controller para manejar desconexiones sin crash
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  BannyChatService({required String userId}) {
    _userId = userId;
  }

  bool get isConnected => _isConnected;

  /// Conecta al WebSocket del backend
  Future<void> connect() async {
    try {
      final uri = '$wsUrl/ws/chat/$_userId';
      debugPrint('[Banny] Conectando a: $uri');
      _channel = WebSocketChannel.connect(Uri.parse(uri));

      // Esperar a que el canal esté listo (con timeout)
      await _channel!.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Timeout conectando al WebSocket');
        },
      );

      _isConnected = true;
      debugPrint('[Banny] ✅ Conectado al WebSocket: $_userId');

      // Escuchar mensajes y reenviar al stream controller
      _channel!.stream.listen(
        (event) {
          try {
            final data = json.decode(event) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (e) {
            debugPrint('[Banny] ❌ Error parseando: $e');
            _messageController.add({
              'type': 'error',
              'content': 'Error parseando respuesta',
            });
          }
        },
        onError: (error) {
          debugPrint('[Banny] ❌ WebSocket stream error: $error');
          _isConnected = false;
          _messageController.addError(error);
        },
        onDone: () {
          debugPrint('[Banny] ⚠️ WebSocket cerrado');
          _isConnected = false;
        },
      );
    } catch (e) {
      debugPrint('[Banny] ❌ Error conectando: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Envía un mensaje a Banny con contexto opcional del tablero
  void sendMessage(String message, {Map<String, dynamic>? context}) {
    if (!_isConnected || _channel == null) {
      debugPrint('[Banny] ⚠️ No conectado, no se puede enviar mensaje');
      return;
    }

    try {
      _channel!.sink.add(
        json.encode({
          'type': 'message',
          'content': message,
          if (context != null) 'context': context,
          'user_id': _userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('[Banny] ✅ Mensaje enviado: $message');
    } catch (e) {
      debugPrint('[Banny] ❌ Error enviando mensaje: $e');
    }
  }

  /// Stream de respuestas de Banny (seguro, nunca lanza LateInitializationError)
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Desconecta del WebSocket
  void disconnect() {
    try {
      _isConnected = false;
      _channel?.sink.close();
      _messageController.close();
      debugPrint('[Banny] ✅ Desconectado del WebSocket');
    } catch (e) {
      debugPrint('[Banny] ❌ Error desconectando: $e');
    }
  }
}

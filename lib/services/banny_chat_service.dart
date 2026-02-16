import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:io';

/// Servicio para comunicarse con Banny (tutor IA) via WebSocket
/// LA API KEY ESTÁ EN EL BACKEND (segura)
class BannyChatService {
  // En Android/emulador, usar 10.0.2.2 en lugar de 127.0.0.1
  // En dispositivo físico, cambiar a la IP real del servidor
  static String get wsUrl {
    // Para dispositivos Android físicos por USB con ADB reverse
    // usa 127.0.0.1 (requiere: adb reverse tcp:8000 tcp:8000)
    // Para emulador Android, cambia a 10.0.2.2
    if (Platform.isAndroid) {
      return 'ws://127.0.0.1:8000'; // Para dispositivo físico USB
    } else {
      return 'ws://127.0.0.1:8000';
    }
  }

  late WebSocketChannel _channel;
  late String _userId;

  BannyChatService({required String userId}) {
    _userId = userId;
  }

  /// Conecta al WebSocket del backend
  Future<void> connect() async {
    try {
      final uri = '$wsUrl/ws/chat/$_userId';
      print('[Banny] Conectando a: $uri');
      _channel = WebSocketChannel.connect(Uri.parse(uri));
      print('[Banny] ✅ Conectado al WebSocket: $_userId');
    } catch (e) {
      print('[Banny] ❌ Error conectando: $e');
      rethrow;
    }
  }

  /// Envía un mensaje a Banny
  void sendMessage(String message) {
    try {
      _channel.sink.add(
        json.encode({
          'type': 'message',
          'content': message,
          'user_id': _userId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      print('[Banny] ✅ Mensaje enviado: $message');
    } catch (e) {
      print('[Banny] ❌ Error enviando mensaje: $e');
    }
  }

  /// Stream de respuestas de Banny
  Stream<Map<String, dynamic>> get messageStream {
    return _channel.stream.map((event) {
      try {
        return json.decode(event) as Map<String, dynamic>;
      } catch (e) {
        print('[Banny] ❌ Error parseando: $e');
        return {'type': 'error', 'content': 'Error parseando respuesta'};
      }
    });
  }

  /// Desconecta del WebSocket
  void disconnect() {
    try {
      _channel.sink.close();
      print('[Banny] ✅ Desconectado del WebSocket');
    } catch (e) {
      print('[Banny] ❌ Error desconectando: $e');
    }
  }
}

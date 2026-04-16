import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'math_api_service.dart';
import '../models/tutor_action.dart';

class HyperpersonalizedTutorService {
  // ✅ Configurado para conectarse desde emulador/dispositivo
  static String get wsUrl => '${MathApiService.wsBaseUrl}/ws/tutor';
  static const Duration connectionTimeout = Duration(seconds: 10);

  WebSocketChannel? _channel;
  final String userId;
  StreamSubscription? _streamSubscription;

  // Callback cuando llega una TutorAction
  final void Function(TutorAction action) onTutorAction;

  // Stream controller para estados
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool get isConnected => _isConnected;

  HyperpersonalizedTutorService({
    required this.userId,
    required this.onTutorAction,
  });

  /// Conectar al WebSocket con timeout y retry
  Future<void> connect() async {
    // Evitar múltiples intentos simultáneos
    if (_isConnecting || _isConnected) {
      debugPrint('⚠️ Ya está conectando o conectado');
      return;
    }

    _isConnecting = true;

    try {
      debugPrint('🔌 Conectando WebSocket: $wsUrl/$userId');

      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/$userId'));

      // Esperar a que se establezca la conexión con timeout
      await _channel!.ready.timeout(
        connectionTimeout,
        onTimeout: () {
          throw Exception(
            'WebSocket connection timeout después de ${connectionTimeout.inSeconds}s',
          );
        },
      );

      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);

      debugPrint('✅ WebSocket conectado correctamente');

      // Escuchar mensajes del backend
      _streamSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error, stackTrace) {
          debugPrint('❌ WebSocket stream error: $error');
          debugPrint('Stack: $stackTrace');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('⚠️ WebSocket cerrado por el servidor');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Timeout conectando WebSocket: $e');
      _handleDisconnect();
    } catch (e) {
      debugPrint('❌ Error conectando WebSocket: $e');
      _handleDisconnect();
      // No relanzar, simplemente logged
    } finally {
      _isConnecting = false;
    }
  }

  /// Manejar desconexión
  void _handleDisconnect() {
    _isConnected = false;
    _connectionController.add(false);
    try {
      _streamSubscription?.cancel();
      _channel?.sink.close();
    } catch (e) {
      debugPrint('⚠️ Error cerrando canal: $e');
    }
  }

  /// Manejar mensajes del backend
  void _handleMessage(dynamic message) {
    try {
      debugPrint('📩 Mensaje recibido: $message');

      final data = json.decode(message);
      final action = TutorAction.fromJson(data);

      debugPrint('🎯 TutorAction: ${action.type} - "${action.speech}"');

      // Ejecutar callback de forma segura
      try {
        onTutorAction(action);
      } catch (e) {
        debugPrint('❌ Error en callback onTutorAction: $e');
      }
    } catch (e) {
      debugPrint('❌ Error procesando mensaje WebSocket: $e');
    }
  }

  /// Enviar señal al backend (opcional)
  void sendSignal(Map<String, dynamic> signal) {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(json.encode(signal));
        debugPrint('📤 Señal enviada: ${signal['type']}');
      } else {
        debugPrint('⚠️ WebSocket no conectado, no se puede enviar señal');
      }
    } catch (e) {
      debugPrint('❌ Error enviando señal: $e');
    }
  }

  /// Desconectar
  void disconnect() {
    _handleDisconnect();
    debugPrint('👋 WebSocket desconectado manualmente');
  }

  void dispose() {
    disconnect();
    _connectionController.close();
  }
}

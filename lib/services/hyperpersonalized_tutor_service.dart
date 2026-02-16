// lib/services/hyperpersonalized_tutor_service.dart

import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import '../models/tutor_action.dart';

class HyperpersonalizedTutorService {
  // ✅ Configurado para conectarse desde emulador/dispositivo
  static const String wsUrl = 'ws://192.168.0.11:8000/ws/tutor';
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
      print('⚠️ Ya está conectando o conectado');
      return;
    }
    
    _isConnecting = true;
    
    try {
      print('🔌 Conectando WebSocket: $wsUrl/$userId');
      
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/$userId'),
      );
      
      // Esperar a que se establezca la conexión con timeout
      await _channel!.ready.timeout(
        connectionTimeout,
        onTimeout: () {
          throw Exception('WebSocket connection timeout después de ${connectionTimeout.inSeconds}s');
        },
      );
      
      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);
      
      print('✅ WebSocket conectado correctamente');
      
      // Escuchar mensajes del backend
      _streamSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error, stackTrace) {
          print('❌ WebSocket stream error: $error');
          print('Stack: $stackTrace');
          _handleDisconnect();
        },
        onDone: () {
          print('⚠️ WebSocket cerrado por el servidor');
          _handleDisconnect();
        },
        cancelOnError: false,
      );
      
    } on TimeoutException catch (e) {
      print('⏱️ Timeout conectando WebSocket: $e');
      _handleDisconnect();
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
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
      print('⚠️ Error cerrando canal: $e');
    }
  }
  
  /// Manejar mensajes del backend
  void _handleMessage(dynamic message) {
    try {
      print('📩 Mensaje recibido: $message');
      
      final data = json.decode(message);
      final action = TutorAction.fromJson(data);
      
      print('🎯 TutorAction: ${action.type} - "${action.speech}"');
      
      // Ejecutar callback de forma segura
      try {
        onTutorAction(action);
      } catch (e) {
        print('❌ Error en callback onTutorAction: $e');
      }
      
    } catch (e) {
      print('❌ Error procesando mensaje WebSocket: $e');
    }
  }
  
  /// Enviar señal al backend (opcional)
  void sendSignal(Map<String, dynamic> signal) {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(json.encode(signal));
        print('📤 Señal enviada: ${signal['type']}');
      } else {
        print('⚠️ WebSocket no conectado, no se puede enviar señal');
      }
    } catch (e) {
      print('❌ Error enviando señal: $e');
    }
  }
  
  /// Desconectar
  void disconnect() {
    _handleDisconnect();
    print('👋 WebSocket desconectado manualmente');
  }
  
  void dispose() {
    disconnect();
    _connectionController.close();
  }
}

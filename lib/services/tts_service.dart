// lib/services/tts_service.dart
// Servicio de Text-to-Speech — consume el endpoint Kokoro del backend.
// Reproduce audio WAV recibido en base64 usando just_audio.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  // URL del backend (ajustar si cambia el host)
  static const String _baseUrl = 'http://localhost:8000';

  /// Sintetiza [text] y lo reproduce inmediatamente.
  /// Si hay audio en reproducción, lo interrumpe.
  Future<void> speak(String text, {double speed = 1.0}) async {
    if (text.trim().isEmpty) return;

    try {
      // Detener cualquier reproducción en curso
      if (_isPlaying) {
        await _player.stop();
      }

      debugPrint(
        '🎤 TTS: sintetizando "${text.substring(0, text.length.clamp(0, 40))}..."',
      );

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/tts/synthesize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'voice': 'ef_dora',
              'speed': speed,
              'return_base64': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          '⚠️ TTS backend error ${response.statusCode}: ${response.body}',
        );
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String audioBase64 = data['audio_base64'] as String;

      // Guardar WAV en archivo temporal y reproducir
      await _playBase64Wav(audioBase64);
    } on SocketException {
      debugPrint('⚠️ TTS: backend no disponible (SocketException)');
    } catch (e) {
      debugPrint('❌ TTS error: $e');
    }
  }

  /// Detiene la reproducción actual.
  Future<void> stop() async {
    if (_isPlaying) {
      await _player.stop();
      _isPlaying = false;
    }
  }

  /// ¿Está el TTS hablando ahora mismo?
  bool get isPlaying => _isPlaying;

  /// Verifica si el backend TTS está disponible.
  Future<bool> isAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tts/status'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['available'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Helpers privados ───────────────────────────────────────────────────────

  Future<void> _playBase64Wav(String base64Audio) async {
    try {
      final Uint8List bytes = base64Decode(base64Audio);

      // Escribir en archivo temporal
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/tts_output.wav');
      await tempFile.writeAsBytes(bytes);

      _isPlaying = true;
      await _player.setFilePath(tempFile.path);
      await _player.play();

      // Escuchar fin de reproducción
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });

      debugPrint('✅ TTS: reproduciendo ${bytes.length ~/ 1024} KB de audio');
    } catch (e) {
      _isPlaying = false;
      debugPrint('❌ TTS playback error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

// lib/services/tts_service.dart
// Servicio de Text-to-Speech — consume el endpoint Kokoro del backend.
// Reproduce audio WAV recibido en base64 usando just_audio.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'math_api_service.dart';

class TTSService extends ChangeNotifier {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _fallbackTts = FlutterTts();
  bool _isPlaying = false;

  String _currentVoice = 'af_jessica';
  List<Map<String, dynamic>> _availableVoices = [];
  bool _isLoadingVoices = false;

  String get currentVoice => _currentVoice;
  List<Map<String, dynamic>> get availableVoices => _availableVoices;
  bool get isLoadingVoices => _isLoadingVoices;

  // URL del backend (sincronizado con MathApiService)
  static const String _baseUrl = MathApiService.baseUrl;

  /// Carga la lista de voces desde el backend.
  Future<void> loadVoices() async {
    if (_availableVoices.isNotEmpty) return;

    _isLoadingVoices = true;
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tts/voices'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _availableVoices = List<Map<String, dynamic>>.from(data['voices'] ?? []);
        // Forzamos af_jessica independientemente de lo que diga el backend
        _currentVoice = 'af_jessica';
      }
    } catch (e) {
      debugPrint('⚠️ Error cargando voces: $e');
      // Fallback básico si falla el backend
      _availableVoices = [
        {'id': 'ef_dora', 'lang': 'es', 'gender': 'F', 'description': 'Dora (Español Nativa)'},
        {'id': 'em_alex', 'lang': 'es', 'gender': 'M', 'description': 'Alex (Español Nativa)'},
        {'id': 'af_nicole','lang': 'es', 'gender': 'F', 'description': 'Nicole (Suave)'},
        {'id': 'af_sky',   'lang': 'es', 'gender': 'F', 'description': 'Sky (Natural)'},
        {'id': 'am_adam',  'lang': 'es', 'gender': 'M', 'description': 'Adam (Suave)'},
      ];
    } finally {
      _isLoadingVoices = false;
      notifyListeners();
    }
  }

  /// Cambia la voz seleccionada.
  void setVoice(String voiceId) {
    if (_currentVoice != voiceId) {
      _currentVoice = voiceId;
      notifyListeners();
    }
  }

  /// Sintetiza [text] y lo reproduce inmediatamente.
  /// Si hay audio en reproducción, lo interrumpe.
  /// Se puede especificar una [voice] para pruebas puntuales.
  Future<void> speak(String text, {double speed = 1.0, String? voice}) async {
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
              'voice': voice ?? _currentVoice,
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

      // Guardar WAV en archivo temporal y reproducir (fire-and-forget)
      _playBase64Wav(audioBase64);
    } catch (e) {
      debugPrint('❌ TTS backend error: $e');
      debugPrint('🔄 Intentando fallback con FlutterTts (local)...');
      await _speakFallback(text);
    }
  }

  /// Igual que [speak] pero espera a que el audio termine antes de retornar.
  /// Úsalo cuando necesitas sincronización exacta (ej: avanzar escena de tutorial).
  Future<void> speakAndWait(
    String text, {
    double speed = 1.0,
    String? voice,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      if (_isPlaying) {
        await _player.stop();
      }

      debugPrint(
        '🎤 TTS (await): sintetizando "${text.substring(0, text.length.clamp(0, 40))}..."',
      );

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/tts/synthesize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'voice': voice ?? _currentVoice,
              'speed': speed,
              'return_base64': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('⚠️ TTS backend error ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String audioBase64 = data['audio_base64'] as String;

      // Reproducir y esperar a que termine
      await _playBase64WavAndWait(audioBase64);
    } catch (e) {
      debugPrint('❌ TTS speakAndWait error: $e — usando fallback');
      await _speakFallback(text);
    }
  }

  /// Fallback usando el motor de TTS nativo del dispositivo.
  Future<void> _speakFallback(String text) async {
    try {
      await _fallbackTts.setLanguage('es-ES');
      await _fallbackTts.setPitch(1.0);
      await _fallbackTts.speak(text);
      debugPrint('✅ TTS Fallback exitoso (device TTS)');
    } catch (e) {
      debugPrint('❌ TTS Fallback falló: $e');
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

  /// Verifica si el backend TTS está disponible. (Alias para compatibilidad)
  Future<bool> isBackendAvailable() => isAvailable();

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
      if (kIsWeb) {
        final dataUri = 'data:audio/wav;base64,$base64Audio';
        _isPlaying = true;
        await _player.setAudioSource(AudioSource.uri(Uri.parse(dataUri)));
        await _player.play();
      } else {
        final Uint8List bytes = base64Decode(base64Audio);
        final Directory tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/tts_output.wav');
        await tempFile.writeAsBytes(bytes);
        _isPlaying = true;
        await _player.setFilePath(tempFile.path);
        await _player.play();
      }

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
        }
      });

      debugPrint('✅ TTS: reproduciendo audio (${base64Audio.length ~/ 1024} KB)');
    } catch (e) {
      _isPlaying = false;
      debugPrint('❌ TTS playback error: $e');
    }
  }

  /// Igual que [_playBase64Wav] pero espera a que el audio termine completamente.
  Future<void> _playBase64WavAndWait(String base64Audio) async {
    try {
      if (kIsWeb) {
        final dataUri = 'data:audio/wav;base64,$base64Audio';
        _isPlaying = true;
        await _player.setAudioSource(AudioSource.uri(Uri.parse(dataUri)));
        await _player.play();
      } else {
        final Uint8List bytes = base64Decode(base64Audio);
        final Directory tempDir = await getTemporaryDirectory();
        final File tempFile = File('${tempDir.path}/tts_output.wav');
        await tempFile.writeAsBytes(bytes);
        _isPlaying = true;
        await _player.setFilePath(tempFile.path);
        await _player.play();
      }

      debugPrint('✅ TTS (await): reproduciendo audio (${base64Audio.length ~/ 1024} KB)');

      // Esperar explícitamente hasta que el processingState sea `completed`
      await _player.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
      _isPlaying = false;
    } catch (e) {
      _isPlaying = false;
      debugPrint('❌ TTS (await) playback error: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

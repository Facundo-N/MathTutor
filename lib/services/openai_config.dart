// lib/services/openai_config.dart
// ❌ NO USAR API KEY EN FRONTEND - INSEGURO
// Las llamadas a OpenAI se hacen DESDE EL BACKEND
// El frontend solo se comunica con el backend via WebSocket

import 'math_api_service.dart';

// Detectar URL unificada del backend
String get baseUrl => MathApiService.baseUrl;

// Detectar URL unificada del WebSocket
String get wsUrlBase => MathApiService.wsBaseUrl;

// Compatibilidad legacy
String get backendUrl => MathApiService.baseUrl;
String get wsUrl => MathApiService.wsBaseUrl;

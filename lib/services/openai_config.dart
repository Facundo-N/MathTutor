// ❌ NO USAR API KEY EN FRONTEND - INSEGURO
// Las llamadas a OpenAI se hacen DESDE EL BACKEND
// El frontend solo se comunica con el backend via WebSocket

import 'dart:io';

// Detectar si estamos en Android/emulador
String get baseUrl {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  } else {
    return 'http://127.0.0.1:8000';
  }
}

String get wsUrlBase {
  if (Platform.isAndroid) {
    return 'ws://10.0.2.2:8000';
  } else {
    return 'ws://127.0.0.1:8000';
  }
}

const String backendUrl = 'http://127.0.0.1:8000'; // Para desarrollo local
const String wsUrl = 'ws://127.0.0.1:8000'; // Para desarrollo local

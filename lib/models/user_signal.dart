// lib/models/user_signal.dart

class UserSignal {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserSignal({
    required this.type,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class SessionSignals {
  final String sessionId;
  final String userId;
  final List<UserSignal> signals;
  final DateTime sessionStart;

  SessionSignals({
    required this.sessionId,
    required this.userId,
    required this.signals,
    required this.sessionStart,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'session_start': sessionStart.toIso8601String(),
      'signals': signals.map((s) => s.toJson()).toList(),
    };
  }
}

import 'package:flutter/material.dart';
import '../widgets/learning_flow_orchestrator.dart';

class LearningFlowScreen extends StatelessWidget {
  final String topicId;
  final String? initialEquation;

  const LearningFlowScreen({
    super.key,
    required this.topicId,
    this.initialEquation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LearningFlowOrchestrator(
        topicId: topicId,
        initialEquation: initialEquation,
        onFlowComplete: (result) {
          // Si el flujo termina (ej: completó el minijuego), volvemos al dashboard
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

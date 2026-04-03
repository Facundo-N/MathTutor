import 'package:flutter/material.dart';
import '../widgets/exercise_templates/destructor_ecuaciones_template.dart';
import '../models/ai_exercise_model.dart';

/// Standalone preview screen to showcase the rebuilt DestructorEcuacionesTemplate.
/// Navigate here via:  Navigator.pushNamed(context, '/destructor-preview');
class DestructorPreviewScreen extends StatefulWidget {
  final String
  topicId; // 'linear', 'distributive', 'factorization', 'quadratic', 'cubic', 'all'

  const DestructorPreviewScreen({super.key, this.topicId = 'all'});

  @override
  _DestructorPreviewScreenState createState() =>
      _DestructorPreviewScreenState();
}

class _DestructorPreviewScreenState extends State<DestructorPreviewScreen> {
  int _key = 0;
  int _sampleIdx = 0;

  // ── Equation Bank per Topic ───────────────────────────────────────────
  static const Map<String, List<Map<String, String>>> _BANK = {
    'linear': [
      {'equation': '2x + 4 = 20', 'answer': 'x = 8'},
      {'equation': '3x - 6 = 15', 'answer': 'x = 7'},
    ],
    'distributive': [
      {'equation': '3(x + 2) = 15', 'answer': 'x = 3'},
      {'equation': '2(x - 1) = 8', 'answer': 'x = 5'},
    ],
    'factorization': [
      {'equation': 'x² - 3x = 0', 'answer': 'x = 0 o x = 3'},
      {'equation': '2x² + 4x = 0', 'answer': 'x = 0 o x = -2'},
    ],
    'quadratic': [
      {'equation': 'x² - 25 = 0', 'answer': 'x = ±5'},
      {'equation': '2x² - 32 = 0', 'answer': 'x = ±4'},
    ],
    'cubic': [
      {'equation': 'x³ = 27', 'answer': 'x = 3'},
      {'equation': '2x³ = 16', 'answer': 'x = 2'},
    ],
  };

  List<Map<String, String>> get _currentSamples {
    if (widget.topicId == 'all' || !_BANK.containsKey(widget.topicId)) {
      return _BANK.values.expand((list) => list).toList();
    }
    return _BANK[widget.topicId]!;
  }

  AIExercise _buildExercise(int idx) {
    final samples = _currentSamples;
    final s = samples[idx % samples.length];

    // Si el topicId es 'all', inferimos el topic real basado en la ecuación buscando la original en el _BANK
    String computedTopic = widget.topicId;
    if (computedTopic == 'all') {
      for (final entry in _BANK.entries) {
        if (entry.value.any((item) => item['equation'] == s['equation'])) {
          computedTopic = entry.key;
          break;
        }
      }
    }

    return AIExercise(
      exerciseType: 'destructor_$computedTopic',
      equation: s['equation']!,
      storyContext: 'Resuelve la ecuación para la categoría $computedTopic.',
      pieces:
          s['equation']!.replaceAll(')', ' )').replaceAll('(', '( ').split(' ')
            ..removeWhere((e) => e.isEmpty),
      correctAnswer: s['answer']!,
    );
  }

  void _nextSample() => setState(() {
    _sampleIdx = (_sampleIdx + 1) % _currentSamples.length;
    _key++;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b1120),
      body: Stack(
        children: [
          DestructorEcuacionesTemplate(
            key: ValueKey(_key),
            exercise: _buildExercise(_sampleIdx),
            onStepCompleted: () {},
            onExerciseCompleted: _nextSample,
            onLivesChanged: (_) {},
          ),

          // ── Bottom navigation bar ─────────────────────────────────────
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavBtn(
                  icon: Icons.arrow_back_ios_new,
                  label: 'Salir (${widget.topicId})',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 16),
                _NavBtn(
                  icon: Icons.skip_next_rounded,
                  label: 'Siguiente ecuación',
                  onTap: _nextSample,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

const kTemplateCards = [
  {'id': 'academia_ninja',    'emoji': '🥷', 'name': 'Academia Ninja'},
  {'id': 'destruir_seleccion','emoji': '💥', 'name': 'Destructor X'},
  {'id': 'candymath',         'emoji': '🍬', 'name': 'Candy Math'},
  {'id': 'dardos',            'emoji': '🎯', 'name': 'Dardos'},
  {'id': 'beatmath',          'emoji': '🎵', 'name': 'Beat Math'},
];

class TemplatePickerScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> templateFuture;
  final String topicId;
  final void Function(String templateId, String equation) onComplete;

  const TemplatePickerScreen({
    super.key,
    required this.templateFuture,
    required this.topicId,
    required this.onComplete,
  });

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  int _currentIndex = 2;
  String? _resolvedTemplateId;
  String? _resolvedEquation;
  bool _isDecelerating = false;
  bool _isLanded = false;
  Timer? _timer;
  int _intervalMs = 80;

  @override
  void initState() {
    super.initState();
    _startCycling();
    
    widget.templateFuture.then((result) {
      if (!mounted) return;
      setState(() {
        _resolvedTemplateId = result['template_id'] as String;
        _resolvedEquation   = result['equation'] as String;
        _isDecelerating = true;
      });
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _resolvedTemplateId = 'destructor_ecuaciones';
        _resolvedEquation   = '2x + 5 = 15';
        _isDecelerating = true;
      });
    });
  }

  void _startCycling() {
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), (_) {
      setState(() => _currentIndex = (_currentIndex + 1) % kTemplateCards.length);
      
      if (_isDecelerating) {
        _timer?.cancel();
        
        if (_intervalMs < 700) {
          _intervalMs = (_intervalMs * 1.5).round().clamp(80, 700);
        }
        
        final winnerIdx = kTemplateCards.indexWhere((t) => t['id'] == _resolvedTemplateId);
        // si winnerIdx es -1 significa que el template no está en la ruleta visible (fallback silencioso)
        // por lo que frenamos en cualquier lado, o frenamos cuando lleguemos al final
        if (_intervalMs >= 600 && (winnerIdx == -1 || _currentIndex == winnerIdx)) {
           _landOnWinner();
           return;
        }
        _startCycling(); 
      }
    });
  }

  void _landOnWinner() {
    setState(() => _isLanded = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) widget.onComplete(_resolvedTemplateId!, _resolvedEquation!);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Color> _getGradientForTemplate(String id) {
    switch (id) {
      case 'beatmath': return const [Color(0xFF7C3AED), Color(0xFFDB2777)];
      case 'academia_ninja': return const [Color(0xFF064E3B), Color(0xFF10B981)];
      case 'destruir_seleccion': return const [Color(0xFF7F1D1D), Color(0xFFEF4444)];
      case 'candymath': return const [Color(0xFFDB2777), Color(0xFFF59E0B)];
      case 'dardos': return const [Color(0xFF1D4ED8), Color(0xFF06B6D4)];
      default: return const [Color(0xFF334155), Color(0xFF64748B)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = kTemplateCards[_currentIndex];
    final cardId = currentCard['id'] as String;
    final cardEmoji = currentCard['emoji'] as String;
    final cardName = currentCard['name'] as String;
    final cardGradient = _getGradientForTemplate(cardId);
    final primaryColor = cardGradient.last;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎲 Seleccionando tu juego...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Container(
                key: ValueKey(_currentIndex),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: _isLanded ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.6),
                      spreadRadius: 20,
                      blurRadius: 40,
                    )
                  ] : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cardEmoji,
                      style: const TextStyle(fontSize: 72),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cardName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(kTemplateCards.length, (index) {
                final isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 12 : 8,
                  height: isActive ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.white : Colors.white24,
                    boxShadow: isActive ? [
                      BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1)
                    ] : [],
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            if (!_isLanded)
              const Text(
                'Eligiendo...',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: const Text(
                      '¡Listo!',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

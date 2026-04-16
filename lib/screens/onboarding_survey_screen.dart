// lib/screens/onboarding_survey_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/animated_aurora.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Selections
  String _selectedObjective = 'entender';
  String _selectedTone = 'amigable';
  String _selectedScaffolding = 'medio';
  final List<String> _selectedContexts = [];
  final TextEditingController _interestsController = TextEditingController();

  final List<Map<String, dynamic>> _objectives = [
    {
      'id': 'aprobar',
      'name': 'Aprobar examen',
      'icon': Icons.assignment_turned_in,
    },
    {'id': 'entender', 'name': 'Entender de verdad', 'icon': Icons.psychology},
    {'id': 'rapido', 'name': 'Hacerlo rápido', 'icon': Icons.speed},
  ];

  final List<Map<String, dynamic>> _tones = [
    {'id': 'serio', 'name': 'Serio y formal', 'icon': Icons.business_center},
    {
      'id': 'amigable',
      'name': 'Cercano y amigable',
      'icon': Icons.sentiment_satisfied_alt,
    },
    {'id': 'humor', 'name': 'Con humor liviano', 'icon': Icons.celebration},
    {
      'id': 'sin_historia',
      'name': 'Sin historias (Directo)',
      'icon': Icons.bolt,
    },
  ];

  final List<Map<String, dynamic>> _scaffoldings = [
    {'id': 'alto', 'name': 'Dame muchas pistas', 'icon': Icons.help_outline},
    {
      'id': 'medio',
      'name': 'Solo si me trabo',
      'icon': Icons.lightbulb_outline,
    },
    {'id': 'bajo', 'name': 'No me des spoilers', 'icon': Icons.visibility_off},
  ];

  final List<Map<String, dynamic>> _contextOptions = [
    {'id': 'space', 'name': '🚀 Espacio', 'color': Colors.indigo},
    {'id': 'sports', 'name': '⚽ Deportes', 'color': Colors.green},
    {'id': 'gaming', 'name': '🎮 Gaming', 'color': Colors.purple},
    {'id': 'music', 'name': '🎵 Música', 'color': Colors.pink},
    {'id': 'nature', 'name': '🌿 Naturaleza', 'color': Colors.teal},
    {'id': 'tech', 'name': '🤖 Tecnología', 'color': Colors.blueGrey},
  ];

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _handleFinish();
    }
  }

  Future<void> _handleFinish() async {
    final userProvider = context.read<UserProvider>();
    setState(() => _isSaving = true);

    try {
      final interests = _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await userProvider.updatePreferences(
        contexts: _selectedContexts,
        objective: _selectedObjective,
        tone: _selectedTone,
        scaffolding: _selectedScaffolding,
        specificInterests: interests,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          AnimatedAurora(
            isDarkMode: true,
            child: SafeArea(
              child: Column(
                children: [
                  // Progress Indicator
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => _buildProgressDot(index),
                      ),
                    ),
                  ),

                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (v) => setState(() => _currentPage = v),
                      children: [
                        _buildObjectiveStep(),
                        _buildToneStep(),
                        _buildScaffoldingStep(),
                        _buildContextStep(),
                        _buildInterestsStep(),
                      ],
                    ),
                  ),

                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    bool isActive = index <= _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 30 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildStepBase({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildObjectiveStep() {
    return _buildStepBase(
      title: '¿Cuál es tu objetivo?',
      subtitle: 'Esto me ayuda a saber qué tanto presionar.',
      child: Column(
        children: _objectives
            .map(
              (e) => _buildSelectionTile(
                e,
                _selectedObjective,
                (v) => setState(() => _selectedObjective = v),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildToneStep() {
    return _buildStepBase(
      title: '¿Cómo prefieres que hable?',
      subtitle: 'Ajustaré mi tono para que te sientas cómodo.',
      child: Column(
        children: _tones
            .map(
              (e) => _buildSelectionTile(
                e,
                _selectedTone,
                (v) => setState(() => _selectedTone = v),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildScaffoldingStep() {
    return _buildStepBase(
      title: '¿Nivel de ayuda?',
      subtitle: '¿Quieres que te guíe paso a paso o prefieres intentarlo solo?',
      child: Column(
        children: _scaffoldings
            .map(
              (e) => _buildSelectionTile(
                e,
                _selectedScaffolding,
                (v) => setState(() => _selectedScaffolding = v),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildContextStep() {
    return _buildStepBase(
      title: 'Temas para tus ejemplos',
      subtitle: 'Uso estas cosas para crear ejercicios realistas.',
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _contextOptions.length,
        itemBuilder: (context, index) {
          final opt = _contextOptions[index];
          final isSelected = _selectedContexts.contains(opt['id']);
          return _buildContextCard(opt, isSelected);
        },
      ),
    );
  }

  Widget _buildInterestsStep() {
    return _buildStepBase(
      title: 'Algo específico? (Opcional)',
      subtitle:
          '¿Una banda, serie o equipo que ames? Ej: Queen, The Office, Real Madrid',
      child: Column(
        children: [
          TextField(
            controller: _interestsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ej: Messi, Star Wars, Queen...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Usaré esto para crear analogías que de verdad entiendas.',
            style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionTile(
    Map<String, dynamic> opt,
    String current,
    Function(String) onSelect,
  ) {
    bool isSelected = opt['id'] == current;
    return GestureDetector(
      onTap: () => onSelect(opt['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white12,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(opt['icon'], color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              opt['name'],
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard(Map<String, dynamic> opt, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedContexts.remove(opt['id']);
          } else {
            _selectedContexts.add(opt['id']);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? opt['color'].withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? opt['color'] : Colors.white24,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            opt['name'],
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: const Text(
                'ATRÁS',
                style: TextStyle(color: Colors.white60),
              ),
            )
          else
            const SizedBox.shrink(),

          ElevatedButton(
            onPressed: _isSaving ? null : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F172A),
                    ),
                  )
                : Text(
                    _currentPage == 4 ? 'FINALIZAR' : 'SIGUIENTE',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

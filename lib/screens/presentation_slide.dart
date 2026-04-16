// lib/screens/presentation_slide.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../widgets/animated_aurora.dart';

class PresentationSlide extends StatelessWidget {
  final String title;
  final List<String> content;
  final int slideIndex;
  final IconData icon;

  const PresentationSlide({
    super.key,
    required this.title,
    required this.content,
    required this.slideIndex,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 600.ms)
                .scale(curve: Curves.elasticOut, duration: 800.ms),

            const SizedBox(height: 48),

            // Glass Card Content
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 24),
                      ...List.generate(content.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8, right: 16),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ).animate(delay: (400 + index * 100).ms).scale(),
                              Expanded(
                                child: Text(
                                  content[index],
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    height: 1.6,
                                  ),
                                )
                                    .animate(delay: (400 + index * 100).ms)
                                    .fadeIn()
                                    .slideX(begin: 0.1),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final PageController _pageController = PageController();
  int _current = 0;

  final List<Map<String, dynamic>> _slidesData = [
    {
      'title': 'Bienvenida',
      'content': [
        'Soy tu tutora de matemáticas.',
        'Resolveremos problemas paso a paso con explicaciones.',
      ],
      'icon': Icons.school_outlined,
    },
    {
      'title': 'Aprende Jugando',
      'content': [
        'Arrastra bloques para transformar ecuaciones.',
        'Recibirás pistas y evaluación en tiempo real.',
      ],
      'icon': Icons.auto_fix_high,
    },
    {
      'title': 'Todo Listo',
      'content': [
        'Comencemos a practicar y dominar las matemáticas ahora mismo.',
      ],
      'icon': Icons.rocket_launch_outlined,
    },
  ];

  void _goHome() {
    final userProvider = context.read<UserProvider>();

    if (!userProvider.hasProfile) {
      debugPrint('🚀 Nueva fase: navegando a /onboarding-survey');
      Navigator.of(context).pushReplacementNamed('/onboarding-survey');
    } else {
      // Simplificado: Ya no pasamos por style-onboarding
      debugPrint('🏠 Todo listo, navegando a /home');
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnimatedAurora(
        isDarkMode: true,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MathTutor',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton(
                      onPressed: _goHome,
                      child: Text(
                        'SALTAR',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slidesData.length,
                    (index) => _buildProgressDot(index),
                  ),
                ),
              ),

              // Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slidesData.length,
                  onPageChanged: (i) {
                    setState(() => _current = i);
                  },
                  itemBuilder: (context, i) {
                    final data = _slidesData[i];
                    return PresentationSlide(
                      title: data['title'],
                      content: data['content'],
                      slideIndex: i,
                      icon: data['icon'],
                    );
                  },
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_current > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: 400.ms,
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'ATRÁS',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),

                    ElevatedButton(
                      onPressed: () {
                        if (_current < _slidesData.length - 1) {
                          _pageController.nextPage(
                            duration: 400.ms,
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _goHome();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _current < _slidesData.length - 1
                            ? 'SIGUIENTE'
                            : 'COMENZAR',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(int index) {
    bool isActive = index == _current;
    return AnimatedContainer(
      duration: 300.ms,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 30 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// lib/screens/presentation_slide.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart'; // ✅ NUEVO
import '../services/visual_style_provider.dart'; // ✅ NUEVO

class PresentationSlide extends StatefulWidget {
  final String title;
  final List<String> content;
  final int slideIndex;
  final Widget? customWidget;

  const PresentationSlide({
    super.key,
    required this.title,
    required this.content,
    required this.slideIndex,
    this.customWidget,
  });

  @override
  State<PresentationSlide> createState() => _PresentationSlideState();
}

class _PresentationSlideState extends State<PresentationSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(
              color: Colors.blue.shade100,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  height: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.2, duration: 500.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              ...List.generate(widget.content.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate()
                          .scale(
                            delay: (300 + index * 150).ms,
                            duration: 300.ms,
                            begin: const Offset(0, 0),
                            curve: Curves.elasticOut,
                          ),
                      Expanded(
                        child: Text(
                          widget.content[index],
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: (300 + index * 150).ms,
                              duration: 400.ms,
                            )
                            .slideX(
                              begin: -0.3,
                              delay: (300 + index * 150).ms,
                              duration: 500.ms,
                              curve: Curves.easeOut,
                            ),
                      ),
                    ],
                  ),
                );
              }),

              if (widget.customWidget != null) ...[
                const SizedBox(height: 24),
                widget.customWidget!
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .scale(delay: 800.ms, duration: 500.ms, curve: Curves.easeOut),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  final List<PresentationSlide> _slides = const [
    PresentationSlide(
      title: '👋 Bienvenida',
      content: [
        'Soy tu tutora de matemáticas.',
        'Resolveremos problemas paso a paso con explicaciones y práctica.',
      ],
      slideIndex: 0,
    ),
    PresentationSlide(
      title: '📚 Aprende con práctica',
      content: [
        'Arrastra bloques para transformar ecuaciones.',
        'Recibirás pistas y evaluación automática.',
      ],
      slideIndex: 1,
    ),
    PresentationSlide(
      title: '🚀 Listo para empezar',
      content: [
        'Comencemos a practicar ahora.',
      ],
      slideIndex: 2,
    ),
  ];

  // ✅ MODIFICADO: Ahora decide si va a onboarding o directo a home
  void _goHome() {
    final styleProvider = context.read<VisualStyleProvider>();
    
    if (styleProvider.hasCompletedOnboarding) {
      // Ya eligió estilo antes, ir directo a home
      print('🏠 Usuario ya completó onboarding, navegando a /home');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Primera vez, mostrar selección de estilos
      print('🎨 Primera vez, navegando a /style-onboarding');
      Navigator.of(context).pushReplacementNamed('/style-onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Introducción',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                print('⏭️ Saltando introducción');
                _goHome();
              },
              child: const Text(
                'Saltar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de página
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index
                        ? Colors.blue.shade600
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),

          // Slides
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) {
                print('📄 Cambió a página $i');
                setState(() => _current = i);
              },
              itemBuilder: (context, i) => _slides[i],
            ),
          ),

          // Botones de navegación
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Botón "Atrás" (solo si no estamos en la primera página)
                  if (_current > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.blue.shade600, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '← Atrás',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  if (_current > 0) const SizedBox(width: 12),

                  // Botón "Siguiente" o "Comenzar"
                  Expanded(
                    flex: _current == 0 ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_current < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                          );
                        } else {
                          print('🎉 Botón Comenzar presionado');
                          _goHome();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _current < _slides.length - 1 ? 'Siguiente →' : '🚀 Comenzar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

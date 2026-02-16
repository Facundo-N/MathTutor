// lib/screens/style_onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/visual_style.dart';
import '../services/visual_style_provider.dart';

class StyleOnboardingScreen extends StatefulWidget {
  const StyleOnboardingScreen({super.key});

  @override
  State<StyleOnboardingScreen> createState() => _StyleOnboardingScreenState();
}

class _StyleOnboardingScreenState extends State<StyleOnboardingScreen> {
  VisualStyle? selectedStyle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Título
              const Text(
                '¿Cómo preferís la interfaz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Elegí el estilo que más te guste',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7F8C8D),
                ),
              ),

              const SizedBox(height: 40),

              // Opciones de estilo
              Expanded(
                child: ListView(
                  children: [
                    _buildStyleOption(
                      style: VisualStyle.playful,
                      icon: '🎨',
                      title: 'Divertido',
                      description: 'Colores brillantes y animaciones alegres',
                      colors: [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
                    ),

                    const SizedBox(height: 16),

                    _buildStyleOption(
                      style: VisualStyle.balanced,
                      icon: '⚖️',
                      title: 'Balanceado',
                      description: 'Equilibrio entre visual y funcionalidad',
                      colors: [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
                    ),

                    const SizedBox(height: 16),

                    _buildStyleOption(
                      style: VisualStyle.minimal,
                      icon: '▫️',
                      title: 'Minimalista',
                      description: 'Diseño sobrio y directo',
                      colors: [const Color(0xFF37474F), const Color(0xFF546E7A)],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mensaje tranquilizador
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF1976D2),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No te preocupes, lo ajustaremos automáticamente mientras usás la app (podés cambiar cuando quieras en Configuración)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1565C0),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón Empezar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedStyle != null ? _onStart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: selectedStyle != null ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Empezar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleOption({
    required VisualStyle style,
    required String icon,
    required String title,
    required String description,
    required List<Color> colors,
  }) {
    final isSelected = selectedStyle == style;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStyle = style;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFFE0E0E0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? colors.first.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 20 : 10,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Ícono
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF7F8C8D),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark si está seleccionado
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: colors.first,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onStart() async {
    if (selectedStyle == null) return;

    final provider = context.read<VisualStyleProvider>();
    
    // Marcar onboarding como completado y guardar estilo elegido
    await provider.completeOnboarding(selectedStyle!);

    // Mostrar feedback visual
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              '¡Listo! Configurado como ${provider.styleDisplayName}',
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Esperar un momento y navegar a home
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }
}

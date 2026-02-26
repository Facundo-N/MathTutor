import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedSlide extends StatefulWidget {
  final String title;
  final List<String> content;
  final int slideIndex;
  final Widget? customWidget;

  const AnimatedSlide({
    super.key,
    required this.title,
    required this.content,
    required this.slideIndex,
    this.customWidget,
  });

  @override
  State<AnimatedSlide> createState() => _AnimatedSlideState();
}

class _AnimatedSlideState extends State<AnimatedSlide>
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
              colors: [Colors.white, Colors.blue.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.blue.shade100, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título con animación
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
                  .slideX(
                    begin: -0.2,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 24),

              // Contenido con bullets animados
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
                      ).animate().scale(
                        delay: (300 + index * 150).ms,
                        duration: 300.ms,
                        begin: const Offset(0, 0),
                        curve: Curves.elasticOut,
                      ),
                      Expanded(
                        child:
                            Text(
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

              // Widget personalizado (si existe)
              if (widget.customWidget != null) ...[
                const SizedBox(height: 24),
                widget.customWidget!
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .scale(
                      delay: 800.ms,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),
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

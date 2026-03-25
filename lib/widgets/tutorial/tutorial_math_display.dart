// lib/widgets/tutorial/tutorial_math_display.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/tutorial_scene_model.dart';

class TutorialMathDisplay extends StatelessWidget {
  final List<MathBlock> blocks;
  final bool isInteractiveMode;
  final String? interactiveTargetId;
  final Function(String)? onBlockDragged;

  const TutorialMathDisplay({
    super.key, 
    required this.blocks,
    this.isInteractiveMode = false,
    this.interactiveTargetId,
    this.onBlockDragged,
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox(height: 100);

    final List<double> positions = [];
    double currentX = 0;
    
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      positions.add(currentX);
      
      double blockWidth = _getBlockWidth(block);
      
      // Agrupar coeficiente y variable (gap más pequeño)
      bool glued = false;
      if (i < blocks.length - 1 &&
          block.type == MathBlockType.blockGreen &&
          block.value.length == 1 &&
          blocks[i + 1].type == MathBlockType.blockDark) {
        glued = true;
      }
      
      currentX += blockWidth + (glued ? 3 : 6);
    }
    
    double totalWidth = currentX > 0 ? currentX - 6 : 0;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => isInteractiveMode,
      onAcceptWithDetails: (details) {
        if (onBlockDragged != null) {
          onBlockDragged!(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
          width: totalWidth,
          height: 180, // Altura ajustada para no desbordar con fracciones grandes
          child: Stack(
        clipBehavior: Clip.none,
        children: blocks.asMap().entries.map((entry) {
          int i = entry.key;
          MathBlock block = entry.value;
          double width = _getBlockWidth(block);

          return AnimatedPositioned(
            key: ValueKey(block.id),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOutBack, // Efecto rebote al reacomodarse
            left: positions[i],
            width: width,
            top: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Center(
                key: ValueKey(block.value),
                child: _buildBlock(block),
              ),
            ),
          );
        }).toList(),
      ),
    );
      },
    );
  }

  double _getBlockWidth(MathBlock block) {
    if (block.type == MathBlockType.operator) {
      return _getTextWidth(block.value, 38, FontWeight.bold);
    } else if (block.type == MathBlockType.fraction) {
      double numW = _getTextWidth(block.fractionNumerator ?? '1', 22, FontWeight.w800);
      double denW = _getTextWidth(block.fractionDenominator ?? '2', 22, FontWeight.w800);
      return (numW > denW ? numW : denW) + 42; // Padding + borders + safety
    } else if (block.type == MathBlockType.blockBracket) {
      return _getTextWidth(block.value, 46, FontWeight.w300) + 8; // padding 4*2
    } else if (block.type == MathBlockType.blockAction) {
      return _getTextWidth(block.value, 30, FontWeight.w800) + 40; // padding 18*2 + borders
    } else if (block.type == MathBlockType.blockRoot) {
      return _getTextWidth(block.value, 34, FontWeight.w900) + 32; // padding 14*2 + borders
    } else {
      return _getTextWidth(block.value, 30, FontWeight.w800) + 42; // Padding 18*2 + borders + margin extra
    }
  }

  double _getTextWidth(String text, double fontSize, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontWeight: weight, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  Widget _buildBlock(MathBlock block) {
    Widget child = _buildBlockInternal(block);
    
    // Highlight del bloque objetivo (pulso dorado)
    final bool isTarget = isInteractiveMode && block.id == interactiveTargetId;
    if (isTarget) {
      child = Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.7),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scaleXY(begin: 0.95, end: 1.05, duration: 700.ms),
            ),
          ),
          // Flecha indicadora arriba del bloque
          Positioned(
            top: -30,
            child: const Icon(Icons.arrow_downward_rounded, color: Colors.amber, size: 20)
              .animate(onPlay: (c) => c.repeat())
              .moveY(begin: -4, end: 4, duration: 500.ms)
              .fade(begin: 0.5, end: 1.0, duration: 500.ms),
          ),
        ],
      );
    }

    // Convertir a Draggable si estamos en modo interactivo y no es un operador/paréntesis
    if (isInteractiveMode && block.type != MathBlockType.operator && block.type != MathBlockType.blockBracket) {
      return Draggable<String>(
        data: block.id,
        feedback: Material(
          type: MaterialType.transparency,
          child: Transform.scale(scale: 1.15, child: Opacity(opacity: 0.9, child: _buildBlockInternal(block))),
        ),
        childWhenDragging: Opacity(opacity: 0.2, child: child),
        child: child,
      );
    }
    return child;
  }

  Widget _buildBlockInternal(MathBlock block) {
    switch (block.type) {
      case MathBlockType.operator:
        return Text(
          block.value,
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 38,
          ),
        );

      case MathBlockType.fraction:
        return _buildFraction(block)
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 300.ms);

      case MathBlockType.blockGreenMoving:
        // Animación de arrastre horizontal con flecha indicadora
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _greenBlock(block.value),
            Positioned(
              right: -40,
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.amber, size: 36)
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(begin: 0, end: 10, duration: 500.ms)
                  .fade(begin: 0.2, end: 1.0, duration: 500.ms),
            ),
          ],
        )
        .animate()
        .scaleXY(begin: 1.0, end: 1.1, duration: 400.ms);

      case MathBlockType.blockGreenGlow:
        return _greenBlock(block.value, glow: true)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.05, duration: 600.ms);

      case MathBlockType.blockGreenGhost:
        return Opacity(
          opacity: 0.5,
          child: _greenBlock(block.value, glow: true),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(begin: 0.4, end: 1.0, duration: 600.ms)
            .scaleXY(begin: 0.95, end: 1.0, duration: 600.ms);

      case MathBlockType.blockGreen:
        return _greenBlock(block.value)
            .animate()
            .fadeIn(duration: 200.ms);

      case MathBlockType.blockDark:
        return _darkBlock(block.value)
            .animate()
            .fadeIn(duration: 200.ms);

      case MathBlockType.blockBracket:
        return _bracketBlock(block.value)
            .animate()
            .fadeIn(duration: 200.ms);

      case MathBlockType.blockAction:
        return _actionBlock(block.value)
            .animate()
            .fadeIn(duration: 200.ms);

      case MathBlockType.blockRoot:
        return _rootBlock(block.value)
            .animate()
            .scaleXY(begin: 1.5, end: 1.0, duration: 400.ms, curve: Curves.easeOutBack)
            .fadeIn(duration: 200.ms);
    }
  }


  Widget _buildFraction(MathBlock block) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _greenBlock(block.fractionNumerator ?? '1', small: true),
        Container(
          height: 3,
          constraints: const BoxConstraints(minWidth: 50),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        _greenBlock(block.fractionDenominator ?? '2', small: true, darker: true),
      ],
    );
  }

  // ── Estilos exactos del HTML ──────────────────────────────────────────────

  static const _borderRadius = BorderRadius.all(Radius.circular(14));
  static const _borderRadiusDark = BorderRadius.all(Radius.circular(12));

  Widget _greenBlock(String text, {bool glow = false, bool small = false, bool darker = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 14 : 18,
        vertical: small ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: darker ? const Color(0xFF0A3818) : const Color(0xFF145C2B),
        borderRadius: _borderRadius,
        border: Border.all(
          color: darker ? const Color(0xFF1E7A33) : const Color(0xFF2DA94F),
          width: 2,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFF2DA94F).withValues(alpha: 0.8),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF2DA94F).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: small ? 22 : 30,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _bracketBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w300,
          fontSize: 46,
        ),
      ),
    );
  }

  Widget _actionBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706),
        borderRadius: _borderRadius,
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 30,
        ),
      ),
    );
  }

  Widget _rootBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAB308),
        borderRadius: _borderRadius,
        border: Border.all(color: const Color(0xFFFDE047), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDE047).withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w900,
          fontSize: 34,
        ),
      ),
    );
  }


  Widget _darkBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161A24),
        borderRadius: _borderRadiusDark,
        border: Border.all(color: const Color(0xFF272C3B), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 30,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

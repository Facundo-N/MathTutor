// lib/widgets/math_expression_display.dart

import 'package:flutter/material.dart';
import '../models/visual_style.dart';

class MathExpressionDisplay extends StatefulWidget {
  final String expression;
  final VisualStyleConfig config;
  final String? highlightedTerm;

  const MathExpressionDisplay({
    super.key,
    required this.expression,
    required this.config,
    this.highlightedTerm,
  });

  @override
  State<MathExpressionDisplay> createState() => _MathExpressionDisplayState();
}

class _MathExpressionDisplayState extends State<MathExpressionDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    final duration = _getAnimationDuration();
    final curve = _getAnimationCurve();

    _controller = AnimationController(duration: duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _getAnimationDuration() {
    switch (widget.config.copyTone) {
      case 'fun':
        return const Duration(milliseconds: 600);
      case 'friendly':
        return const Duration(milliseconds: 400);
      case 'formal':
        return const Duration(milliseconds: 200);
      default:
        return const Duration(milliseconds: 400);
    }
  }

  Curve _getAnimationCurve() {
    switch (widget.config.copyTone) {
      case 'fun':
        return Curves.elasticOut;
      case 'friendly':
        return Curves.easeOutCubic;
      case 'formal':
        return Curves.linear;
      default:
        return Curves.easeOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget content = _buildContent();

        if (widget.config.copyTone == 'fun') {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(opacity: _fadeAnimation.value, child: content),
          );
        }

        return Opacity(opacity: _fadeAnimation.value, child: content);
      },
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(widget.config.spacing),
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.config.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: widget.config.copyTone == 'fun'
            ? [
                BoxShadow(
                  color: widget.config.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Text(
        widget.expression,
        style: TextStyle(
          fontSize: _getFontSize(),
          fontWeight: FontWeight.bold,
          color: widget.config.primaryColor,
          letterSpacing: widget.config.letterSpacing * 2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  double _getFontSize() {
    switch (widget.config.copyTone) {
      case 'fun':
        return widget.config.titleFontSize * 1.8;
      case 'friendly':
        return widget.config.titleFontSize * 1.5;
      case 'formal':
        return widget.config.titleFontSize * 1.3;
      default:
        return widget.config.titleFontSize * 1.5;
    }
  }

  LinearGradient _getGradient() {
    switch (widget.config.copyTone) {
      case 'fun':
        return LinearGradient(
          colors: [
            widget.config.primaryColor.withValues(alpha: 0.15),
            widget.config.secondaryColor.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'formal':
        return LinearGradient(
          colors: [
            widget.config.backgroundColor,
            widget.config.backgroundColor,
          ],
        );
      default:
        return LinearGradient(
          colors: [
            widget.config.primaryColor.withValues(alpha: 0.08),
            widget.config.primaryColor.withValues(alpha: 0.08),
          ],
        );
    }
  }
}

// lib/widgets/draggable_math_piece.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/math_piece.dart';
import '../providers/adaptive_style_provider.dart';

class DraggableMathPiece extends StatefulWidget {
  final MathPiece piece;
  final VoidCallback? onDragStart;
  final Function(Offset)? onDragEnd;
  final VoidCallback? onTap;

  const DraggableMathPiece({
    super.key,
    required this.piece,
    this.onDragStart,
    this.onDragEnd,
    this.onTap,
  });

  @override
  State<DraggableMathPiece> createState() => _DraggableMathPieceState();
}

class _DraggableMathPieceState extends State<DraggableMathPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final styleProvider = Provider.of<AdaptiveStyleProvider>(context);
    final config = styleProvider.config;

    // Si está bloqueada, no es draggable
    if (widget.piece.isLocked) {
      return _buildPieceWidget(config, isLocked: true);
    }

    return GestureDetector(
      onTap: () {
        if (config.hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        widget.onTap?.call();
        styleProvider.trackTap();
      },
      child: Draggable<MathPiece>(
        data: widget.piece,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: _buildPieceWidget(config, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildPieceWidget(config),
        ),
        onDragStarted: () {
          if (config.hapticFeedback) {
            HapticFeedback.mediumImpact();
          }
          widget.onDragStart?.call();
          styleProvider.trackTap();
        },
        onDragEnd: (details) {
          widget.onDragEnd?.call(details.offset);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: _buildPieceWidget(config),
        ),
      ),
    );
  }

  Widget _buildPieceWidget(
    StyleConfig config, {
    bool isDragging = false,
    bool isLocked = false,
  }) {
    final shouldPulse = widget.piece.isHighlighted && config.pulseOnHint;
    final shouldGlow = _isHovering && config.glowOnHover;

    Widget pieceWidget = AnimatedContainer(
      duration: config.animationDuration,
      width: config.pieceSize,
      height: config.pieceSize,
      padding: EdgeInsets.all(config.padding / 2),
      decoration: BoxDecoration(
        color: config.usePieceGradient ? null : _getPieceColor(config),
        gradient: config.usePieceGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getPieceColor(config),
                  _getPieceColor(config).withValues(alpha: 0.7),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(config.pieceBorderRadius),
        border: Border.all(
          color: widget.piece.isHighlighted
              ? Colors.amber
              : Colors.black.withValues(alpha: 0.1),
          width: widget.piece.isHighlighted ? 3 : 2,
        ),
        boxShadow: config.pieceElevation > 0
            ? [
                BoxShadow(
                  color: _getPieceColor(
                    config,
                  ).withValues(alpha: config.pieceShadowOpacity),
                  blurRadius: config.pieceElevation * 2,
                  offset: Offset(0, config.pieceElevation),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          widget.piece.displayValue,
          style: TextStyle(
            fontSize: config.fontSize,
            fontWeight: config.fontWeight,
            fontFamily: config.fontFamily,
            letterSpacing: config.letterSpacing,
            color: config.usePieceGradient ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );

    // Aplicar pulse si está highlighted
    if (shouldPulse) {
      pieceWidget = ScaleTransition(scale: _pulseAnimation, child: pieceWidget);
    }

    // Aplicar glow si está hovering
    if (shouldGlow) {
      pieceWidget = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(config.pieceBorderRadius + 4),
          boxShadow: [
            BoxShadow(
              color: _getPieceColor(config).withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: pieceWidget,
      );
    }

    return pieceWidget;
  }

  Color _getPieceColor(StyleConfig config) {
    // Rotar colores según tipo de pieza
    final index = widget.piece.type.index % config.pieceColors.length;
    return config.pieceColors[index];
  }
}

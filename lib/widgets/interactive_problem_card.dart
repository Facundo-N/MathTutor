// lib/widgets/interactive_problem_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/adaptive_style_provider.dart';

class InteractiveProblemCard extends StatefulWidget {
  final String expression; // "2 + 2"
  final VoidCallback? onTap;
  final Function(String)? onNumberTap; // Cuando toca un número específico
  
  const InteractiveProblemCard({
    Key? key,
    required this.expression,
    this.onTap,
    this.onNumberTap,
  }) : super(key: key);

  @override
  State<InteractiveProblemCard> createState() => _InteractiveProblemCardState();
}

class _InteractiveProblemCardState extends State<InteractiveProblemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String? _highlightedPart;
  
  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }
  
  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }
  
  void _triggerShake() {
    _shakeController.forward(from: 0);
  }
  
  @override
  Widget build(BuildContext context) {
    final styleProvider = Provider.of<AdaptiveStyleProvider>(context);
    final config = styleProvider.config;
    
    // Parsear expresión en partes interactivas
    final parts = _parseExpression(widget.expression);
    
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * (1), 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          if (config.hapticFeedback) {
            HapticFeedback.lightImpact();
          }
          widget.onTap?.call();
          styleProvider.trackTap();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(config.padding * 2),
          decoration: BoxDecoration(
            gradient: config.usePieceGradient
                ? LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.purple.shade50,
                    ],
                  )
                : null,
            color: config.usePieceGradient ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(config.pieceBorderRadius),
            border: Border.all(
              color: config.pieceColors.first,
              width: 3,
            ),
            boxShadow: config.pieceElevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: config.spacing,
            children: parts.map((part) => _buildInteractivePart(part, config)).toList(),
          ),
        ),
      ),
    );
  }
  
  List<String> _parseExpression(String expr) {
    // Separar en números y operadores: "2+2" -> ["2", "+", "2"]
    return expr.split(RegExp(r'(\+|\-|\×|\÷|\=)')).where((s) => s.isNotEmpty).toList();
  }
  
  Widget _buildInteractivePart(String part, StyleConfig config) {
    final isOperator = ['+', '-', '×', '÷', '='].contains(part.trim());
    final isHighlighted = _highlightedPart == part;
    
    return GestureDetector(
      onTap: () {
        if (!isOperator) {
          setState(() => _highlightedPart = part);
          widget.onNumberTap?.call(part);
          
          if (config.hapticFeedback) {
            HapticFeedback.selectionClick();
          }
        }
      },
      child: AnimatedContainer(
        duration: config.animationDuration,
        padding: EdgeInsets.symmetric(
          horizontal: config.padding,
          vertical: config.padding / 2,
        ),
        decoration: BoxDecoration(
          color: isHighlighted
              ? config.pieceColors.first.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(config.pieceBorderRadius / 2),
          border: isHighlighted
              ? Border.all(color: config.pieceColors.first, width: 2)
              : null,
        ),
        child: Text(
          part,
          style: TextStyle(
            fontSize: config.fontSize * 2.5, // Más grande que piezas normales
            fontWeight: config.fontWeight,
            fontFamily: config.fontFamily,
            letterSpacing: config.letterSpacing * 2,
            color: isOperator ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
  
  // Método público para shake desde afuera
  void shake() {
    _triggerShake();
  }
}

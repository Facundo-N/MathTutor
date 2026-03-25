// lib/widgets/interactive_board_widget.dart
// Pizarra interactiva como widget embeddable (refactorizado de BoardScreen)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';

import 'interactive_math_element.dart';
import 'equals_portal.dart';

/// Widget de pizarra interactiva táctil embeddable.
/// Aspecto rectangular vertical (3:4) para formato portrait.
///
/// Se usa dentro de [UnifiedBoardChatScreen] como zona central.
class InteractiveBoardWidget extends StatefulWidget {
  final String equation;
  final ValueChanged<String>? onElementMoved;
  final VoidCallback? onEquationSolved;

  const InteractiveBoardWidget({
    super.key,
    required this.equation,
    this.onElementMoved,
    this.onEquationSolved,
  });

  @override
  State<InteractiveBoardWidget> createState() => _InteractiveBoardWidgetState();
}

class _InteractiveBoardWidgetState extends State<InteractiveBoardWidget> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Use post-frame callback to avoid calling notifyListeners()
      // while the widget tree is still being built (setState during build crash).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BoardProvider>().initializeBoard(widget.equation);
        }
      });
    }
  }

  @override
  void didUpdateWidget(InteractiveBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equation != widget.equation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BoardProvider>().initializeBoard(widget.equation);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardProvider = context.watch<BoardProvider>();
    final board = boardProvider.currentBoard;

    if (board == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B5CE7)),
      );
    }

    return Column(
      children: [
        // Header con ecuación original
        _buildEquationHeader(board.originalEquation),

        // Pizarra interactiva
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(60),
              minScale: 0.5,
              maxScale: 2.0,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparente para ver Aurora
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Fondo con grid sutil
                          CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _BoardGridPainter(),
                          ),

                          // Línea divisoria vertical (referencia del =)
                          Positioned(
                            left: constraints.maxWidth / 2 - 1,
                            top: 20,
                            bottom: 20,
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.grey.shade200.withValues(alpha: 0),
                                    Colors.grey.shade300,
                                    Colors.grey.shade200.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Elementos del lado izquierdo
                          ...board.leftSide.map((element) {
                            return InteractiveMathElement(element: element);
                          }),

                          // Portal del = (centro)
                          if (board.equalsElement != null)
                            EqualsPortal(equalsElement: board.equalsElement!),

                          // Elementos del lado derecho
                          ...board.rightSide.map((element) {
                            return InteractiveMathElement(element: element);
                          }),

                          // Mensaje de error
                          if (!board.isCurrentActionValid &&
                              board.errorMessage != null)
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: _buildErrorBanner(board.errorMessage!),
                            ),

                          // Hint de IA (spotlight)
                          if (board.hintText != null)
                            Positioned(
                              top: 12,
                              left: 12,
                              right: 12,
                              child: _buildHintBanner(
                                board.hintText!,
                                boardProvider,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Mini toolbar
        _buildMiniToolbar(context, boardProvider, board),
      ],
    );
  }

  Widget _buildEquationHeader(String equation) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B5CE7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calculate,
              color: Color(0xFF6B5CE7),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              equation,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniToolbar(
    BuildContext context,
    BoardProvider boardProvider,
    dynamic board,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolBtn(
            icon: Icons.undo,
            label: 'Deshacer',
            enabled: board.history.isNotEmpty,
            onTap: () => boardProvider.undo(),
          ),
          _buildToolBtn(
            icon: Icons.lightbulb_outline,
            label: 'Pista',
            enabled: true,
            onTap: () => _showAIHint(boardProvider),
          ),
          _buildToolBtn(
            icon: Icons.refresh,
            label: 'Reiniciar',
            enabled: true,
            onTap: () => boardProvider.initializeBoard(widget.equation),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? const Color(0xFF6B5CE7) : Colors.grey.shade300,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: enabled ? Colors.white70 : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintBanner(String hint, BoardProvider boardProvider) {
    return Material(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => boardProvider.clearSpotlight(),
              child: Icon(Icons.close, size: 16, color: Colors.amber.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIHint(BoardProvider boardProvider) {
    // TODO: Integrar con backend real
    boardProvider.setSpotlight(
      'left_num_0',
      '¿Qué pasaría si pasas este número al otro lado del =?',
    );
  }
}

// ─── Grid Painter ───
class _BoardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 0.5;

    // Grid horizontal sutil
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Grid vertical sutil
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

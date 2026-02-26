// lib/screens/board_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/board_provider.dart';
import '../widgets/interactive_math_element.dart';
import '../widgets/equals_portal.dart';

/// Pantalla principal de la Pizarra Interactiva
class BoardScreen extends StatefulWidget {
  final String equation; // Ecuación inicial a resolver

  const BoardScreen({super.key, required this.equation});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  @override
  void initState() {
    super.initState();

    // Inicializar la pizarra con la ecuación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoardProvider>().initializeBoard(widget.equation);
    });
  }

  @override
  Widget build(BuildContext context) {
    final boardProvider = context.watch<BoardProvider>();
    final board = boardProvider.currentBoard;

    if (board == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pizarra Interactiva'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // Botón de deshacer
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: board.history.isNotEmpty
                ? () => boardProvider.undo()
                : null,
          ),
          // Botón de ayuda (IA Coach)
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () {
              _showAIHint(context, boardProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con ecuación original
          _buildHeader(board.originalEquation),

          // Área principal: InteractiveViewer con pizarra
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 2.0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.7,
                color: Colors.white,
                child: Stack(
                  children: [
                    // Línea divisoria vertical (referencia del =)
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 2,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 4, color: Colors.grey.shade300),
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

                    // Mensaje de error si existe
                    if (!board.isCurrentActionValid &&
                        board.errorMessage != null)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: _buildErrorMessage(board.errorMessage!),
                      ),

                    // Hint de IA si existe
                    if (board.hintText != null)
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: _buildAIHint(board.hintText!),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Toolbar inferior
          _buildBottomToolbar(context, boardProvider),
        ],
      ),
    );
  }

  Widget _buildHeader(String equation) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.calculate, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            'Resolviendo: $equation',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Material(
      color: Colors.red.shade100,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHint(String hint) {
    return Material(
      color: Colors.amber.shade100,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hint,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                context.read<BoardProvider>().clearSpotlight();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(
    BuildContext context,
    BoardProvider boardProvider,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            icon: Icons.keyboard,
            label: 'Teclado',
            onTap: () {
              // TODO: Mostrar teclado matemático
            },
          ),
          _buildToolbarButton(
            icon: Icons.camera_alt,
            label: 'Cámara',
            onTap: () {
              // TODO: OCR para capturar ecuación
            },
          ),
          _buildToolbarButton(
            icon: Icons.edit,
            label: 'Dibujar',
            onTap: () {
              // TODO: Modo de dibujo
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIHint(BuildContext context, BoardProvider boardProvider) {
    // Simulación de hint de IA
    // TODO: Integrar con backend
    boardProvider.setSpotlight(
      'left_num_0',
      '¿Qué pasaría si pasas este número al otro lado del =?',
    );
  }
}

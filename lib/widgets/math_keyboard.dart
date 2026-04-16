import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback onClose;
  final TextEditingController?
  controller; // NUEVO: Controlador para la vista previa

  const MathKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onSubmit,
    required this.onClose,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Definimos las teclas de nuestra calculadora / teclado matemático
    final List<String> keys = [
      'x',
      'y',
      '²',
      '³',
      '(',
      ')',
      '7',
      '8',
      '9',
      '÷',
      '=',
      '4',
      '5',
      '6',
      '×',
      '+',
      '1',
      '2',
      '3',
      '-',
      'DEL',
      '0',
      '.',
      ',',
      'ENTER',
    ];

    return Container(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior del teclado (Drag handle + Close)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // Spacer
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.keyboard_hide_rounded,
                        color: Colors.white54,
                      ),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),

              // VISTA PREVIA DEL TEXTO (Solo si se proporcionó un controlador)
              if (controller != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    readOnly:
                        true, // Es solo un preview, se edita con las teclas
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Ecuación...',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Grid de botones
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 5 columnas
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final keyLabel = keys[index];
                  return _buildKey(keyLabel);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    bool isAction = label == 'DEL' || label == 'ENTER';
    bool isOperator = ['+', '-', '×', '÷', '=', '^', '(', ')'].contains(label);
    bool isVariable = ['x', 'y'].contains(label);

    Color bgColor = Colors.white.withValues(alpha: 0.1);
    Color textColor = Colors.white;

    if (isAction) {
      bgColor = label == 'ENTER'
          ? Colors.blue.withValues(alpha: 0.8)
          : Colors.redAccent.withValues(alpha: 0.5);
    } else if (isOperator) {
      bgColor = Colors.orangeAccent.withValues(alpha: 0.3);
      textColor = Colors.orangeAccent[100]!;
    } else if (isVariable) {
      bgColor = Colors.greenAccent.withValues(alpha: 0.2);
      textColor = Colors.greenAccent[100]!;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == 'DEL') {
            onBackspace();
          } else if (label == 'ENTER') {
            onSubmit();
          } else {
            // Reemplazar los signos visuales por operadores reales si es necesario
            String insertText = label;
            if (label == '×') insertText = '*';
            if (label == '÷') insertText = '/';
            onKeyPressed(insertText);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Center(
            child: label == 'DEL'
                ? const Icon(
                    Icons.backspace_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                : label == 'ENTER'
                ? const Icon(Icons.send_rounded, color: Colors.white, size: 20)
                : isOperator
                ? Math.tex(
                    label
                        .replaceAll('×', r'\times')
                        .replaceAll('÷', r'\div')
                        .replaceAll('²', r'x^2')
                        .replaceAll('³', r'x^3')
                        .replaceAll('(', '(')
                        .replaceAll(')', ')'),
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

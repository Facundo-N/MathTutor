import 'package:flutter/material.dart';

class AvatarWidget extends StatefulWidget {
  final String message;
  final bool isSpeaking;
  final double size;

  const AvatarWidget({
    super.key,
    required this.message,
    required this.isSpeaking,
    this.size = 150,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar animado
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_controller.value * 0.1),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFB490FF),
                        const Color(0xFF9F7AEA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Pelo ondulado arriba
                      Positioned(
                        top: 10,
                        left: widget.size * 0.25,
                        right: widget.size * 0.25,
                        child: CustomPaint(
                          size: Size(widget.size * 0.5, 20),
                          painter: WavyHairPainter(),
                        ),
                      ),
                      
                      // Ojos
                      Positioned(
                        top: widget.size * 0.35,
                        left: widget.size * 0.25,
                        child: _buildEye(),
                      ),
                      Positioned(
                        top: widget.size * 0.35,
                        right: widget.size * 0.25,
                        child: _buildEye(),
                      ),
                      
                      // Moño
                      Positioned(
                        bottom: widget.size * 0.15,
                        left: widget.size * 0.3,
                        child: Container(
                          width: widget.size * 0.4,
                          height: widget.size * 0.15,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E),
                            borderRadius: BorderRadius.circular(widget.size * 0.1),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: widget.size * 0.05,
                              height: widget.size * 0.1,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(widget.size * 0.025),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          if (widget.message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: widget.size * 0.2,
      height: widget.size * 0.2,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Container(
          width: widget.size * 0.1,
          height: widget.size * 0.1,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
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

class WavyHairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    
    for (double i = 0; i <= size.width; i += size.width / 3) {
      path.quadraticBezierTo(
        i + size.width / 6,
        0,
        i + size.width / 3,
        size.height,
      );
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Borde negro
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

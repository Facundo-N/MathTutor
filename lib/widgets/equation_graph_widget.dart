import 'package:flutter/material.dart';
import '../services/math_engine_service.dart';

/// Widget para graficar ecuaciones CON ZOOM Y PAN
class EquationGraphWidget extends StatefulWidget {
  final GraphData graphData;

  const EquationGraphWidget({super.key, required this.graphData});

  @override
  State<EquationGraphWidget> createState() => _EquationGraphWidgetState();
}

class _EquationGraphWidgetState extends State<EquationGraphWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // ✅ NUEVO: Controlador para zoom y pan
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose(); // ✅ NUEVO
    super.dispose();
  }

  // ✅ NUEVO: Resetear zoom
  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  // ✅ NUEVO: Zoom in
  void _zoomIn() {
    final newScale = _currentScale * 1.5;
    _transformationController.value = Matrix4.diagonal3Values(
      newScale,
      newScale,
      1.0,
    );
    setState(() => _currentScale = newScale);
  }

  // ✅ NUEVO: Zoom out
  void _zoomOut() {
    final newScale = _currentScale / 1.5;
    if (newScale >= 0.5) {
      _transformationController.value = Matrix4.diagonal3Values(
        newScale,
        newScale,
        1.0,
      );
      setState(() => _currentScale = newScale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ecuación
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: Colors.purple[600], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.graphData.equation,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ NUEVO: Controles de zoom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _zoomIn,
                      icon: const Icon(Icons.zoom_in),
                      tooltip: 'Acercar',
                      color: Colors.purple[600],
                    ),
                    IconButton(
                      onPressed: _zoomOut,
                      icon: const Icon(Icons.zoom_out),
                      tooltip: 'Alejar',
                      color: Colors.purple[600],
                    ),
                    IconButton(
                      onPressed: _resetZoom,
                      icon: const Icon(Icons.center_focus_strong),
                      tooltip: 'Centrar',
                      color: Colors.purple[600],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.purple[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Zoom: ${(_currentScale * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ✅ NUEVO: Gráfico con zoom y pan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(100),
                  onInteractionUpdate: (details) {
                    setState(() {
                      _currentScale = _transformationController.value
                          .getMaxScaleOnAxis();
                    });
                  },
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: GraphPainter(
                          graphData: widget.graphData,
                          progress: _animation.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Punto de solución
          if (widget.graphData.solutionPoint != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Solución: (${widget.graphData.solutionPoint!.x.toStringAsFixed(1)}, ${widget.graphData.solutionPoint!.y.toStringAsFixed(1)})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // ✅ NUEVO: Ayuda de controles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usa dos dedos para hacer zoom, arrastra para moverte',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pintor personalizado para el gráfico
class GraphPainter extends CustomPainter {
  final GraphData graphData;
  final double progress;

  GraphPainter({required this.graphData, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // Calcular escala
    final xRange = graphData.xMax - graphData.xMin;
    final yRange = graphData.yMax - graphData.yMin;

    final xScale = size.width / xRange;
    final yScale = size.height / yRange;

    // Función para convertir coordenadas del gráfico a canvas
    Offset toCanvas(double x, double y) {
      final canvasX = (x - graphData.xMin) * xScale;
      final canvasY = size.height - (y - graphData.yMin) * yScale;
      return Offset(canvasX, canvasY);
    }

    // Dibujar grid
    final gridInterval = _calculateGridInterval(xRange);
    for (
      double x = (graphData.xMin / gridInterval).ceil() * gridInterval;
      x <= graphData.xMax;
      x += gridInterval
    ) {
      final point = toCanvas(x, 0);
      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, size.height),
        gridPaint,
      );
    }

    for (
      double y = (graphData.yMin / gridInterval).ceil() * gridInterval;
      y <= graphData.yMax;
      y += gridInterval
    ) {
      final point = toCanvas(0, y);
      canvas.drawLine(
        Offset(0, point.dy),
        Offset(size.width, point.dy),
        gridPaint,
      );
    }

    // Dibujar ejes
    final origin = toCanvas(0, 0);

    // Eje X
    canvas.drawLine(
      Offset(0, origin.dy),
      Offset(size.width, origin.dy),
      axisPaint,
    );

    // Eje Y
    canvas.drawLine(
      Offset(origin.dx, 0),
      Offset(origin.dx, size.height),
      axisPaint,
    );

    // Dibujar etiquetas de números
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Etiquetas eje X
    for (
      double x = (graphData.xMin / gridInterval).ceil() * gridInterval;
      x <= graphData.xMax;
      x += gridInterval
    ) {
      if (x == 0) continue;
      final point = toCanvas(x, 0);
      textPainter.text = TextSpan(
        text: x.toInt().toString(),
        style: const TextStyle(color: Colors.black, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(point.dx - 10, origin.dy + 5));
    }

    // Etiquetas eje Y
    for (
      double y = (graphData.yMin / gridInterval).ceil() * gridInterval;
      y <= graphData.yMax;
      y += gridInterval
    ) {
      if (y == 0) continue;
      final point = toCanvas(0, y);
      textPainter.text = TextSpan(
        text: y.toInt().toString(),
        style: const TextStyle(color: Colors.black, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(origin.dx + 5, point.dy - 10));
    }

    // Dibujar línea de la ecuación (animada)
    if (graphData.xValues.isNotEmpty && graphData.yValues.isNotEmpty) {
      final path = Path();
      final visiblePoints = (graphData.xValues.length * progress).round();

      bool firstPoint = true;
      for (int i = 0; i < visiblePoints; i++) {
        final x = graphData.xValues[i];
        final y = graphData.yValues[i];

        if (!y.isFinite) continue;

        final point = toCanvas(x, y);

        if (firstPoint) {
          path.moveTo(point.dx, point.dy);
          firstPoint = false;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(path, paint);
    }

    // Dibujar punto de solución
    if (graphData.solutionPoint != null && progress > 0.5) {
      final solutionPaint = Paint()
        ..color = Colors.green.shade700
        ..style = PaintingStyle.fill;

      final solutionPoint = toCanvas(
        graphData.solutionPoint!.x,
        graphData.solutionPoint!.y,
      );

      canvas.drawCircle(solutionPoint, 6, solutionPaint);

      // Borde blanco
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(solutionPoint, 6, borderPaint);
    }
  }

  double _calculateGridInterval(double range) {
    if (range <= 10) return 1;
    if (range <= 20) return 2;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    return 20;
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// lib/widgets/drop_zone_widget.dart
import 'package:flutter/material.dart';
import '../models/math_piece.dart';

class DropZoneWidget extends StatelessWidget {
  final DropZone dropZone;
  final Function(MathPiece, DropZone) onPieceDropped;
  final Widget child;

  const DropZoneWidget({
    super.key,
    required this.dropZone,
    required this.onPieceDropped,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<MathPiece>(
      onWillAcceptWithDetails: (details) {
        return dropZone.canAccept(details.data);
      },
      onAcceptWithDetails: (details) {
        onPieceDropped(details.data, dropZone);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        final isRejected = rejectedData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isRejected
                ? Colors.red.withValues(alpha: 0.1)
                : isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRejected
                  ? Colors.red
                  : isActive
                  ? Colors.green
                  : Colors.grey.shade300,
              width: isActive || isRejected ? 3 : 2,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

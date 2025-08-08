import 'package:flutter/material.dart';
import '../services/analyzer.dart';

class BoxesPainter extends CustomPainter {
  final List<Detection> detections;
  BoxesPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final goodPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.greenAccent;
    final badPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.redAccent;

    for (final d in detections) {
      final rect = Rect.fromLTWH(
        d.box.left * size.width,
        d.box.top * size.height,
        d.box.width * size.width,
        d.box.height * size.height,
      );
      final isGood = d.label == 'good';
      canvas.drawRect(rect, isGood ? goodPaint : badPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BoxesPainter oldDelegate) =>
      oldDelegate.detections != detections;
}

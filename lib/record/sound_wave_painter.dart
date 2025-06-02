import 'dart:math';

import 'package:flutter/material.dart';

class OptimizedWavePainter extends CustomPainter {
  final List<double> waveHistory;

  OptimizedWavePainter(this.waveHistory);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    final barWidth = 5.0;
    final spacing = 2.0;
    final barCount = waveHistory.length;
    final maxHeight = size.height;
    final minHeight = 8.0;
    final cornerRadius = Radius.circular(3.0);

    for (int i = 0; i < barCount; i++) {
      final level = waveHistory[i];
      final barHeight = (minHeight + level * (maxHeight - minHeight)).clamp(minHeight, maxHeight);
      final x = i * (barWidth + spacing);
      final y = (size.height - barHeight) / 2;

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        cornerRadius,
      );
      canvas.drawRRect(rRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OptimizedWavePainter oldDelegate) {
    return oldDelegate.waveHistory != waveHistory;
  }
}

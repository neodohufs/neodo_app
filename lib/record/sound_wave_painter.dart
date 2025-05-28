import 'dart:math';
import 'package:flutter/material.dart';

class SoundWavePainter extends CustomPainter {
  final double soundLevel;
  double smoothedSoundLevel = 0.0;

  SoundWavePainter(this.soundLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    final barCount = 30;
    final barWidth = 6.0;
    final spacing = 4.0;
    final maxHeight = size.height; // 꽉 차게
    final minHeight = 10.0;
    final cornerRadius = Radius.circular(3.0);
    final random = Random();

    smoothedSoundLevel = smoothedSoundLevel * 0.3 + soundLevel * 0.7;

    for (int i = 0; i < barCount; i++) {
      final randomFactor = 0.8 + random.nextDouble() * 0.4;
      final barHeight = max(minHeight, smoothedSoundLevel * maxHeight * randomFactor);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

class FlowingWavePainter extends CustomPainter {
  final List<double> waveHistory;

  FlowingWavePainter(this.waveHistory);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    final barWidth = 4.0;
    final spacing = 1.5;
    final totalWidth = waveHistory.length * (barWidth + spacing);
    final maxHeight = size.height;
    final minHeight = 6.0;
    final cornerRadius = Radius.circular(3.0);

    // 우측 끝 기준으로 좌우 흐름 효과
    double x = size.width - totalWidth;

    for (int i = 0; i < waveHistory.length; i++) {
      final level = waveHistory[i];
      final barHeight = (minHeight + level * (maxHeight - minHeight)).clamp(minHeight, maxHeight);
      final y = (size.height - barHeight) / 2;

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        cornerRadius,
      );
      canvas.drawRRect(rRect, paint);
      x += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant FlowingWavePainter oldDelegate) {
    return true; // 매 프레임마다 다시 그려야 흐름이 자연스러움
  }
}

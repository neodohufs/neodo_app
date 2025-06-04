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
    final maxHeight = size.height;
    final minHeight = 6.0;
    final cornerRadius = Radius.circular(3.0);

    // 오른쪽부터 왼쪽으로 그리기
    double x = size.width - barWidth;

    for (int i = waveHistory.length - 1; i >= 0; i--) {
      final level = waveHistory[i];
      final barHeight = (minHeight + level * (maxHeight - minHeight)).clamp(minHeight, maxHeight);
      final y = (size.height - barHeight) / 2;

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        cornerRadius,
      );
      canvas.drawRRect(rRect, paint);
      x -= (barWidth + spacing);

      if (x < 0) break; // 화면 벗어나면 중단
    }
  }

  @override
  bool shouldRepaint(covariant FlowingWavePainter oldDelegate) => true;
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class RealTimeWaveformPage extends StatefulWidget {
  @override
  _RealTimeWaveformPageState createState() => _RealTimeWaveformPageState();
}

class _RealTimeWaveformPageState extends State<RealTimeWaveformPage> with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  double _soundLevel = 0.0;
  double _smoothedLevel = 0.0;
  StreamSubscription? _dbSubscription;
  String? _filePath;
  Timer? _visualTimer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("마이크 권한이 필요합니다.")));
      Navigator.pop(context);
      return;
    }
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacADTS,
      bitRate: 128000,
      sampleRate: 44100,
    );

    _dbSubscription = _recorder.onProgress!.listen((event) {
      final db = event.decibels ?? -60;
      final linearLevel = ((db + 60) / 60).clamp(0.0, 1.0);
      _soundLevel = linearLevel;
    });

    _visualTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      setState(() {
        _smoothedLevel = _smoothedLevel * 0.85 + _soundLevel * 0.15;
      });
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    _dbSubscription?.cancel();
    _visualTimer?.cancel();
    setState(() => _isRecording = false);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _dbSubscription?.cancel();
    _visualTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text("실시간 웨이브", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _isRecording ? "녹음 중..." : "버튼을 눌러 녹음 시작",
            style: const TextStyle(fontSize: 22, color: Colors.brown),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Center(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: OptimizedWavePainter(_smoothedLevel),
                  size: Size(MediaQuery.of(context).size.width, 140),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(_isRecording ? "정지" : "녹음 시작"),
            onPressed: _isRecording ? _stopRecording : _startRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class OptimizedWavePainter extends CustomPainter {
  final double soundLevel;
  final Random random = Random();

  OptimizedWavePainter(this.soundLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    final barCount = 48;
    final barWidth = 5.0;
    final spacing = 2.0;
    final maxHeight = size.height;
    final minHeight = 8.0;
    final cornerRadius = Radius.circular(3.0);

    for (int i = 0; i < barCount; i++) {
      final randomFactor = 0.85 + random.nextDouble() * 0.3;
      final barHeight = max(minHeight, soundLevel * maxHeight * randomFactor);
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
    return oldDelegate.soundLevel != soundLevel;
  }
}

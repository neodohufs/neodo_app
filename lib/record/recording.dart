import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../meta_data/recording_meta_data.dart';

class SoundWavePainter extends CustomPainter {
  final double soundLevel;
  double smoothedSoundLevel = 0.0;

  SoundWavePainter(this.soundLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.fill;

    final barCount = 12;
    final barWidth = 8.0;
    final spacing = 4.0;
    final maxHeight = 20.0;
    final minHeight = 5.0;
    final cornerRadius = Radius.circular(4.0);
    final random = Random();

    smoothedSoundLevel = smoothedSoundLevel * 0.3 + soundLevel * 0.7;

    for (int i = 0; i < barCount; i++) {
      final randomFactor = 0.8 + random.nextDouble() * 0.4;
      final barHeight = max(minHeight, (smoothedSoundLevel * maxHeight * randomFactor));
      final x = i * (barWidth + spacing);
      final y = (size.height / 2) - (barHeight / 2);

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

class RecordingPage extends StatefulWidget {
  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  double _soundLevel = 0.0;
  StreamSubscription? _dbSubscription;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('마이크 권한이 필요합니다.')));
      Navigator.pop(context);
      return;
    }

    await _recorder.openRecorder();
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
      setState(() {
        _soundLevel = ((db + 60) / 60).clamp(0.0, 1.0);
      });
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    _dbSubscription?.cancel();
    setState(() => _isRecording = false);

    if (_filePath != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecordingMetaDataPage(filePath: _filePath!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('녹음', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomPaint(
              painter: SoundWavePainter(_soundLevel),
              size: Size(MediaQuery.of(context).size.width, 60),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.brown,
                    side: const BorderSide(color: Colors.brown),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('취소'),
                ),
                GestureDetector(
                  onTap: () => {},
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.brown,
                    child: Icon(_isRecording ? Icons.pause : Icons.mic, color: Colors.white, size: 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('완료'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

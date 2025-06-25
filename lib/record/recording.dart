/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:neodo/record/sound_wave_painter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../meta_data/recording_meta_data.dart';

class RecordingPage extends StatefulWidget {
  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _filePath;

  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  double _soundLevel = 0.0;
  double _smoothedLevel = 0.0;
  List<double> _waveHistory = List.filled(50, 0.0);
  StreamSubscription? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
      Navigator.pop(context);
      return;
    }

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dbSubscription?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;

    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4,
    );

    _dbSubscription = _recorder.onProgress!.listen((event) {
      final db = event.decibels;
      if (db == null) return;

      setState(() {
        _soundLevel = ((db + 60) / 60).clamp(0.0, 1.0);
        _smoothedLevel = _smoothedLevel * 0.3 + _soundLevel * 0.7;

        _waveHistory.removeAt(0);
        _waveHistory.add(_smoothedLevel);
      });
    });

    _recordingDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });

    setState(() {
      _isRecording = true;
      _isPaused = false;
    });
  }

  Future<void> _pauseResume() async {
    if (!_isRecording) return;

    if (_isPaused) {
      await _recorder.resumeRecorder();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } else {
      await _recorder.pauseRecorder();
      _timer?.cancel();
    }

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await _recorder.stopRecorder();
    _dbSubscription?.cancel();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (_filePath != null) {
      print("파일 저장 경로 : $_filePath");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecordingMetaDataPage(filePath: _filePath!),
        ),
      );
    }
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        children: [
          const SizedBox(height: 40),
          Text(
            formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 40),

          // 🔊 Wave 시각화
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: FlowingWavePainter(_waveHistory),
              size: Size(MediaQuery.of(context).size.width, 140),
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.brown,
                    side: const BorderSide(color: Colors.brown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('취소'),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!_isRecording) {
                      await _startRecording();
                    } else {
                      await _pauseResume();
                    }
                  },
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.brown,
                    child: Icon(
                      !_isRecording
                          ? Icons.mic
                          : _isPaused
                          ? Icons.play_arrow
                          : Icons.pause,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
*/
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../meta_data/recording_meta_data.dart';

class RecordingPage extends StatefulWidget {
  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _filePath;

  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  StreamSubscription? _dbSubscription;

  double _soundLevel = 0.0;
  double _smoothedLevel = 0.0;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
      setState(() {});
    });

    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
      Navigator.pop(context);
      return;
    }

    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void deactivate() {
    if (_isRecording) {
      _stopRecording();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _timer?.cancel();
    _dbSubscription?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4,
    );

    _dbSubscription = _recorder.onProgress!.listen((event) {
      final db = event.decibels;
      if (db == null) return;

      setState(() {
        _soundLevel = ((db + 60) / 60).clamp(0.0, 1.0);
        _smoothedLevel = _smoothedLevel * 0.3 + _soundLevel * 0.7;
      });
    });

    _recordingDuration = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });

    _waveController.repeat();

    setState(() {
      _isRecording = true;
      _isPaused = false;
    });
  }

  Future<void> _pauseResume() async {
    if (!_isRecording) return;

    if (_isPaused) {
      await _recorder.resumeRecorder();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } else {
      await _recorder.pauseRecorder();
      _timer?.cancel();
    }

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    _dbSubscription?.cancel();
    _timer?.cancel();
    _waveController.stop();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }

  void _finishRecording() {
    if (_filePath != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecordingMetaDataPage(filePath: _filePath!),
        ),
      );
    }
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 60),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: CircleVisualizerPainter(
                    level: (_isRecording && !_isPaused) ? _smoothedLevel : 0.0,
                  ),
                  size: const Size(250, 250),
                ),
                GestureDetector(
                  onTap: () async {
                    if (!_isRecording) {
                      await _startRecording();
                    } else {
                      await _pauseResume();
                    }
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.brown,
                    child: Icon(
                      !_isRecording
                          ? Icons.mic
                          : _isPaused
                          ? Icons.play_arrow
                          : Icons.pause,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.brown,
                    side: const BorderSide(color: Colors.brown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _isRecording
                      ? () async {
                    await _stopRecording();
                    _finishRecording();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class CircleVisualizerPainter extends CustomPainter {
  final double level;

  CircleVisualizerPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    if (level < 0.01) return; // level이 너무 낮으면 그리지 않음

    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(level);
    final radius = 60.0 + eased * 40.0;

    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleVisualizerPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}

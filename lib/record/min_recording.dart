import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../coaching_plan/coaching_feedback.dart';
import '../get_access_token.dart';

class MinRecordingPage extends StatefulWidget {
  final int topicId;
  const MinRecordingPage({super.key, required this.topicId});

  @override
  State<MinRecordingPage> createState() => _MinRecordingPageState();
}

class _MinRecordingPageState extends State<MinRecordingPage> with SingleTickerProviderStateMixin {
  sound.FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _remainingDuration = const Duration(minutes: 3);
  Timer? _timer;
  late String _filePath;

  StreamSubscription? _dbSubscription;
  double _smoothedLevel = 0.0;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() => setState(() {}));
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = sound.FlutterSoundRecorder();

    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마이크 권한이 필요합니다.'), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
      return;
    }

    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _waveController.dispose();
    _timer?.cancel();
    _dbSubscription?.cancel();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

    await _recorder!.startRecorder(toFile: _filePath, codec: sound.Codec.aacMP4);

    _dbSubscription = _recorder!.onProgress!.listen((event) {
      final db = event.decibels;
      if (db == null) return;
      final level = ((db + 60) / 60).clamp(0.0, 1.0);
      _smoothedLevel = _smoothedLevel * 0.3 + level * 0.7;
    });

    _waveController.repeat();

    _remainingDuration = const Duration(minutes: 3);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration.inSeconds > 0) {
        setState(() => _remainingDuration -= const Duration(seconds: 1));
      } else {
        _stopRecording();
      }
    });

    setState(() {
      _isRecording = true;
      _isPaused = false;
    });
  }

  Future<void> _pauseResume() async {
    if (!_isRecording) return;

    if (_isPaused) {
      await _recorder!.resumeRecorder();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingDuration.inSeconds > 0) {
          setState(() => _remainingDuration -= const Duration(seconds: 1));
        } else {
          _stopRecording();
        }
      });
    } else {
      await _recorder!.pauseRecorder();
      _timer?.cancel();
    }

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopRecording() async {
    if (_recorder?.isRecording == true || _recorder?.isPaused == true) {
      await _recorder!.stopRecorder();
      _timer?.cancel();
      _dbSubscription?.cancel();
      _waveController.stop();

      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
    }
  }

  Future<void> _uploadRecording(int topicId) async {
    try {
      await _stopRecording();
      File file = File(_filePath);
      if (!file.existsSync() || file.lengthSync() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('녹음 파일이 존재하지 않거나 비어 있습니다'), backgroundColor: Colors.red));
        return;
      }

      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final url = Uri.parse('https://bb69-1-230-133-117.ngrok-free.app/api/topics/$topicId/speech-coachings/record');

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..headers['Set-Cookie'] = 'Bearer $refreshToken'
        ..files.add(await http.MultipartFile.fromPath('record', file.path, contentType: MediaType('audio', 'm4a')));

      var response = await request.send();
      String responseBody = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseJson = json.decode(responseBody);
        final id = responseJson['data']?['speechCoachingId'];
        if (id != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => CoachingFeedbackPage(speechCoachingId: id)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('응답 파싱 오류: ID 없음'), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업로드 실패: ${response.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('3분 녹음', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatDuration(_remainingDuration),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          const SizedBox(height: 60),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: CircleVisualizerPainter(level: (_isRecording && !_isPaused) ? _smoothedLevel : 0.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _stopRecording();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.brown,
                    side: const BorderSide(color: Colors.brown),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _isRecording ? () async => await _uploadRecording(widget.topicId) : null,
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

class CircleVisualizerPainter extends CustomPainter {
  final double level;

  CircleVisualizerPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    if (level < 0.01) return;
    final center = Offset(size.width / 2, size.height / 2);
    final eased = Curves.easeOut.transform(level);
    final radius = 60.0 + eased * 40.0;

    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleVisualizerPainter oldDelegate) => oldDelegate.level != level;
}

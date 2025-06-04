import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:async';
import '../coaching_plan/coaching_feedback.dart';
import '../get_access_token.dart';

class minRecordingPage extends StatefulWidget {
  final int topicId;
  const minRecordingPage({super.key, required this.topicId});

  @override
  State<minRecordingPage> createState() => _minRecordingPageState();
}

class _minRecordingPageState extends State<minRecordingPage> {
  sound.FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Duration _remainingDuration = const Duration(minutes: 3);
  Timer? _timer;
  late String _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = sound.FlutterSoundRecorder();
    await _recorder!.openRecorder();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

    setState(() {
      _isRecording = true;
      _remainingDuration = const Duration(minutes: 3);
    });

    await _recorder!.startRecorder(toFile: _filePath, codec: sound.Codec.aacMP4);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingDuration.inSeconds > 0) {
        setState(() => _remainingDuration -= const Duration(seconds: 1));
      } else {
        _stopRecording();
      }
    });
  }

  Future<void> _pauseRecording() async {
    if (_recorder!.isRecording) {
      await _recorder!.pauseRecorder();
      _timer?.cancel();
      setState(() => _isRecording = false);
    } else if (_recorder!.isPaused) {
      await _recorder!.resumeRecorder();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingDuration.inSeconds > 0) {
          setState(() => _remainingDuration -= const Duration(seconds: 1));
        } else {
          _stopRecording();
        }
      });
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder != null && _recorder!.isRecording) {
      await _recorder!.stopRecorder();
      _timer?.cancel();
      setState(() => _isRecording = false);
    }
  }

  Future<void> _uploadRecording(int topicId) async {
    try {
      await _stopRecording(); // 안전하게 멈춤
      File file = File(_filePath);

      print("📁 파일 존재: ${file.existsSync()}, 크기: ${file.existsSync() ? file.lengthSync() : 0} bytes");

      if (!file.existsSync() || file.lengthSync() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('녹음 파일이 존재하지 않거나 비어 있습니다'), backgroundColor: Colors.red));
        return;
      }

      final token = await getAccessToken();
      final url = Uri.parse('https://3c45-1-230-133-117.ngrok-free.app/api/topics/$topicId/speech-coachings/record');

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'record',
          file.path,
          contentType: MediaType('audio', 'm4a'),
        ));

      var response = await request.send();

      String responseBody = await response.stream.bytesToString();
      print("🔁 응답 코드: ${response.statusCode}");
      print("📨 응답 본문: $responseBody");

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseJson = json.decode(responseBody);
        final id = responseJson['data']?['speechCoachingId'];
        if (id != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CoachingFeedbackPage(speechCoachingId: id)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('응답 파싱 오류: ID 없음'), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패: ${response.statusCode}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러 발생: $e'), backgroundColor: Colors.red));
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formatDuration(_remainingDuration),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
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
                GestureDetector(
                  onTap: _pauseRecording,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.brown,
                    child: Icon(
                      _isRecording ? Icons.pause : Icons.mic,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _uploadRecording(widget.topicId);
                  },
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

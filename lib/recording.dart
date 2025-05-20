import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'get_access_token.dart';
import 'home.dart';

class RecordingPage extends StatefulWidget {
  @override
  _RecordingPageState createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  sound.FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _timer;
  late String _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = sound.FlutterSoundRecorder();
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('마이크 권한이 필요합니다.')),
      );
      Navigator.pop(context);
      return;
    }
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
      _recordedDuration = Duration.zero;
    });

    await _recorder!.startRecorder(toFile: _filePath, codec: sound.Codec.aacMP4);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isRecording) {
        setState(() {
          _recordedDuration += Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _pauseRecording() async {
    if (_recorder!.isRecording) {
      await _recorder!.pauseRecorder();
      setState(() => _isRecording = false);
    } else if (_recorder!.isPaused) {
      await _recorder!.resumeRecorder();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder != null) {
      final path = await _recorder!.stopRecorder();
      setState(() => _isRecording = false);
      if (path != null) {
        File recordedFile = File(path);
        _showCompletionDialog(recordedFile);
      }
    }
  }

  Future<void> _stopRecordingGoHome() async {
    if (_recorder != null) {
      if (_isRecording) {
        await _recorder!.stopRecorder();
        setState(() => _isRecording = false);
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Map<String, String> koreanToEnglish = {
    "공식적": "FORMAL",
    "비공식적": "INFORMAL",
    "정보 전달": "INFORMATIVE",
    "보고": "REPORTING",
    "설득": "PERSUASIVE",
    "토론": "DEBATE",
    "소규모 (~10명)": "SMALL",
    "중규모 (~50명)": "MEDIUM",
    "대규모 (50명 이상)": "LARGE",
    "일반 대중": "GENERAL",
    "관련 지식 보유자": "KNOWLEDGEABLE",
    "전문가": "EXPERT",
  };

  String _selectedAtmosphere = '';
  String _selectedPurpose = '';
  String _selectedScale = '';
  String _selectedAudience = '';
  TextEditingController _timeLimitController = TextEditingController();
  TextEditingController _titleController = TextEditingController();

  void _showCompletionDialog(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Column(
            children: [
              Container(height: 5, width: double.infinity, color: Colors.black),
              SizedBox(height: 10),
              Text('발표 종류', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildTitleTextField('제목', _titleController),
                  _buildDropdown('📌 분위기', ['공식적', '비공식적'], _selectedAtmosphere, (val) => setState(() => _selectedAtmosphere = val)),
                  _buildDropdown('🎯 목적', ['정보 전달', '보고', '설득', '토론'], _selectedPurpose, (val) => setState(() => _selectedPurpose = val)),
                  _buildDropdown('👥 규모', ['소규모 (~10명)', '중규모 (~50명)', '대규모 (50명 이상)'], _selectedScale, (val) => setState(() => _selectedScale = val)),
                  _buildDropdown('🎓 청중 수준', ['일반 대중', '관련 지식 보유자', '전문가'], _selectedAudience, (val) => setState(() => _selectedAudience = val)),
                  _buildTextField('⏳ 제한 시간 (선택)', _timeLimitController),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_selectedAtmosphere.isNotEmpty && _selectedPurpose.isNotEmpty && _selectedScale.isNotEmpty && _selectedAudience.isNotEmpty) {
                  await postFile(
                    file,
                    koreanToEnglish[_selectedAtmosphere]!,
                    koreanToEnglish[_selectedPurpose]!,
                    koreanToEnglish[_selectedScale]!,
                    koreanToEnglish[_selectedAudience]!,
                    _timeLimitController.text.isNotEmpty ? int.parse(_timeLimitController.text) : 0,
                    _titleController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 항목을 선택해주세요.')));
                }
              },
              child: Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  Widget _buildDropdown(String title, List<String> items, String selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selectedValue.isEmpty ? null : selectedValue,
          hint: Text('선택하세요'),
          isExpanded: true,
          alignment: Alignment.center,
          items: items.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
          onChanged: (newValue) => onChanged(newValue!),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '시간을 입력하세요 (예: 30)',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTitleTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '제목을 입력하세요',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10),
          ),
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Future<void> postFile(File file, String atmosphere, String purpose, String scale, String audience, int deadline, String title) async {
    final uri = 'https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/record';
    final token = await getAccessToken();
    var dio = Dio();

    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    Map<String, dynamic> metadata = {
      "atmosphere": atmosphere,
      "purpose": purpose,
      "scale": scale,
      "audience": audience,
      "deadline": deadline,
    };

    try {
      FormData formData = FormData.fromMap({
        "record": await MultipartFile.fromFile(
          file.path,
          filename: '$title.m4a',
          contentType: MediaType('audio', 'mp4'),
        ),
        "request": MultipartFile.fromString(
          jsonEncode(metadata),
          contentType: MediaType('application', 'json'),
        ),
      });

      var response = await dio.post(uri, data: formData, options: Options(headers: {"Content-Type": "multipart/form-data"}));
      if (response.statusCode == 200) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      }
    } catch (e) {
      print("파일 업로드 에러: $e");
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
            child: Text(
              _formatDuration(_recordedDuration),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _stopRecordingGoHome,
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

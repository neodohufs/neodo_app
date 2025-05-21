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

  String _selectedAtmosphere = '';
  String _selectedPurpose = '';
  String _selectedScale = '';
  String _selectedAudience = '';
  TextEditingController _timeLimitController = TextEditingController();
  TextEditingController _titleController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    _recorder = sound.FlutterSoundRecorder();
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('마이크 권한이 필요합니다.')));
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
        _showMetaInputDialog(recordedFile);
      }
    }
  }

  void _showMetaInputDialog(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFFFF8E8),
          title: Text('발표 메타 정보 입력', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('제목', _titleController),
                _buildDropdown('📌 분위기', ['공식적', '비공식적'], _selectedAtmosphere, (val) => setState(() => _selectedAtmosphere = val)),
                _buildDropdown('🎯 목적', ['정보 전달', '보고', '설득', '토론'], _selectedPurpose, (val) => setState(() => _selectedPurpose = val)),
                _buildDropdown('👥 규모', ['소규모 (~10명)', '중규모 (~50명)', '대규모 (50명 이상)'], _selectedScale, (val) => setState(() => _selectedScale = val)),
                _buildDropdown('🎓 청중 수준', ['일반 대중', '관련 지식 보유자', '전문가'], _selectedAudience, (val) => setState(() => _selectedAudience = val)),
                _buildTextField('⏳ 제한 시간 (분)', _timeLimitController, numberOnly: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_selectedAtmosphere.isNotEmpty && _selectedPurpose.isNotEmpty && _selectedScale.isNotEmpty && _selectedAudience.isNotEmpty) {
                  bool success = await postFile(
                    file,
                    koreanToEnglish[_selectedAtmosphere]!,
                    koreanToEnglish[_selectedPurpose]!,
                    koreanToEnglish[_selectedScale]!,
                    koreanToEnglish[_selectedAudience]!,
                    _timeLimitController.text.isNotEmpty ? int.parse(_timeLimitController.text) : 0,
                    _titleController.text,
                  );
                  if (success) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 실패')));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 항목을 선택해주세요.')));
                }
              },
              child: Text('업로드'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selectedValue.isEmpty ? null : selectedValue,
          hint: Text('선택하세요'),
          isExpanded: true,
          items: items.map((val) => DropdownMenuItem<String>(value: val, child: Text(val))).toList(),
          onChanged: (val) => onChanged(val!),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool numberOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          keyboardType: numberOnly ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: numberOnly ? '숫자만 입력' : '입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Future<bool> postFile(File file, String atmosphere, String purpose, String scale, String audience, int deadline, String title) async {
    final uri = 'https://21b2-1-230-133-117.ngrok-free.app/api/speech-boards/record';
    final token = await getAccessToken();
    var dio = Dio();

    if (token == null) return false;

    dio.options.headers['Authorization'] = 'Bearer $token';

    Map<String, dynamic> metadata = {
      "atmosphere": atmosphere,
      "purpose": purpose,
      "scale": scale,
      "audience": audience,
      "deadline": deadline,
    };

    try {
      FormData formData = FormData.fromMap({
        "record": await MultipartFile.fromFile(file.path, filename: '$title.m4a', contentType: MediaType('audio', 'mp4')),
        "request": MultipartFile.fromString(jsonEncode(metadata), contentType: MediaType('application', 'json')),
      });

      final response = await dio.post(uri, data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("파일 업로드 에러: $e");
      return false;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
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
            child: Text(_formatDuration(_recordedDuration), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.brown)),
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

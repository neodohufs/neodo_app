import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import '../script/coaching_script_feedback.dart';
import '../get_access_token.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../home.dart';

class RecordingMetaDataPage extends StatefulWidget {
  final String filePath;
  const RecordingMetaDataPage({super.key, required this.filePath});

  @override
  _RecordingMetaDataPageState createState() => _RecordingMetaDataPageState();
}

class _RecordingMetaDataPageState extends State<RecordingMetaDataPage> {
  String _selectedAtmosphere = '';
  String _selectedPurpose = '';
  String _selectedScale = '';
  String _selectedAudience = '';
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

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

  Future<void> _submitAll() async {
    if (_selectedAtmosphere.isEmpty ||
        _selectedPurpose.isEmpty ||
        _selectedScale.isEmpty ||
        _selectedAudience.isEmpty ||
        _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    final token = await getAccessToken();
    final uri = 'https://dfd7-119-197-110-182.ngrok-free.app/api/speech-boards/record';

    final file = File(widget.filePath);
    final dio = Dio();
    String title = _titleController.text;
    dio.options.headers['Authorization'] = 'Bearer $token';

    final metadata = {
      "atmosphere": koreanToEnglish[_selectedAtmosphere],
      "purpose": koreanToEnglish[_selectedPurpose],
      "scale": koreanToEnglish[_selectedScale],
      "audience": koreanToEnglish[_selectedAudience],
      "deadline": _deadlineController.text.isNotEmpty
          ? int.parse(_deadlineController.text)
          : 0,
    };

    try {
      final formData = FormData.fromMap({
        "record": await MultipartFile.fromFile(
          file.path,
          filename: '$title.m4a',
          contentType: MediaType("audio", "mp4"), // 또는 aac
        ),
        "request": MultipartFile.fromString(
          jsonEncode(metadata),
          contentType: MediaType("application", "json"),
        ),
      });

      final response = await dio.post(uri, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("meta data 넘기기 성공");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      } else {
        _showErrorDialog("전송 실패: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("서버 요청 실패: $e");
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오류'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text("메타정보 입력", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('📄 제목', _titleController, hint: "제목을 입력하세요"),
            _buildDropdown('📌 분위기', ['공식적', '비공식적'], _selectedAtmosphere,
                    (val) => setState(() => _selectedAtmosphere = val)),
            _buildDropdown('🎯 목적', ['정보 전달', '보고', '설득', '토론'],
                _selectedPurpose, (val) => setState(() => _selectedPurpose = val)),
            _buildDropdown('👥 규모', ['소규모 (~10명)', '중규모 (~50명)', '대규모 (50명 이상)'],
                _selectedScale, (val) => setState(() => _selectedScale = val)),
            _buildDropdown('🎓 청중 수준', ['일반 대중', '관련 지식 보유자', '전문가'],
                _selectedAudience, (val) => setState(() => _selectedAudience = val)),
            _buildTextField('⏳ 제한 시간 (선택)', _deadlineController, hint: "시간을 입력하세요 (예: 30)", isNumber: true),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("완료"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selected, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.brown.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: selected.isEmpty ? null : selected,
              hint: const Text("선택하세요"),
              isExpanded: true,
              underline: const SizedBox(),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => onChanged(val!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String hint = '', bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.brown.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.brown),
              ),
            ),
            cursorColor: Colors.brown,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:neodo/recording.dart';
import 'package:neodo/speech_board.dart';
import 'dart:convert';
import 'dart:async';
import 'coaching_plan.dart';
import 'login.dart';
import 'user.dart';
import 'apiService.dart';
import 'get_access_token.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
  GlobalKey<ScaffoldState>(); // GlobalKey 추가
  User? user;
  postFile(File file, String atmosphere, String purpose, String scale, String audience, int deadline, String title) async {
    final uri = 'https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/record';

    // SharedPreferences에서 accessToken 가져오기
    final token = await getAccessToken();

    var dio = Dio();

    // Authorization 헤더 추가
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
      print("토큰 전송 완료 $token");
    } else {
      print("토큰에 아무것도 안 담김");
    }

    // JSON 데이터 생성
    Map<String, dynamic> metadata = {
      "atmosphere": atmosphere,
      "purpose": purpose,
      "scale": scale,
      "audience": audience,
      "deadline": deadline
    };

    try {
      // FormData 구성 (파일 + JSON)
      FormData formData = FormData.fromMap({
        "record": await MultipartFile.fromFile(
          file.path,
          filename: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        ),
        "request": MultipartFile.fromString(
          jsonEncode(metadata),
          contentType: MediaType.parse('application/json'),
        ),
      });

      var response = await dio.post(
        uri,
        data: formData,
      );
      print("업로드 응답: ${response.data}");
    } catch (eee) {
      print("파일 업로드에서 에러: $eee");
    }
  }


  // 🔹 파일 선택 및 업로드 실행 함수
  Future<void> pickAndUploadAudio(BuildContext context) async {

    FilePickerResult? result =
    await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      File file = File(result.files.single.path!);
      print('📂 선택된 파일 경로: ${file.path}');
      _showCompletionDialog(file);

    } else {
      print("파일 선택이 취소되었습니다.");
    }
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

  String _selectedAtmosphere = ''; // 분위기
  String _selectedPurpose = ''; // 목적
  String _selectedScale = ''; // 규모
  String _selectedAudience = ''; // 청중 수준
  TextEditingController _timeLimitController =
  TextEditingController(); // 제한 시간 입력
  TextEditingController _titleController = TextEditingController();

  void _showCompletionDialog(File file) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            title: Column(
              children: [
                Container(
                  height: 5,
                  width: double.infinity,
                  color: Colors.black, // 상단 강조선
                ),
                SizedBox(height: 10),
                Text('발표 종류',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
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
                    _buildDropdown(
                        '📌 분위기', ['공식적', '비공식적'], _selectedAtmosphere,
                            (val) {
                          setState(() => _selectedAtmosphere = val);
                        }),
                    _buildDropdown(
                        '🎯 목적', ['정보 전달', '보고', '설득', '토론'], _selectedPurpose,
                            (val) {
                          setState(() => _selectedPurpose = val);
                        }),
                    _buildDropdown(
                        '👥 규모',
                        ['소규모 (~10명)', '중규모 (~50명)', '대규모 (50명 이상)'],
                        _selectedScale, (val) {
                      setState(() => _selectedScale = val);
                    }),
                    _buildDropdown('🎓 청중 수준', ['일반 대중', '관련 지식 보유자', '전문가'],
                        _selectedAudience, (val) {
                          setState(() => _selectedAudience = val);
                        }),
                    _buildTextField('⏳ 제한 시간 (선택)', _timeLimitController),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  if (_selectedAtmosphere.isNotEmpty &&
                      _selectedPurpose.isNotEmpty &&
                      _selectedScale.isNotEmpty &&
                      _selectedAudience.isNotEmpty) {
                    String atmosphereEng = koreanToEnglish[_selectedAtmosphere] ?? _selectedAtmosphere;
                    String purposeEng = koreanToEnglish[_selectedPurpose] ?? _selectedPurpose;
                    String scaleEng = koreanToEnglish[_selectedScale] ?? _selectedScale;
                    String audienceEng = koreanToEnglish[_selectedAudience] ?? _selectedAudience;

                    await postFile(
                      file,
                      atmosphereEng,
                      purposeEng,
                      scaleEng,
                      audienceEng,
                      _timeLimitController.text.isNotEmpty
                          ? int.parse(_timeLimitController.text)
                          : 0,
                      _titleController.text,
                    );

                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                            (Route<dynamic> route) => false, // 모든 기존 페이지 제거
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('모든 항목을 선택해주세요.')),
                    );
                  }
                },
                child: Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

// 🔹 공통 드롭다운 위젯
  Widget _buildDropdown(String title, List<String> items, String selectedValue,
      Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selectedValue.isEmpty ? null : selectedValue,
          hint: Text('선택하세요'),
          isExpanded: true,
          alignment: Alignment.center,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, textAlign: TextAlign.center),
            );
          }).toList(),
          onChanged: (newValue) => onChanged(newValue!),
        ),
        SizedBox(height: 10),
      ],
    );
  }

// 🔹 공통 텍스트 필드 위젯
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

  // 녹음 완료 후 카테고리와 함께 처리하는 함수
  void _completeRecording(File file, String atmosphere, String purpose, String scale, String audience, int deadline) {
    String title = _titleController.text;

    // 선택된 카테고리와 함께 녹음을 완료하는 처리
    print('제목: $title');
    print('분위기: $_selectedAtmosphere');
    print('목적: $_selectedPurpose');
    print('규모: $_selectedScale');
    print('청중 수준: $_selectedAudience');
    print('제한 시간: $deadline');
    print('파일: $file');
  }
  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    ApiService apiService = ApiService();
    User? fetchedUser = await apiService.getUserInfo();
    if (fetchedUser != null) {
      setState(() {
        user = fetchedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text(
          'Donut',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.brown),
                accountName: Text(
                  user?.username ?? 'Loading...',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  user?.email ?? "No Email",
                  style: TextStyle(fontSize: 16),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.brown),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.brown),
                      title: Text('로그아웃'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButtonWithLabel(
                  context,
                  icon: Icons.person,
                  label: "스피치 보드",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SpeechBoardPage()),
                    );
                  },
                ),
                _buildButtonWithLabel(
                  context,
                  icon: Icons.assignment,
                  label: "스피치 코칭",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CoachingPlanPage()),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButtonWithLabel(
                  context,
                  icon: Icons.upload,
                  label: "업로드",
                  onPressed: () {
                    pickAndUploadAudio(context);
                  },
                ),
                _buildButtonWithLabel(
                  context,
                  icon: Icons.mic,
                  label: "녹음",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RecordingPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonWithLabel(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onPressed}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(150, 100),
            backgroundColor: Colors.brown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onPressed,
          child: Icon(
            icon,
            size: 60,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ],
    );
  }
}
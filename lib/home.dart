import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:neodo/profile.dart';
import 'package:neodo/record/recording.dart';
import 'package:neodo/speech_board/speech_board.dart';
import 'dart:convert';
import 'dart:async';
import 'coaching_plan/coaching_plan.dart';
import 'list.dart';
import 'login.dart';
import 'meta_data/recording_meta_data.dart';
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
    final uri = 'http://3.34.1.102:8080/api/speech-boards/record';

    // SharedPreferences에서 accessToken 가져오기
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    var dio = Dio();

    // Authorization 헤더 추가
    if (accessToken != null) {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
      dio.options.headers['Set-Cookie'] = 'Bearer $refreshToken';
      print("토큰 전송 완료 $accessToken");
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
          filename: '$title.m4a',
          contentType: MediaType("audio", "mp4"), // 또는 aac
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RecordingMetaDataPage(filePath: file.path),
        ),
      );

    } else {
      print("파일 선택이 취소되었습니다.");
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // 현재 선택된 탭 (예: 목록이 1번째 인덱스일 경우)
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()), // 홈 페이지로 이동
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SpeechMenuPage()), // 목록 페이지
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()), // 프로필 페이지
            );
          }
        },
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
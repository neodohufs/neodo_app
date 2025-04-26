import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
//import 'audio_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
//import 'speech_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'user.dart';
import 'apiService.dart';
import 'dart:developer';
import 'get_access_token.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioProvider()), // AudioProvider 추가
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Donut',
          style: TextStyle(color: Colors.lightBlue),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(), // 여기에 실제 LoginPage 넣기
                ),
              );
            },
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Center(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 24, color: Colors.black),
            children: [
              TextSpan(
                text: '도',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                  fontSize: 30,
                ),
              ),
              const TextSpan(text: '와줄게 '),
              TextSpan(
                text: '너',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                  fontSize: 30,
                ),
              ),
              const TextSpan(text: '의 '),
              TextSpan(
                text: '스',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                  fontSize: 30,
                ),
              ),
              const TextSpan(text: '피치'),
            ],
          ),
        ),
      ),
    );
  }
}



class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "Donut",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                ),
              ),
            ),
            SizedBox(height: 32),

            // Email Field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.lightBlue), // 라벨 텍스트 색상
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue), // 포커스 시 테두리 색
                ),
                prefixIcon: Icon(Icons.email, color: Colors.lightBlue), // 아이콘 색상
              ),
              cursorColor: Colors.lightBlue, // 커서 색상
            ),

            SizedBox(height: 16),

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.lightBlue), // 라벨 텍스트 색상
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightBlue), // 포커스 시 테두리 색
                ),
                prefixIcon: Icon(Icons.lock, color: Colors.lightBlue), // 아이콘 색상
              ),
              cursorColor: Colors.lightBlue, // 커서 색상
            ),

            SizedBox(height: 32),

            // Login Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("Log In", style: TextStyle(fontSize: 18, color: Colors.lightBlue)),
              onPressed: () {
                login(context);
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => HomePage()),
                );*/
              },
            ),

            SizedBox(height: 32),

            // Sign Up Button
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: Text(
                  "회원가입",
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://1d93-203-234-105-223.ngrok-free.app/api/users/login'), // ✅ 실제 API 주소
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        print("로그인 성공함티비, 이메일 : ${emailController.text}, ${passwordController.text}");
        String? accessToken = response.headers['authorization'] ?? response.headers['Authorization'];
        //accessToken 대신 사용
        if (accessToken != null && accessToken.startsWith('Bearer ')) {
          accessToken = accessToken.substring(7); // 'Bearer ' 제거
        }
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', accessToken);
          print("로그인 토큰 넣기 성공ㅎㅎ, $accessToken");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      } else {
        _showErrorDialog(context, '로그인 실패: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog(context, '서버 요청 중 오류 발생: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SignUp")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "Donut",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 32),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: "UserName",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            SizedBox(height: 16),
            // Email Field
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),

            SizedBox(height: 16),

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            SizedBox(height: 32),

            // Login Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("Sign Up", style: TextStyle(fontSize: 18)),
              onPressed: () {
                signUp(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signUp(BuildContext context) async {
    final String username = usernameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/users/signup"), // 실제 API 주소 사용
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {'username': username, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        _showErrorDialog(context, '회원가입 실패: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog(context, '서버 요청 중 오류 발생: $e');
    }
  }

  Future<void> login(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://1d93-203-234-105-223.ngrok-free.app/api/users/login'), // 실제 API 주소 사용
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      } else {
        _showErrorDialog(context, '로그인 실패: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog(context, '서버 요청 중 오류 발생: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}
/*
class GlobalState with ChangeNotifier {
  static String _globalId = ""; // 전역 id 변수

  // 전역 id 값을 가져오는 getter
  static String get globalId => _globalId;

  // 전역 id 값을 설정하는 setter
  static void setGlobalId(String id) {
    _globalId = id;
    //notifyListeners(); // id 값 변경 시 리스너들에게 알림
  }
}
*/
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // GlobalKey 추가
  User? user;
  // 🔹 파일 업로드 함수 (서버와 동기화)
  /*Future<void> uploadAudioFile(File audioFile) async {
    final uri = Uri.parse(
        'https://ed8b-203-232-234-11.ngrok-free.app/api/speech-boards/record');

    var request = http.MultipartRequest('POST', uri);

    // SharedPreferences에서 accessToken 가져오기
    final token = await getAccessToken();

    // 헤더에 accessToken 추가
    if (token != null) {
      request.headers['Authorization'] =
          'Bearer $token';
    } else {
      print("토큰에 아무것도 안 담김");
    }

    // 오디오 파일을 서버에 첨부
    request.files.add(
      await http.MultipartFile.fromPath(
        'record',
        audioFile.path,
        contentType: MediaType('audio', 'm4a'),
      ),
    );
    _showCompletionDialog(audioFile.path);

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print('✅ 파일 업로드 성공');

        // JSON 응답 받기
        String responseBody = await response.stream.bytesToString();
        Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // 파일이 업로드된 후 서버에서 최신 데이터 가져오기
        if (context.mounted) {
          await Provider.of<AudioProvider>(context, listen: false)
              .fetchAudioFiles();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('파일 업로드 완료: ${jsonResponse["title"]}')),
        );
      } else {
        print('파일 업로드 실패: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('업로드 중 오류 발생: $e');
    }
  }*/
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

  // 데이터를 받아오는 함수
  Future<void> _fetchUserInfo() async {
    ApiService apiService = ApiService();
    User? fetchedUser = await apiService.getUserInfo();

    if (fetchedUser != null) {
      setState(() {
        user = fetchedUser; // 받아온 데이터를 state에 저장
      });
    }
  }
  //마이페이지
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Scaffold에 GlobalKey 추가
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Donut'),
        centerTitle: true,
        automaticallyImplyLeading: false, // 기본 back 버튼 숨기기
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Drawer 열기
            _scaffoldKey.currentState?.openDrawer(); // _scaffoldKey로 Drawer 열기
          },
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // 사용자 정보 영역
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.lightBlue),
                accountName: Text(
                  user?.username ?? 'Loading...', // 실제 사용자 이름을 여기에 표시
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? "No Email", // 실제 사용자 ID를 여기에 표시
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.lightBlue,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    // 로그아웃 버튼
                    ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('로그아웃'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                    ),
                    // 필요한 경우 여기에 더 많은 ListTile을 추가할 수 있습니다.
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
                      MaterialPageRoute(
                        builder: (_) => SpeechBoardPage(),
                      ),
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
                      MaterialPageRoute(
                        builder: (_) => CoachingPlanPage(),
                      ),
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
                      MaterialPageRoute(
                        builder: (_) => RecordingPage(),
                      ),
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
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.amber,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Icon(
            icon,
            size: 80,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8), // 버튼과 텍스트 간 간격
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
//스피치 보드
class SpeechBoardPage extends StatefulWidget {
  @override
  _SpeechBoardPageState createState() => _SpeechBoardPageState();
}

class _SpeechBoardPageState extends State<SpeechBoardPage> {
  late Future<void> _fetchAudioFuture;

  @override
  void initState() {
    super.initState();
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _fetchAudioFuture = audioProvider.fetchAudioFiles(); // ID 전달
  }

  Future<void> _refreshAudioFiles() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    await audioProvider.fetchAudioFiles();  // 데이터 새로 고침
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('스피치 보드')),
      body: FutureBuilder<void>(
        future: _fetchAudioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // 로딩 중
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다. 다시 시도해주세요.'));
          }

          if (audioProvider.audioList.isEmpty) {
            return Center(child: Text('오디오 파일이 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshAudioFiles, // 스와이프하여 새로고침
            child: ListView.builder(
              itemCount: audioProvider.audioList.length,
              itemBuilder: (context, index) {
                final file = audioProvider.audioList[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.mic, color: Colors.white),
                      ),
                      title: Text(
                        file.title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        '생성 날짜: ${file.createdAt}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackPage(speechBoardId: file.id), //id 넘김
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        onTap: (index) {
          // 네비게이션 로직 추가 가능
        },
      ),
    );
  }
}


class AudioProvider with ChangeNotifier {
  List<Audio> _audioList = [];
  bool _isLoading = false;

  List<Audio> get audioList => _audioList;
  bool get isLoading => _isLoading;

  Future<void> fetchAudioFiles() async {
    final url = 'https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards';

    final token = await getAccessToken();

    if (token == null) {
      print('Access Token이 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners(); // UI 갱신

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token', // Access Token 추가
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        print("스피치보드 오디오목록 데이터 불러오기 성공");
        if (responseBody.containsKey('data')) {
          List<dynamic> audioData = responseBody['data']; // 리스트 가져오기
          _audioList = audioData.map((item) => Audio.fromJson(item)).toList();
          notifyListeners();
        }
      } else {
        throw Exception('Failed to load audios: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('오디오 목록 불러오기 실패: $error');
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 완료 알림
    }
  }

}

class Audio {
  final int id;
  final int userId;
  final String title;
  final String createdAt;

  Audio(
      {required this.id,
      required this.userId,
      required this.title,
      required this.createdAt});

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      createdAt: json['createdAt'],
    );
  }
}

class FeedbackPage extends StatefulWidget {
  final int speechBoardId; // speech_board_id를 받음

  const FeedbackPage(
      {super.key, required this.speechBoardId});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String originalStt = "";
  String conclusion = "";
  bool isLoading = true; // 데이터 로딩 상태
  int score = 0;
  List<String> topics = [];

  @override
  void initState() {
    super.initState();
    fetchTextAndFeedback(widget.speechBoardId); // 변환된 텍스트 & 피드백 가져오기

    // 오디오 재생 상태 설정
    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => duration = d);
    });

    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => position = p);
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if(mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      }
    });
  }

  // 변환된 텍스트와 피드백 가져오기
  Future<void> fetchTextAndFeedback(int speechBoardId) async {
    try {
      final accessToken = await getAccessToken();
      final dio = Dio();
      final response = await http.get(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/$speechBoardId/feedback"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // GET 요청에 Authorization 헤더 추가
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          originalStt = data['data']['originalStt'] ?? "";
          score = data['data']['score'] ?? 0;
          conclusion = data['data']['conclusion'] ?? "";
          topics = List<String>.from(data['data']['topics'] ?? []);
          isLoading = false;
        });
      } else {
        print("스피치 보드 데이터 가져오기 실패");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("오류 발생: $e");
      setState(() => isLoading = false);
    }
  }

  // 오디오 재생
  Future<void> playAudio(int speechBoardId) async {
    try {
      final accessToken = await getAccessToken();
      // 백엔드에서 GET 요청으로 record 데이터 받아오기
      final response = await http.get(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/$speechBoardId/record"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // GET 요청에 Authorization 헤더 추가
        },
      );

      if (response.statusCode == 200) {
        print("스피치 보드 오디오 데이터 받기 완료");
        final data = json.decode(response.body);
        final audioPath = data['data']; // 백엔드에서 반환하는 오디오 경로를 받음
        String audioRecord = audioPath['record'];
        // audioPlayer에 오디오 경로 설정
        await audioPlayer.stop();
        await audioPlayer.setSourceUrl(audioRecord);
        await audioPlayer.resume();

        setState(() {
          isPlaying = true; //true가 맞나?
        });
      } else {
        print("오디오 경로를 가져오는 데 실패했습니다.");
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
    }
  }


  // 시간 포맷 변환 함수
  String formatTime(Duration duration) {
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override //Stack의 position을 사용해서 녹음재생바 화면아래에 고정, 스크롤
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스피치 피드백'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.search),
            onSelected: (value) {
              print("$value 선택");
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: '제목 수정', child: Text("제목 수정")),
                PopupMenuItem(value: '텍스트 수정', child: Text("텍스트 수정")),
              ];
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // 데이터 로딩 중
                : SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 80), // 오디오 컨트롤러 공간 확보
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("점수 : $score",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),

                  // 변환된 텍스트
                  Text("변환된 텍스트",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(originalStt, style: TextStyle(fontSize: 16)),
                  ),

                  SizedBox(height: 16),

                  // 피드백
                  Text("피드백",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(conclusion, style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 16), // 수정
                ],
              ),
            ),
          ),

          // 오디오 컨트롤러를 화면 하단에 고정
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await audioPlayer.seek(newPosition);
                      setState(() => position = newPosition);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(formatTime(position)),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          if (isPlaying) {
                            await audioPlayer.pause();
                          } else {
                            if (duration == Duration.zero) {
                              await playAudio(widget.speechBoardId);
                            } else {
                              await audioPlayer.resume();
                            }
                          }
                          setState(() => isPlaying = !isPlaying);
                        },
                      ),
                      Text(formatTime(duration)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/*
class FeedbackPage extends StatefulWidget {
  final String playAudioPath;
  const FeedbackPage({super.key, required this.playAudioPath});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String? currentAudioUrl;
  List<String> audioUrls = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAudioUrls();

    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => duration = d);
    });

    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => position = p);
    });

    audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  // 백엔드에서 오디오 URL 리스트 가져오기
  Future<void> fetchAudioUrls() async {
    try {
      final response = await http.get(Uri.parse(
          "https://ed8b-203-232-234-11.ngrok-free.app/api/speech-boards"));
      if (response.statusCode == 200) {
        setState(() {
          audioUrls = List<String>.from(json.decode(response.body));
          isLoading = false;
        });
      } else {
        print("오디오 리스트 가져오기 실패");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("오류 발생: $e");
      setState(() => isLoading = false);
    }
  }

  // 오디오 재생 함수
  Future<void> playAudio(String url) async {
    try {
      await audioPlayer.stop();
      await audioPlayer.setSourceUrl(url);
      await audioPlayer.resume();
      setState(() {
        currentAudioUrl = url;
        isPlaying = true;
      });
    } catch (e) {
      print("오디오 재생 오류: $e");
    }
  }

  // 시간 포맷 변환 함수
  String formatTime(Duration duration) {
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('오디오 리스트')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : audioUrls.isEmpty
              ? Center(child: Text('오디오 파일이 없습니다.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: audioUrls.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text("Audio ${index + 1}"),
                            tileColor: currentAudioUrl == audioUrls[index]
                                ? Colors.grey[300]
                                : null, // 선택한 오디오 강조
                            onTap: () => playAudio(audioUrls[index]),
                          );
                        },
                      ),
                    ),
                    if (currentAudioUrl != null)
                      Column(
                        children: [
                          Slider(
                            min: 0,
                            max: duration.inSeconds.toDouble(),
                            value: position.inSeconds.toDouble(),
                            onChanged: (value) async {
                              final newPosition =
                                  Duration(seconds: value.toInt());
                              await audioPlayer.seek(newPosition);
                              setState(() => position = newPosition);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(formatTime(position)),
                              IconButton(
                                icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow),
                                onPressed: () async {
                                  if (isPlaying) {
                                    await audioPlayer.pause();
                                  } else {
                                    await audioPlayer.resume();
                                  }
                                  setState(() => isPlaying = !isPlaying);
                                },
                              ),
                              Text(formatTime(duration)),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
    );
  }
}
*/

class CoachingPlanPage extends StatefulWidget {
  @override
  _CoachingPlanPage createState() => _CoachingPlanPage();
}

class _CoachingPlanPage extends State<CoachingPlanPage> {
  List fetchData = [];
  List<Map<String, dynamic>> topicList = [];

  void selectedTopic(BuildContext context, List<Map<String, dynamic>> threeTopics) { //3개 토픽중 한개 선택
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Text("토픽 선택", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...threeTopics.map((topicIdAndTopic) => ListTile(
                title: Text(topicIdAndTopic['topic']),
                onTap: () {
                  print(threeTopics);
                  int? selectedCoachingId = topicIdAndTopic['speechCoachingId']; //선택한 토픽의 speechCoachingId
                  _navigateToRecording(topicIdAndTopic['topicId'], selectedCoachingId);
                },
              )),
            ],
          ),
        );
      },
    ).then((selectedTopic) {
      if (selectedTopic != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("선택한 토픽: $selectedTopic"),
        ));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    final accessToken = await getAccessToken();
    final response = await http.get(
      Uri.parse("https://1d93-203-234-105-223.ngrok-free.app/api/speech-coachings"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        fetchData = jsonResponse['data'];  // 🔥 여기 수정!
      });
      print(fetchData);
    } else {
      throw Exception('Failed to load topics');
    }
  }

  // topicId를 전달하는 함수
  void _navigateToRecording(int selectedTopicId, int? speechCoachingId) {
    if(speechCoachingId == null){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => minRecordingPage(topicId: selectedTopicId),
        ),
      );
    }
    else{
      int speechCoachingIdInt = speechCoachingId;
      Navigator.pushReplacement(
        context,
          MaterialPageRoute(
              builder: (context)=> CoachingFeedbackPage(speechCoachingId: speechCoachingIdInt),
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('스피치 코칭')),
        floatingActionButton: Container(
          margin: EdgeInsets.only(bottom: 20, right: 20),
          width: 70, // 원하는 크기로 설정
          height: 70,
          decoration: BoxDecoration(
            color: Colors.lightBlue,
            shape: BoxShape.circle, // 둥근 버튼 모양 유지
          ),
          child: RawMaterialButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => CoachingScriptWritePage(),
              ));
            },
            shape: CircleBorder(),
            child: Icon(Icons.add, size: 40, color: Colors.white), // 아이콘 크기도 조절 가능
          ),
        ),
        body: Padding(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView( //스크롤
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스피치 코칭',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                '3분 스피치',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              fetchData == null
                ? Center(child: CircularProgressIndicator())
                : fetchData.isEmpty
                  ? Center(
                    child: Text(
                      "데이터 없음",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    textAlign: TextAlign.center,
                    )
                  )
                  : ListView.builder(
                      shrinkWrap: true, //추가
                      physics: NeverScrollableScrollPhysics(), //추가 => ListView.builder와의 충돌을 막기 위함
                      itemCount: fetchData.length,
                    itemBuilder: (context, index) {
                      // 각 speechBoardId에 대한 topic 데이터를 추출 (전역 topicList 사용 X)
                      List<Map<String, dynamic>> topicList = List<Map<String, dynamic>>.from(fetchData[index]['topics']);

                      return GestureDetector(
                        onTap: () {
                          selectedTopic(context, topicList);
                          /*int selectedTopicId = topicList.isNotEmpty ? topicList[0]['topicId'] : -1;  // 안전하게 처리
                          int selectedCoachingId = topicList.isNotEmpty ? topicList[0]['speechCoachingId'] : -1;
                          print(jsonEncode(topicList));
                          _navigateToRecording(selectedTopicId, selectedCoachingId); // topicId 전달
                          print("topicID : ${selectedTopicId}");
                           */
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '신규 스피치 ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: topicList.map((topic) => Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          topic['topic'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),  // topic 사이 공백 추가
                                    ],
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        )
      ),
    );
  }
}

class CoachingScriptWritePage extends StatefulWidget {
  @override
  _CoachingScriptPageState createState() => _CoachingScriptPageState();
}

class _CoachingScriptPageState extends State<CoachingScriptWritePage> {
  TextEditingController _controller = TextEditingController();

  void _submitScript() {
    final scriptText = _controller.text.trim();

    if (scriptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대본을 입력해주세요.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MetadataSelectionPage(script: scriptText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('스피치 대본')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                maxLines: 25,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                enableIMEPersonalizedLearning: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "스피치 대본을 입력하세요",
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => CoachingPlanPage()),
                        );
                      },
                      child: Text("취소"),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _submitScript,
                      child: Text("완료"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetadataSelectionPage extends StatefulWidget {
  final String script;
  MetadataSelectionPage({required this.script});

  @override
  _MetadataSelectionPageState createState() => _MetadataSelectionPageState();
}

class _MetadataSelectionPageState extends State<MetadataSelectionPage> {
  String _selectedAtmosphere = '';
  String _selectedPurpose = '';
  String _selectedScale = '';
  String _selectedAudience = '';
  TextEditingController _deadlineController = TextEditingController();

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
        _selectedAudience.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('모든 항목을 선택해주세요.')));
      return;
    }

    final token = await getAccessToken();
    final uri = Uri.parse('https://1d93-203-234-105-223.ngrok-free.app/api/scripts'); // ✅ 서버 주소

    final body = {
      "atmosphere": koreanToEnglish[_selectedAtmosphere],
      "purpose": koreanToEnglish[_selectedPurpose],
      "scale": koreanToEnglish[_selectedScale],
      "audience": koreanToEnglish[_selectedAudience],
      "deadline": _deadlineController.text.isNotEmpty
          ? int.parse(_deadlineController.text)
          : 0,
      "script": widget.script,
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CoachingScriptFeedbackPage()),
        );
      } else {
        _showErrorDialog('전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('서버 요청 실패');
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('오류'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("메타정보 입력")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDropdown('📌 분위기', ['공식적', '비공식적'], _selectedAtmosphere,
                    (val) => setState(() => _selectedAtmosphere = val)),
            _buildDropdown('🎯 목적', ['정보 전달', '보고', '설득', '토론'],
                _selectedPurpose, (val) => setState(() => _selectedPurpose = val)),
            _buildDropdown(
                '👥 규모',
                ['소규모 (~10명)', '중규모 (~50명)', '대규모 (50명 이상)'],
                _selectedScale,
                    (val) => setState(() => _selectedScale = val)),
            _buildDropdown(
                '🎓 청중 수준',
                ['일반 대중', '관련 지식 보유자', '전문가'],
                _selectedAudience,
                    (val) => setState(() => _selectedAudience = val)),
            _buildTextField('⏳ 제한 시간 (선택)', _deadlineController),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _submitAll, child: Text("완료"))
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, List<String> items, String selected, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selected.isEmpty ? null : selected,
          hint: Text("선택하세요"),
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => onChanged(val!),
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
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              border: OutlineInputBorder(), hintText: "시간을 입력하세요 (예: 30)"),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}


class CoachingScriptFeedbackPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('CoachingScriptFeedbackPage 페이지'), // 빈 화면 (텍스트 없음)
        ),
      ),
    );
  }
}
/*class CoachingScriptFeedbackPage extends StatefulWidget {
  @override
  _CoachingScriptFeedPageState createState() => _CoachingScriptFeedPageState();
}

class _CoachingScriptFeedPageState extends State<CoachingScriptFeedbackPage>{
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String originalStt = "";
  String conclusion = "";
  bool isLoading = true; // 데이터 로딩 상태
  int score = 0;
  List<String> topics = [];

  @override
  void initState() {
    super.initState();
    fetchTextAndFeedback(widget.scriptId); // 변환된 텍스트 & 피드백 가져오기

    // 오디오 재생 상태 설정
    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => duration = d);
    });

    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => position = p);
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if(mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      }
    });
  }

  // 변환된 텍스트와 피드백 가져오기
  Future<void> fetchTextAndFeedback(int speechBoardId) async {
    try {
      final accessToken = await getAccessToken();
      final dio = Dio();
      final response = await http.get(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/$speechBoardId/feedback"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // GET 요청에 Authorization 헤더 추가
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          originalStt = data['data']['originalStt'] ?? "";
          score = data['data']['score'] ?? 0;
          conclusion = data['data']['conclusion'] ?? "";
          topics = List<String>.from(data['data']['topics'] ?? []);
          isLoading = false;
        });
      } else {
        print("스피치 보드 데이터 가져오기 실패");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("오류 발생: $e");
      setState(() => isLoading = false);
    }
  }

  // 오디오 재생
  Future<void> playAudio(int speechBoardId) async {
    try {
      final accessToken = await getAccessToken();
      // 백엔드에서 GET 요청으로 record 데이터 받아오기
      final response = await http.get(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/$speechBoardId/record"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // GET 요청에 Authorization 헤더 추가
        },
      );

      if (response.statusCode == 200) {
        print("스피치 보드 오디오 데이터 받기 완료");
        final data = json.decode(response.body);
        final audioPath = data['data']; // 백엔드에서 반환하는 오디오 경로를 받음
        String audioRecord = audioPath['record'];
        // audioPlayer에 오디오 경로 설정
        await audioPlayer.stop();
        await audioPlayer.setSourceUrl(audioRecord);
        await audioPlayer.resume();

        setState(() {
          isPlaying = true; //true가 맞나?
        });
      } else {
        print("오디오 경로를 가져오는 데 실패했습니다.");
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
    }
  }


  // 시간 포맷 변환 함수
  String formatTime(Duration duration) {
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override //Stack의 position을 사용해서 녹음재생바 화면아래에 고정, 스크롤
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스피치 피드백'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.search),
            onSelected: (value) {
              print("$value 선택");
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: '제목 수정', child: Text("제목 수정")),
                PopupMenuItem(value: '텍스트 수정', child: Text("텍스트 수정")),
              ];
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // 데이터 로딩 중
                : SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 80), // 오디오 컨트롤러 공간 확보
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("점수 : $score",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),

                  // 변환된 텍스트
                  Text("변환된 텍스트",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(originalStt, style: TextStyle(fontSize: 16)),
                  ),

                  SizedBox(height: 16),

                  // 피드백
                  Text("피드백",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(conclusion, style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 16), // 수정
                ],
              ),
            ),
          ),

          // 오디오 컨트롤러를 화면 하단에 고정
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await audioPlayer.seek(newPosition);
                      setState(() => position = newPosition);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(formatTime(position)),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          if (isPlaying) {
                            await audioPlayer.pause();
                          } else {
                            if (duration == Duration.zero) {
                              await playAudio(widget.scriptId);
                            } else {
                              await audioPlayer.resume();
                            }
                          }
                          setState(() => isPlaying = !isPlaying);
                        },
                      ),
                      Text(formatTime(duration)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
 */

//녹음 기능 구현, 녹음 페이지
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

    // 마이크 권한 요청
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

  Future<void> requestStoragePermission() async {
    var status = await Permission.storage.status;

    if (!status.isGranted) {
      // 권한 요청
      await Permission.storage.request();
    }
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
    print(_filePath);

    setState(() {
      _isRecording = true;
      _recordedDuration = Duration.zero;
    });

    await _recorder!
        .startRecorder(toFile: _filePath, codec: sound.Codec.aacMP4);

    // 타이머 시작 (1초마다 업데이트)
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
      // await _recorder!.stopRecorder();
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        // File 객체 생성
        File recordedFile = File(path);
        print("녹음 파일 경로 : ${recordedFile.path}");

        _showCompletionDialog(recordedFile);
    }

    /*
    // 녹음 완료 후 경로 받아오기
    final path = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      // File 객체 생성
      File recordedFile = File(path);
      print("녹음 파일 경로 : ${recordedFile.path}");*/

      // 파일 로컬 저장
     /* String savedFilePath = await saveRecordingLocally(path);  // 변환된 경로를 저장
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('녹음 저장 완료: $savedFilePath')),
      );
*/
      // 다이얼로그 표시 (File 객체 전달)
      //_showCompletionDialog(recordedFile);
    }
  }

  /*Future<String> saveRecordingLocally(String path) async {
    try {
      final audioFile = File(path);
      if (!audioFile.existsSync()) return 'File does not exist';

      final directory = await getExternalStorageDirectory();
      final newDir = Directory(p.join(directory.path, 'recordings'));
      if (!await newDir.exists()) await newDir.create(recursive: true);

      final newFile = File(p.join(
          newDir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a'));
      await audioFile.copy(newFile.path);

      final token = await getAccessToken();
      if (token == null) {
        return 'JWT Token is missing';
      }

      return newFile.path;
    } catch (e) {
      print('녹음 저장 중 오류 발생: $e');
      return 'Error: $e';
    }
  }
   */

  Future<void> _stopRecordingGoHome() async {
    if (_recorder != null) {
      if (_isRecording) { // 현재 녹음 중이라면
        await _recorder!.stopRecorder();
        setState(() {
          _isRecording = false;
        });
        print("녹음 중단 및 메인 페이지로 이동");
        // 메인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // HomePage()는 실제 메인 페이지 위젯
        );
      } else { // 이미 녹음이 멈춰있다면
        print("이미 녹음이 멈춰있음. 메인 페이지로 이동");
        // 메인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // HomePage()는 실제 메인 페이지 위젯
        );
      }
    } else {
      print("_recorder가 null입니다.");
      // _recorder가 초기화되지 않은 경우 처리 (선택 사항)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
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

  String _selectedAtmosphere = ''; // 분위기
  String _selectedPurpose = ''; // 목적
  String _selectedScale = ''; // 규모
  String _selectedAudience = ''; // 청중 수준
  TextEditingController _timeLimitController =
      TextEditingController(); // 제한 시간 입력
  TextEditingController _titleController = TextEditingController();

  void _showCompletionDialog(File file) {
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  _buildDropdown('📌 분위기', ['공식적', '비공식적'], _selectedAtmosphere,
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
                  String atmosphereEng = koreanToEnglish[_selectedAtmosphere] ??
                      _selectedAtmosphere;
                  String purposeEng =
                      koreanToEnglish[_selectedPurpose] ?? _selectedPurpose;
                  String scaleEng =
                      koreanToEnglish[_selectedScale] ?? _selectedScale;
                  String audienceEng =
                      koreanToEnglish[_selectedAudience] ?? _selectedAudience;
                  // uploadAudioFile 호출 시 jwtToken 전달
                  if (mounted) {
                    await postFile(
                        file,
                        atmosphereEng,
                        purposeEng,
                        scaleEng,
                        audienceEng,
                        _timeLimitController.text.isNotEmpty
                            ? int.parse(
                            _timeLimitController.text) // 🔹 String -> int 변환
                            : 0,
                        _titleController.text);
                    setState(() {
                      // 상태 업데이트 작업
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                        SnackBar(content: Text('모든 항목을 선택해주세요.')));
                  }
                }
              },
                  child: Text(
                    '확인',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold
                    ),
                  ),
                )
          ],
        );
      },
    );
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
  Future<void> postFile(
      File file,
      String atmosphere,
      String purpose,
      String scale,
      String audience,
      int deadline,
      String title,
      ) async {
    final uri = 'https://1d93-203-234-105-223.ngrok-free.app/api/speech-boards/record';

    // SharedPreferences에서 accessToken 가져오기
    final token = await getAccessToken();
    var dio = Dio();

    // Authorization 헤더 추가
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
      print("✅ 토큰 전송 완료: $token");
    } else {
      print("❌ 토큰 없음!");
    }

    // JSON 데이터 생성
    Map<String, dynamic> metadata = {
      "atmosphere": atmosphere,
      "purpose": purpose,
      "scale": scale,
      "audience": audience,
      "deadline": deadline,
    };

    try {
      // FormData 구성 (파일 + JSON)
      FormData formData = FormData.fromMap({
        "record": await MultipartFile.fromFile( // dio 패키지 사용
          file.path,
          filename: '${title}.m4a',
          contentType: MediaType('audio', 'mp4'), // .m4a 파일의 MIME 타입
        ),
        "request": MultipartFile.fromString(
          jsonEncode(metadata),
          contentType: MediaType('application', 'json'), // JSON 타입
        ),
      });
      log("postFile 파일 이름 출력", name: file.path);
      // 파일 업로드 요청
      var response = await dio.post(
        uri,
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );
      print("🎤 업로드 응답: ${response.data}");

      if (response.statusCode == 200) {
        goToHomePage(); // 업로드 성공 후 홈으로 이동
      }
    } catch (e) {
      print("❌ 파일 업로드 에러: $e");
    }
  }
// HomePage로 돌아가는 함수
  Future <void> goToHomePage() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('녹음')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formatDuration(_recordedDuration),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _stopRecordingGoHome();
                  },
                  child: Text('취소'),
                ),
                GestureDetector(
                  onTap: _pauseRecording,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.red,
                    child: Icon(_isRecording ? Icons.pause : Icons.mic,
                        color: Colors.white, size: 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: _stopRecording,
                  child: Text('완료'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class minRecordingPage extends StatefulWidget {
  final int topicId;

  minRecordingPage({required this.topicId});

  @override
  _minRecordingPageState createState() => _minRecordingPageState();
}

class _minRecordingPageState extends State<minRecordingPage> {
  sound.FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Duration _remainingDuration = Duration(minutes: 3); // 3분 카운트다운
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

  // 녹음 시작 및 카운트다운
  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = p.join(directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');

    setState(() {
      _isRecording = true;
      _remainingDuration = Duration(minutes: 3); // 초기화
    });

    await _recorder!.startRecorder(toFile: _filePath, codec: sound.Codec.aacMP4);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingDuration.inSeconds > 0) {
        setState(() {
          _remainingDuration -= Duration(seconds: 1);
        });
      } else {
        _stopRecording();
      }
    });
  }

  // 일시 정지/재개
  Future<void> _pauseRecording() async {
    if (_recorder!.isRecording) {
      await _recorder!.pauseRecorder();
      _timer?.cancel();  // ⬅️ 타이머 정지!
      setState(() {
        _isRecording = false;
      });
    } else if (_recorder!.isPaused) {
      await _recorder!.resumeRecorder();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {  // ⬅️ 타이머 재개!
        if (_remainingDuration.inSeconds > 0) {
          setState(() {
            _remainingDuration -= Duration(seconds: 1);
          });
        } else {
          _stopRecording();
        }
      });
      setState(() {
        _isRecording = true;
      });
    }
  }

  // 녹음 정지 (페이지 닫지 않음)
  Future<void> _stopRecording() async {
    if (_recorder != null && _recorder!.isRecording) {
      await _recorder!.stopRecorder();
      _timer?.cancel();
      setState(() => _isRecording = false);
    }
  }

  // 업로드 함수
  Future<void> _uploadRecording(int topicId) async {
    try {
      await _stopRecording(); // 업로드 전에 녹음 멈추기

      File file = File(_filePath);
      final token = await getAccessToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('토큰 없음'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      final url = Uri.parse('https://1655-1-230-133-117.ngrok-free.app/api/topics/$topicId/speech-coachings/record');

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'record',
          file.path,
          contentType: MediaType('audio', 'm4a'),
        ));

      var response = await request.send();

      if (response.statusCode == 201) {
        print("스피치 코칭 3분 녹음 파일 전송 완료");
        String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseJson = json.decode(responseBody);

        Map<String, dynamic> data = responseJson['data'];
        int speechCoachingId = data['speechCoachingId'];
        print("스피치코칭 아이디 : $speechCoachingId");

        // 업로드 성공 → CoachingFeedbackPage로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CoachingFeedbackPage(speechCoachingId: speechCoachingId)),
        );
      } else {
        print('코칭 업로드 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('코칭 업로드 실패: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('코칭 업로드 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('코칭 업로드 중 오류: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }


  // 시간을 "MM:SS" 형식으로 포맷
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('3분 녹음')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formatDuration(_remainingDuration),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
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
                  child: Text('취소'),
                ),
                GestureDetector(
                  onTap: _pauseRecording,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.red,
                    child: Icon(_isRecording ? Icons.pause : Icons.mic, color: Colors.white, size: 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _uploadRecording(widget.topicId);
                  },
                  child: Text('완료'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
class minRecordingPage extends StatefulWidget {
  final String topicId;

  minRecordingPage({required this.topicId});
  @override
  _minRecordingPageState createState() => _minRecordingPageState();
}

class _minRecordingPageState extends State<minRecordingPage> {
  sound.FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  Duration _remainingDuration = Duration(minutes: 3);
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
    _filePath = p.join(
        directory.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.aac');

    setState(() {
      _isRecording = true;
      _remainingDuration = Duration(minutes: 3);
    });

    await _recorder!
        .startRecorder(toFile: _filePath, codec: sound.Codec.aacMP4);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingDuration.inSeconds > 0) {
        setState(() {
          _remainingDuration -= Duration(seconds: 1);
        });
      } else {
        _stopRecording();
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
      await _recorder!.stopRecorder();
    }
    _timer?.cancel();
    setState(() => _isRecording = false);
    Navigator.pop(context);
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
      appBar: AppBar(title: Text('3분 녹음')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formatDuration(_remainingDuration),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 100.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _stopRecording();
                    Navigator.pop(context);
                  },
                  child: Text('취소'),
                ),
                GestureDetector(
                  onTap: _pauseRecording,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.red,
                    child: Icon(_isRecording ? Icons.pause : Icons.mic,
                        color: Colors.white, size: 36),
                  ),
                ),
                ElevatedButton(
                  onPressed: _stopRecording,
                  child: Text('완료'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/
class CoachingFeedbackPage extends StatefulWidget {
  final int speechCoachingId; // speech_board_id를 받음

  const CoachingFeedbackPage(
      {super.key, required this.speechCoachingId});

  @override
  State<CoachingFeedbackPage> createState() => _CoachingFeedbackPageState();
}

class _CoachingFeedbackPageState extends State<CoachingFeedbackPage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  String originalStt = "";
  String conclusion = "";
  bool isLoading = true; // 데이터 로딩 상태
  int score = 0;
  List<String> topics = [];

  @override
  void initState() {
    super.initState();
    fetchTextAndFeedback(widget.speechCoachingId); // 변환된 텍스트 & 피드백 가져오기

    // 오디오 재생 상태 설정
    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() => duration = d);
    });

    audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() => position = p);
    });

    audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  // 변환된 텍스트와 피드백 가져오기
  Future<void> fetchTextAndFeedback(int speechCoachingId) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/speech-coachings/$speechCoachingId/feedback"),
          headers: {
            'Content-Type': 'application/json',
            //'Accept': 'application/json',
            'Authorization': 'Bearer $token}'}
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body); //텍스트

        setState(() {
          originalStt = data['data']['originalStt'] ?? "";
          score = data['data']['score'] ?? 0;
          conclusion = data['data']['conclusion'] ?? "";
          isLoading = false;
        });
      } else {
        print("데이터 가져오기 실패");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("오류 발생: $e");
      setState(() => isLoading = false);
    }
  }

  // 오디오 재생
  Future<void> playAudio(int speechCoachingId) async {
    try {
      final accessToken = await getAccessToken();
      // 백엔드에서 GET 요청으로 record 데이터 받아오기
      final response = await http.get(
        Uri.parse(
            "https://1d93-203-234-105-223.ngrok-free.app/api/speech-coachings/$speechCoachingId/record"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // GET 요청에 Authorization 헤더 추가
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final audioData = data['data']; // 백엔드에서 반환하는 오디오 경로를 받음
        String audioPath = audioData['record'];
        if(audioPath == Null){
          print("스피치 코칭 음성 확인 불가능");
        }
        // audioPlayer에 오디오 경로 설정
        await audioPlayer.stop();
        await audioPlayer.setSourceUrl(audioPath);
        await audioPlayer.resume();

        setState(() {
          isPlaying = true;
        });
      } else {
        print("오디오 경로를 가져오는 데 실패했습니다.");
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
    }
  }


  // 시간 포맷 변환 함수
  String formatTime(Duration duration) {
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스피치코칭 피드백'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.search),
            onSelected: (value) {
              print("$value 선택");
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: '제목 수정', child: Text("제목 수정")),
                PopupMenuItem(value: '텍스트 수정', child: Text("텍스트 수정")),
              ];
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 80), // 오디오 컨트롤러 공간 확보
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "점수 : $score",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // 변환된 텍스트 표시
                  Text(
                    "변환된 텍스트",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(originalStt, style: TextStyle(fontSize: 16)),
                  ),

                  SizedBox(height: 16),

                  // 피드백 표시
                  Text(
                    "피드백",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(conclusion, style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),

          // 오디오 컨트롤러를 화면 하단에 고정
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await audioPlayer.seek(newPosition);
                      setState(() => position = newPosition);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(formatTime(position)),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () async {
                          if (isPlaying) {
                            await audioPlayer.pause();
                          } else {
                            if (duration == Duration.zero) {
                              await playAudio(widget.speechCoachingId);
                            } else {
                              await audioPlayer.resume();
                            }
                          }
                          setState(() => isPlaying = !isPlaying);
                        },
                      ),
                      Text(formatTime(duration)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/*
Future<void> uploadDataWithFileAndMeta(String atmosphere, String purpose, String scale, String audience, int deadline) async {
  var uri = Uri.parse(
      "https://ed8b-203-232-234-11.ngrok-free.app/api/speech-boards/record");

  var request = http.MultipartRequest('POST', uri);

  // SharedPreferences에서 accessToken 가져오기
  final token = await getAccessToken();

  // 헤더에 accessToken 추가
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  } else {
    print("토큰에 아무것도 안 담김");
  }
  // JSON 데이터 추가 (meta 정보)
  request.fields['atmosphere'] = atmosphere;
  request.fields['purpose'] = purpose;
  request.fields['scale'] = scale;
  request.fields['audience'] = audience;
  request.fields['deadline'] = deadline.toString();

  // 오디오 파일을 서버에 첨부 (record)
  request.files.add(
    await http.MultipartFile.fromPath(
      'record', // 서버에서 요구하는 필드명
      audioFile.path,
      contentType: MediaType('audio', 'm4a'),
    ),
  );

  try {
    var response = await request.send();

    if (response.statusCode == 200) {
      print('✅ 파일과 데이터 업로드 성공');

      // JSON 응답 받기
      String responseBody = await response.stream.bytesToString();
      Map<String, dynamic> jsonResponse = json.decode(responseBody);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 업로드 완료: ${jsonResponse["title"]}')),
      );
    } else {
      print('파일 업로드 실패: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('업로드 중 오류 발생: $e');
  }
}
*/

/*
//벡엔드로 메타정보 전송
Future<void> sendPresentationData(String atmosphere, String purpose,
    String scale, String audience, int deadline, ) async {
  var uri = Uri.parse(
      "https://ed8b-203-232-234-11.ngrok-free.app/api/speech-boards/record"); // JSON 데이터 전송 URL
  final token = await getAccessToken();

  var body = {
    "atmosphere": atmosphere,
    "purpose": purpose,
    "scale": scale,
    "audience": audience,
    "deadline": deadline, // 🔹 int로 보낼 경우
  };

  var response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      "Content-Type": "application/json"
    },
    body: json.encode(body), //jsonEncode
  );

  if (response.statusCode == 200) {
    debugPrint("데이터 전송 성공!");
  } else {
    debugPrint("전송 실패: ${response.statusCode}");
  }
}
*/
//백엔드에서 파일 목록 가져오기
/*Future<List<AudioFile>> fetchAudioFiles() async {
  final response = await http.get(
      Uri.parse('https://ed8b-203-232-234-11.ngrok-free.app/api/speech-boards'));
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((item) => AudioFile.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load audio files');
  }
}
*/
class AudioFile {
  final String speechBoardId;
  final String file;
  final String userId;
  final String title;
  final List<String> categories;

  AudioFile({
    required this.speechBoardId,
    required this.file,
    required this.userId,
    required this.title,
    required this.categories,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      speechBoardId: _generateSpeechBoardId(),
      file: json['file'],
      userId: json['userId'],
      title: json['title'],
      categories: List<String>.from(json['category']),
    );
  }

  static String _generateSpeechBoardId() {
    var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'speech_$timestamp';
  }
}

/*
//오디오 재생 페이지
class AudioPlayerPage extends StatefulWidget {
  final AudioFile audioFile;

  AudioPlayerPage({required this.audioFile});

  @override
  _AudioPlayerPageState createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    await _audioPlayer.setSource(UrlSource(widget.audioFile.file));
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() => duration = d);
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() => position = p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.audioFile.title)),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Slider(
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble(),
            onChanged: (value) {
              _audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.resume();
                  }
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
*/


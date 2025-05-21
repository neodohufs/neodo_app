import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:async';
import 'get_access_token.dart';

class CoachingFeedbackPage extends StatefulWidget {
  final int speechCoachingId;

  const CoachingFeedbackPage({super.key, required this.speechCoachingId});

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
  bool isLoading = true;
  int score = 0;

  @override
  void initState() {
    super.initState();
    fetchTextAndFeedback(widget.speechCoachingId);
    audioPlayer.onDurationChanged.listen((Duration d) => setState(() => duration = d));
    audioPlayer.onPositionChanged.listen((Duration p) => setState(() => position = p));
    audioPlayer.onPlayerComplete.listen((_) => setState(() {
      isPlaying = false;
      position = Duration.zero;
    }));
  }

  Future<void> fetchTextAndFeedback(int id) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://21b2-1-230-133-117.ngrok-free.app/api/speech-coachings/$id/feedback"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          originalStt = data['data']['originalStt'] ?? "";
          score = data['data']['score'] ?? 0;
          conclusion = data['data']['conclusion'] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> playAudio(int id) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://21b2-1-230-133-117.ngrok-free.app/api/speech-coachings/$id/record"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final audioPath = json.decode(response.body)['data']['record'];
        await audioPlayer.stop();
        await audioPlayer.setSourceUrl(audioPath);
        await audioPlayer.resume();
        setState(() => isPlaying = true);
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
    }
  }

  String formatTime(Duration d) => '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('스피치코칭 피드백', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("점수 : $score",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 16),
                  const Text("변환된 텍스트",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.brown.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(originalStt, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  const Text("피드백",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.brown.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(conclusion, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                    activeColor: Colors.brown,
                    onChanged: (value) async {
                      final newPos = Duration(seconds: value.toInt());
                      await audioPlayer.seek(newPos);
                      setState(() => position = newPos);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(formatTime(position), style: const TextStyle(color: Colors.brown)),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.brown),
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
                      Text(formatTime(duration), style: const TextStyle(color: Colors.brown)),
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
/*class CoachingFeedbackPage extends StatefulWidget {
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
              "https://21b2-1-230-133-117.ngrok-free.app/api/speech-coachings/$speechCoachingId/feedback"),
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
            "https://21b2-1-230-133-117.ngrok-free.app/api/speech-coachings/$speechCoachingId/record"),
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

}*/
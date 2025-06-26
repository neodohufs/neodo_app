import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../get_access_token.dart';
import 'package:http/http.dart' as http;

class FeedbackPage extends StatefulWidget {
  final int speechBoardId;
  const FeedbackPage({super.key, required this.speechBoardId});

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
  int score = 0;
  String title = "";
  List<String> topics = [];
  String audioUrl = "";

  bool isFullLoading = true;

  @override
  void initState() {
    super.initState();

    audioPlayer.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) {
        setState(() {
          duration = d;
        });
      }
    });

    audioPlayer.onPositionChanged.listen((p) {
      if (mounted && p <= duration) {
        setState(() => position = p);
      }
    });

    audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          position = duration;
        });
      }
    });

    loadAllData();
  }

  Future<void> loadAllData() async {
    setState(() => isFullLoading = true);
    try {
      await Future.wait([
        fetchTextAndFeedback(widget.speechBoardId),
        fetchTitle(widget.speechBoardId),
        fetchAndPrepareAudio(widget.speechBoardId),
      ]);
    } catch (e) {
      print("[loadAllData] 예외 발생: $e");
    } finally {
      if (mounted) setState(() => isFullLoading = false);
    }
  }

  Future<void> fetchAndPrepareAudio(int id) async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final response = await http.get(
        Uri.parse("ip-172-31-37-122.ap-northeast-2.compute.internal/api/speech-boards/$id/record"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Set-Cookie': 'RefreshToken=$refreshToken',
        },
      );
      if (response.statusCode == 200) {
        audioUrl = json.decode(response.body)['data']['record'];
        await audioPlayer.setSourceUrl(audioUrl);
      } else {
        print("[fetchAndPrepareAudio] 실패: 상태 코드 ${response.statusCode}");
      }
    } catch (e) {
      print("[fetchAndPrepareAudio] 예외 발생: $e");
    }
  }

  Future<void> fetchTextAndFeedback(int id) async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final response = await http.get(
        Uri.parse("ip-172-31-37-122.ap-northeast-2.compute.internal/api/speech-boards/$id/feedback"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Set-Cookie': 'RefreshToken=$refreshToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          originalStt = data['data']['originalStt'] ?? "";
          score = data['data']['score'] ?? 0;
          conclusion = data['data']['conclusion'] ?? "";
          topics = List<String>.from(data['data']['topics'] ?? []);
        });
      } else {
        print("스피치 보드 피드백 : ${response.statusCode}");
      }
    } catch (e) {
      print("[fetchTextAndFeedback] 예외 발생: $e");
    }
  }

  Future<void> fetchTitle(int id) async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final response = await http.get(
        Uri.parse("ip-172-31-37-122.ap-northeast-2.compute.internal/api/speech-boards/$id/record"),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Set-Cookie': 'RefreshToken=$refreshToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() => title = data['data']['title']);
      }
    } catch (e) {
      print("[fetchTitle] 예외 발생: $e");
    }
  }

  Future<void> playAudio() async {
    try {
      await audioPlayer.resume();
      setState(() => isPlaying = true);
    } catch (e) {
      print("[playAudio] 재생 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("재생에 실패했습니다: $e")),
      );
    }
  }

  String formatTime(Duration d) => '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('스피치 피드백', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isFullLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.brown))
          : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("점수 : $score",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 16),
                  const Text("변환된 텍스트",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade200),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Text(originalStt, style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(height: 24),
                  const Text("피드백",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Text(conclusion, style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(height: 40),
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble().clamp(1, double.infinity),
                    value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                    activeColor: Colors.brown,
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await audioPlayer.seek(newPosition);
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
                            setState(() => isPlaying = false);
                          } else {
                            if (position >= duration) {
                              await audioPlayer.seek(Duration.zero);
                            }
                            await playAudio();
                          }
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

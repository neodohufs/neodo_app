import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:async';
import '../get_access_token.dart';

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

  String? audioUrl;

  @override
  void initState() {
    super.initState();
    fetchTextAndFeedback(widget.speechCoachingId);
    fetchAndPrepareAudio(widget.speechCoachingId);
    audioPlayer.onDurationChanged.listen((Duration d) => setState(() => duration = d));
    audioPlayer.onPositionChanged.listen((Duration p) => setState(() => position = p));
    audioPlayer.onPlayerComplete.listen((_){
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  Future<void> fetchAndPrepareAudio(int id) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://f8a2-1-230-133-117.ngrok-free.app/api/speech-coachings/$id/record"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if(response.statusCode == 200) {
        final data = json.decode(response.body);
        audioUrl = data['data']['record'];
        await audioPlayer.setSourceUrl(audioUrl!);
      } else {
        print("오디오 URL 로딩 실패");
      }
    } catch(e) {
      print("오디오 URL 준비 오류: $e");
    }
  }
  Future<void> fetchTextAndFeedback(int id) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://f8a2-1-230-133-117.ngrok-free.app/api/speech-coachings/$id/feedback"),
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
                          if (audioUrl == null) {
                            print("⛔ 오디오 아직 로드되지 않음");
                            return;
                          }
                          if (isPlaying) {
                            await audioPlayer.pause();
                          } else {
                            await audioPlayer.resume();
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

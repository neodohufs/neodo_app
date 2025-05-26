import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
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
  bool isLoading = true;
  int score = 0;
  List<String> topics = [];

  @override
  void initState() {
    super.initState();
    fetchTextAndFeedback(widget.speechBoardId);
    audioPlayer.onDurationChanged.listen((d) => setState(() => duration = d));
    audioPlayer.onPositionChanged.listen((p) => setState(() => position = p));
    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      }
    });
  }

  Future<void> fetchTextAndFeedback(int id) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://f8a2-1-230-133-117.ngrok-free.app/api/speech-boards/$id/feedback"),
        headers: {'Authorization': 'Bearer $token'},
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
        Uri.parse("https://f8a2-1-230-133-117.ngrok-free.app/api/speech-boards/$id/record"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final audioRecord = json.decode(response.body)['data']['record'];
        await audioPlayer.stop();
        await audioPlayer.setSourceUrl(audioRecord);
        await audioPlayer.resume();
        setState(() => isPlaying = true);
      }
    } catch (e) {
      print("오디오 재생 오류: $e");
    }
  }

  String formatTime(Duration d) => '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("제목 수정"),
            onTap: () {
              Navigator.pop(context);
              // TODO: 제목 수정 팝업 구현
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text("내용 수정"),
            onTap: () {
              Navigator.pop(context);
              // TODO: 내용 수정 팝업 구현
            },
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
        title: const Text('스피치 피드백', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("점수 : $score", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 16),
                  const Text("변환된 텍스트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade200),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Text(originalStt, style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  const Text("피드백", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
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
                    value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                    activeColor: Colors.brown,
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await audioPlayer.seek(newPosition);
                      setState(() => position = newPosition);
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
                              await playAudio(widget.speechBoardId);
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

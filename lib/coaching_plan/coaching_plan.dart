import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../home.dart';
import '../list.dart';
import '../profile.dart';
import 'coaching_feedback.dart';
import '../script/coaching_script.dart';
import '../script/coaching_script_feedback.dart';
import '../get_access_token.dart';
import '../record/min_recording.dart';

class CoachingPlanPage extends StatefulWidget {
  @override
  _CoachingPlanPage createState() => _CoachingPlanPage();
}

class _CoachingPlanPage extends State<CoachingPlanPage> {
  List fetchTopicsData = [];
  List fetchScriptsData = [];
  bool showTopics = true;

  void selectedTopic(BuildContext context, List<Map<String, dynamic>> threeTopics) {
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
              const Text("토픽 선택", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 16),
              ...threeTopics.map((topicIdAndTopic) => ListTile(
                title: Text(topicIdAndTopic['topic'], style: const TextStyle(color: Colors.brown)),
                onTap: () {
                  int? selectedCoachingId = topicIdAndTopic['speechCoachingId'];
                  _navigateToRecording(topicIdAndTopic['topicId'], selectedCoachingId);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchTopics();
    fetchScripts();
  }

  Future<void> fetchTopics() async {
    final accessToken = await getAccessToken();
    final response = await http.get(
      Uri.parse("https://dfd7-119-197-110-182.ngrok-free.app/api/speech-coachings"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        fetchTopicsData = jsonResponse['data'];
      });
    } else {
      throw Exception('Failed to load topics');
    }
  }

  Future<void> fetchScripts() async {
    final accessToken = await getAccessToken();
    final response = await http.get(
      Uri.parse("https://dfd7-119-197-110-182.ngrok-free.app/api/scripts"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        fetchScriptsData = jsonResponse['data'];
      });
    } else {
      throw Exception('Failed to load scripts');
    }
  }

  void _navigateToRecording(int selectedTopicId, int? speechCoachingId) {
    if (speechCoachingId == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => minRecordingPage(topicId: selectedTopicId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CoachingFeedbackPage(speechCoachingId: speechCoachingId)),
      );
    }
  }

  void _navigateToScriptDetail(int scriptId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CoachingScriptFeedbackPage(scriptId: scriptId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('스피치 코칭', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CoachingScriptWritePage()),
          );
        },
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: Text('3분 스피치'),
                    selected: showTopics,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => showTopics = true),
                    selectedColor: Colors.brown.shade100,
                    labelStyle: TextStyle(color: Colors.brown),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text('스피치 대본'),
                    selected: !showTopics,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => showTopics = false),
                    selectedColor: Colors.brown.shade100,
                    labelStyle: TextStyle(color: Colors.brown),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              showTopics
                  ? buildTopicList()
                  : buildScriptList(),
            ],
          ),
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
              MaterialPageRoute(builder: (_) => ProfilePage()), // 프로필 페이지
            );
          }
        },
      ),
    );
  }

  Widget buildTopicList() {
    if (fetchTopicsData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            '스피치 보드에 녹음을 추가하세요',
            style: TextStyle(color: Colors.brown, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fetchTopicsData.length,
      itemBuilder: (context, index) {
        List<Map<String, dynamic>> topicList =
        List<Map<String, dynamic>>.from(fetchTopicsData[index]['topics']);

        return GestureDetector(
          onTap: () => selectedTopic(context, topicList),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신규 스피치 ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topicList.map((topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          topic['topic'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildScriptList() {
    if (fetchScriptsData.isEmpty) {
      return const Center(child: Text('등록된 스피치 대본이 없습니다.', style: TextStyle(color: Colors.brown)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fetchScriptsData.length,
      itemBuilder: (context, index) {
        final script = fetchScriptsData[index];
        final title = script['title'] ?? '(제목 없음)';
        final createdAt = script['createdAt'] != null ? script['createdAt'].substring(0, 10) : '날짜 없음';
        final scriptId = script['id'];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: ListTile(
            title: Text(title, style: TextStyle(color: Colors.brown)),
            subtitle: Text('작성일: $createdAt', style: TextStyle(color: Colors.brown.shade300)),
            onTap: () => _navigateToScriptDetail(scriptId),
          ),
        );
      },
    );
  }
}

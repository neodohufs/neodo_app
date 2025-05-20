import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'coaching_feedback.dart';
import 'coaching_script.dart';
import 'get_access_token.dart';
import 'min_recording.dart';

class CoachingPlanPage extends StatefulWidget {
  @override
  _CoachingPlanPage createState() => _CoachingPlanPage();
}

class _CoachingPlanPage extends State<CoachingPlanPage> {
  List fetchData = [];

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
        fetchData = jsonResponse['data'];
      });
    } else {
      throw Exception('Failed to load topics');
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
        child: const Icon(Icons.add, size: 32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('스피치 코칭', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 5),
              Text('3분 스피치', style: TextStyle(fontSize: 16, color: Colors.brown.shade300)),
              const SizedBox(height: 10),
              fetchData.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fetchData.length,
                itemBuilder: (context, index) {
                  List<Map<String, dynamic>> topicList = List<Map<String, dynamic>>.from(fetchData[index]['topics']);

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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
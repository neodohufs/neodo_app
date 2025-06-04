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
              const Text("\uacfc\ud559 \uc120\ud0dd", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
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
      Uri.parse("https://3c45-1-230-133-117.ngrok-free.app/api/speech-coachings"),
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
      Uri.parse("https://3c45-1-230-133-117.ngrok-free.app/api/scripts"),
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

  Future<void> _deleteScript(int scriptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("\uc0ad\uc81c \ud655\uc778"),
        content: const Text("\uc815\ub9d0 \uc774 \ub300\ubcf8\uc744 \uc0ad\uc81c\ud558\uc2dc\uaca0\uc2b5\ub2c8\uae4c?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("\uc544\ub2c8\uc694")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("\ub124")),
        ],
      ),
    );

    if (confirm == true) {
      final token = await getAccessToken();
      final response = await http.delete(
        Uri.parse("https://3c45-1-230-133-117.ngrok-free.app/api/scripts/$scriptId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          fetchScriptsData.removeWhere((script) => script['id'] == scriptId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("\uc0ad\uc81c\ub418\uc5c8\uc2b5\ub2c8\ub2e4.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("\uc0ad\uc81c \uc2e4\ud328: ${response.statusCode}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('\uc2a4\ud53c\uce58 \ucf54\uce58\u5f0f', style: TextStyle(color: Colors.white)),
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
                    label: Text('3\ubd84 \uc2a4\ud53c\uce58'),
                    selected: showTopics,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => showTopics = true),
                    selectedColor: Colors.brown.shade100,
                    labelStyle: TextStyle(color: Colors.brown),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: Text('\uc2a4\ud53c\uce58 \ub300\ubcf8'),
                    selected: !showTopics,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => showTopics = false),
                    selectedColor: Colors.brown.shade100,
                    labelStyle: TextStyle(color: Colors.brown),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              showTopics ? buildTopicList() : buildScriptList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '\ud648'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '\ubaa9\ub85d'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '\ud504\ub9ac\ud3f4'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SpeechMenuPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfilePage()));
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
          child: Text('\uc2a4\ud53c\uce58 \ubcf4\ub4dc\uc5d0 \ub178\uadf8\uc74c\uc744 \ucd94\uac00\ud558\uc138\uc694', style: TextStyle(color: Colors.brown, fontSize: 16)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fetchTopicsData.length,
      itemBuilder: (context, index) {
        List<Map<String, dynamic>> topicList = List<Map<String, dynamic>>.from(fetchTopicsData[index]['topics']);

        return GestureDetector(
          onTap: () => selectedTopic(context, topicList),
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\uc2e0\uaddc \uc2a4\ud53c\uce58 ${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
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
                          style: const TextStyle(fontSize: 16, color: Colors.brown),
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
      return const Center(child: Text('\ub4f1\ub85d\ub41c \uc2a4\ud53c\uce58 \ub300\ubcf8\uc774 \uc5c6\uc2b5\ub2c8\ub2e4.', style: TextStyle(color: Colors.brown)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fetchScriptsData.length,
      itemBuilder: (context, index) {
        final script = fetchScriptsData[index];
        final title = script['title'] ?? '(\uc81c\ubaa9 \uc5c6\uc74c)';
        final createdAt = script['createdAt'] != null ? script['createdAt'].substring(0, 10) : '\ub0a0\uc9dc \uc5c6\uc74c';
        final scriptId = script['id'];

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: ListTile(
            title: Text(title, style: TextStyle(color: Colors.brown)),
            subtitle: Text('\uc791\uc131\uc77c: $createdAt', style: TextStyle(color: Colors.brown.shade300)),
            onTap: () => _navigateToScriptDetail(scriptId),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteScript(scriptId),
            ),
          ),
        );
      },
    );
  }
}

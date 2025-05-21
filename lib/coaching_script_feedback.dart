import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'get_access_token.dart';

class CoachingScriptFeedbackPage extends StatefulWidget {
  final int scriptId;
  const CoachingScriptFeedbackPage({super.key, required this.scriptId});

  @override
  _CoachingScriptFeedPageState createState() => _CoachingScriptFeedPageState();
}

class _CoachingScriptFeedPageState extends State<CoachingScriptFeedbackPage> {
  String title = "";
  String script = "";
  bool isLoading = true;
  String feedback = "";

  @override
  void initState() {
    super.initState();
    fetchScriptDetail(widget.scriptId);
  }

  Future<void> fetchScriptDetail(int scriptId) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://21b2-1-230-133-117.ngrok-free.app/api/scripts/$scriptId"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          title = data['data']['title'] ?? "";
          script = data['data']['script'] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchScriptFeedback(int scriptId) async {
    try {
      final token = await getAccessToken();
      final response = await http.get(
        Uri.parse("https://21b2-1-230-133-117.ngrok-free.app//api/scripts/$scriptId/feedback"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          feedback = data['data']['feedback'] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("제목 수정"),
              onTap: () {
                Navigator.pop(context);
                // TODO: 제목 수정 페이지로 이동
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text("내용 수정"),
              onTap: () {
                Navigator.pop(context);
                // TODO: 내용 수정 페이지로 이동
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('스피치 대본 상세', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditOptions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("제목: $title", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 16),
              const Text("작성한 대본", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(script, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              const Text("피드백", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Text(feedback, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

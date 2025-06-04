import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../get_access_token.dart';

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
  bool isFeedbackLoading = true;

  @override
  void initState() {
    super.initState();
    fetchScriptDetail(widget.scriptId);
  }

  Future<void> fetchScriptDetail(int scriptId) async {
    try {
      final token = await getValidAccessToken();
      final response = await http.get(
        Uri.parse("https://3c45-1-230-133-117.ngrok-free.app/api/scripts/$scriptId"),
        headers: {
          'Content-type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        title = data['data']['title'] ?? "";
        if (data['data']['editedScript'] != null) {
          script = data['data']['editedScript'];
          fetchScriptFeedback(scriptId, true);
        } else {
          script = data['data']['script'];
          fetchScriptFeedback(scriptId, false);
        }
      }
    } catch (e) {
      print("스크립트 로딩 실패: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> fetchScriptFeedback(int scriptId, bool edited) async {
    try {
      final token = await getValidAccessToken();
      final endpoint = edited ? 'edit-feedback' : 'feedback';
      final response = await http.get(
        Uri.parse("https://3c45-1-230-133-117.ngrok-free.app/api/scripts/$scriptId/$endpoint"),
        headers: {
          'Content-type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        feedback = data['data']['feedback'] ?? "";
      }
    } catch (e) {
      print("피드백 로딩 실패: $e");
    } finally {
      setState(() {
        isFeedbackLoading = false;
      });
    }
  }

  Future<void> updateScriptField(String field, String value, String api) async {
    try {
      final token = await getValidAccessToken();
      final response = await http.patch(
        Uri.parse("https://3c45-1-230-133-117.ngrok-free.app/api/scripts/${widget.scriptId}/$api"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({field: value}),
      );

      if (response.statusCode != 200) {
        print("수정 실패 ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("요청 중 오류 발생")),
      );
    }
  }

  void _showEditTitleDialog() {
    TextEditingController _editTitleController = TextEditingController(text: title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("제목 수정"),
        content: TextField(
          controller: _editTitleController,
          decoration: const InputDecoration(hintText: "새 제목 입력"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = _editTitleController.text;
              setState(() {
                title = newTitle;
              });
              updateScriptField("title", newTitle, "title");
              Navigator.pop(context);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  void _showEditContentDialog() {
    TextEditingController _editContentController = TextEditingController(text: script);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("내용 수정"),
        content: TextField(
          controller: _editContentController,
          decoration: const InputDecoration(hintText: "새 내용 입력"),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              final newScript = _editContentController.text;
              setState(() {
                script = newScript;
              });
              updateScriptField("script", newScript, "text");
              Navigator.pop(context);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

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
              _showEditTitleDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text("내용 수정"),
            onTap: () {
              Navigator.pop(context);
              _showEditContentDialog();
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
          child: isLoading || isFeedbackLoading
              ? const Center(child: CircularProgressIndicator(
            color: Colors.brown,
          ))
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
        )
    );
  }
}

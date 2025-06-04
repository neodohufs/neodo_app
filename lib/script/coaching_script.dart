import 'package:flutter/material.dart';
import '../meta_data/script_meta_data.dart';

class CoachingScriptWritePage extends StatefulWidget {
  @override
  _CoachingScriptWritePageState createState() => _CoachingScriptWritePageState();
}

class _CoachingScriptWritePageState extends State<CoachingScriptWritePage> {
  final TextEditingController _controller = TextEditingController();

  void _submitScript() {
    final scriptText = _controller.text.trim();
    if (scriptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
        builder: (context) => ScriptMetaDataPage(script: scriptText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('스피치 대본', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '대본 입력',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 40,
              decoration: InputDecoration(
                hintText: "스피치 대본을 입력하세요",
                filled: true,
                fillColor: Colors.white,
                hintStyle: const TextStyle(color: Colors.brown),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.brown),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.brown, width: 2),
                ),
              ),
              cursorColor: Colors.brown,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: _submitScript,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("대본 저장"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

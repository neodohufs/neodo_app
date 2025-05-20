import 'dart:convert';

class AudioFile {
  final String speechBoardId;
  final String file;
  final String userId;
  final String title;
  final List<String> categories;

  AudioFile({
    required this.speechBoardId,
    required this.file,
    required this.userId,
    required this.title,
    required this.categories,
  });

  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      speechBoardId: _generateSpeechBoardId(),
      file: json['file'],
      userId: json['userId'],
      title: json['title'],
      categories: List<String>.from(json['category']),
    );
  }

  static List<AudioFile> fromJsonList(String jsonString) {
    final parsed = jsonDecode(jsonString);
    final List<dynamic> data = parsed['data'];  // 백엔드 응답 구조에 따라 'data' 키가 다를 수 있음
    return data.map((json) => AudioFile.fromJson(json)).toList();
  }

  static String _generateSpeechBoardId() {
    var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'speech_$timestamp';
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'get_access_token.dart';
import 'package:http/http.dart' as http;

class AudioProvider with ChangeNotifier {
  List<Audio> _audioList = [];
  bool _isLoading = false;

  List<Audio> get audioList => _audioList;
  bool get isLoading => _isLoading;

  Future<void> fetchAudioFiles() async {
    final url = 'https://21b2-1-230-133-117.ngrok-free.app/api/speech-boards';

    final token = await getAccessToken();

    if (token == null) {
      print('Access Token이 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners(); // UI 갱신

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token', // Access Token 추가
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        print("스피치보드 오디오목록 데이터 불러오기 성공");
        if (responseBody.containsKey('data')) {
          List<dynamic> audioData = responseBody['data']; // 리스트 가져오기
          _audioList = audioData.map((item) => Audio.fromJson(item)).toList();
          notifyListeners();
        }
      } else {
        throw Exception('Failed to load audios: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('오디오 목록 불러오기 실패: $error');
    } finally {
      _isLoading = false;
      notifyListeners(); // 로딩 완료 알림
    }
  }

}

class Audio {
  final int id;
  final int userId;
  final String title;
  final String createdAt;

  Audio(
      {required this.id,
        required this.userId,
        required this.title,
        required this.createdAt});

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      createdAt: json['createdAt'],
    );
  }
}
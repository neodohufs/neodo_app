import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> getAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('accessToken');
}

Future<bool> refreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refreshToken');

  if (refreshToken == null) {
    print('❌ 저장된 refresh token 없음');
    return false;
  }

  final url = Uri.parse('https://example.com/api/auth/refresh'); // ← API 주소 너가 쓰는 걸로 바꿔
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $refreshToken',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    await prefs.setString('accessToken', newAccessToken);
    await prefs.setString('refreshToken', newRefreshToken);

    print('✅ 토큰 재발급 완료');
    return true;
  } else {
    print('❌ 토큰 재발급 실패: ${response.statusCode}');
    return false;
  }
}

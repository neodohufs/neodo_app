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

  final url = Uri.parse('https://3c45-1-230-133-117.ngrok-free.app/api/auth/refresh'); // ← API 주소 너가 쓰는 걸로 바꿔
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

Future<String?> getValidAccessToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('accessToken');

  // 테스트 요청을 통해 토큰이 유효한지 확인 (옵션)
  final testUrl = Uri.parse('https://3c45-1-230-133-117.ngrok-free.app/api/users/my-page');
  final testResponse = await http.get(
    testUrl,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
  );

  if (testResponse.statusCode == 200) {
    return accessToken; // ✅ 유효한 토큰
  }

  // ❌ 403 또는 401 → 토큰 만료 시도
  print('[DEBUG] 기존 토큰 만료됨, 재발급 시도');
  final success = await refreshToken();

  if (success) {
    print('[DEBUG] 토큰 재발급 성공');
    return prefs.getString('accessToken');
  } else {
    print('[ERROR] 토큰 재발급 실패');
    return null;
  }
}

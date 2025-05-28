import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'get_access_token.dart';

class ApiService {
  Future<User?> getUserInfo() async {
    final token = await getAccessToken();
    final url = Uri.parse(
        'https://dfd7-119-197-110-182.ngrok-free.app/api/users/my-page');
    final response = await http.get(
      url,
      headers: {
        'Authorization' : 'Bearer $token',
        'Content-Type' : 'application/json',
      }
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return User.fromJson(responseData['data']);
    } else {
      print("유저 정보 가져오기 실패: ${response.body}");
      return null;
    }
  }
}

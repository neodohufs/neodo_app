import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:neodo/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8), // 도넛 스타일 배경색
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/donut_character.png',
                width: 120,
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 32),
              _buildInputField(
                controller: emailController,
                label: "Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock,
                obscure: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => login(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Log In",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                child: const Text(
                  "회원가입 하기",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                    color: Colors.brown,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.brown),
        prefixIcon: Icon(icon, color: Colors.brown),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.brown),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.brown),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.brown, width: 2),
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
      cursorColor: Colors.brown,
    );
  }

  Future<void> login(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('https://3c45-1-230-133-117.ngrok-free.app/api/users/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        print("로그인 성공: ${emailController.text}, ${passwordController.text}");

        // Access Token 파싱
        String? accessToken = response.headers['authorization'] ?? response.headers['Authorization'];
        if (accessToken != null && accessToken.startsWith('Bearer ')) {
          accessToken = accessToken.substring(7);
        }

        // SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // Access Token 저장
        if (accessToken != null) {
          await prefs.setString('accessToken', accessToken);
          print("✅ AccessToken 저장 완료: $accessToken");
        }

        // Refresh Token 저장 (Set-Cookie 방식)
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          final match = RegExp(r'RefreshToken=([^;]+)').firstMatch(setCookie);
          if (match != null) {
            final refreshToken = match.group(1);
            await prefs.setString('refreshToken', refreshToken!);
            print("✅ RefreshToken 저장 완료: $refreshToken");
          }
        }

        // 페이지 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
      else {
        _showErrorDialog(context, '로그인 실패: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog(context, '서버 오류: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
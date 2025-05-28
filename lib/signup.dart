import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Donut",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 32),
              _buildInputField(
                controller: usernameController,
                label: "Username",
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => signUp(context),
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
                  "Sign Up",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text(
                  "이미 계정이 있으신가요? 로그인",
                  style: TextStyle(color: Colors.brown),
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

  Future<void> signUp(BuildContext context) async {
    final String username = usernameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;

    try {
      final response = await http.post(
        Uri.parse("https://dfd7-119-197-110-182.ngrok-free.app/api/users/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'username': username, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        _showErrorDialog(context, '회원가입 실패: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog(context, '서버 요청 중 오류 발생: $e');
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

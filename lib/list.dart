import 'package:flutter/material.dart';
import 'package:neodo/profile.dart';
import 'package:neodo/recording.dart';
import 'coaching_plan.dart';
import 'home.dart';
import 'speech_board.dart';

class SpeechMenuPage extends StatelessWidget {
  const SpeechMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'label': '스피치 보드', 'page': SpeechBoardPage()},
      {'label': '3분 스피치', 'page': CoachingPlanPage()},
      {'label': '스피치 녹음', 'page': RecordingPage()},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: const Text('전체 메뉴'),
        backgroundColor: Colors.brown,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        itemCount: menuItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.brown, width: 1.5),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: ListTile(
              leading: const Icon(Icons.radio_button_unchecked, color: Colors.brown),
              title: Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['page'] as Widget),
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SpeechMenuPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage()), // 프로필 페이지
            );
          }
        },
      ),
    );
  }
}

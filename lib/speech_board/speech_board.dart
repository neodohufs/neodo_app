import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio.dart';
import '../home.dart';
import '../list.dart';
import '../profile.dart';
import 'feedback.dart';
import '../get_access_token.dart';

class SpeechBoardPage extends StatefulWidget {
  @override
  _SpeechBoardPageState createState() => _SpeechBoardPageState();
}

class _SpeechBoardPageState extends State<SpeechBoardPage> {
  late Future<void> _fetchAudioFuture;

  @override
  void initState() {
    super.initState();
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _fetchAudioFuture = audioProvider.fetchAudioFiles();
  }

  Future<void> _refreshAudioFiles() async {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    await audioProvider.fetchAudioFiles();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('스피치 보드', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<void>(
        future: _fetchAudioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다. 다시 시도해주세요.'));
          }

          if (audioProvider.audioList.isEmpty) {
            return const Center(child: Text('오디오 파일이 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshAudioFiles,
            child: ListView.builder(
              itemCount: audioProvider.audioList.length,
              itemBuilder: (context, index) {
                final file = audioProvider.audioList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.brown,
                        child: const Icon(Icons.mic, color: Colors.white),
                      ),
                      title: Text(
                        file.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      subtitle: Text(
                        '생성 날짜: ${file.createdAt}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeedbackPage(speechBoardId: file.id),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // 현재 선택된 탭 (예: 목록이 1번째 인덱스일 경우)
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '목록'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()), // 홈 페이지로 이동
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SpeechMenuPage()), // 목록 페이지
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

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
//import 'audio_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
//import 'speech_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'audio.dart';
import 'onBoarding.dart';
import 'user.dart';
import 'apiService.dart';
import 'dart:developer';
import 'get_access_token.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioProvider()), // AudioProvider 추가
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

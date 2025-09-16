import 'package:flutter/material.dart';
import 'entry_screen.dart';

void main() {
  runApp(const GamerLetterboxApp());
}

class GamerLetterboxApp extends StatelessWidget {
  const GamerLetterboxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamer Letterbox',
      theme: ThemeData(
        primaryColor: const Color(0xFF107C10), // Verde Xbox
      ),
      home: const EntryScreen(),
    );
  }
}

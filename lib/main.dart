import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mlnjdtymmkshchybwsbe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sbmpkdHltbWtzaGNoeWJ3c2JlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0NjAwOTksImV4cCI6MjA4OTAzNjA5OX0.CwNKlWZx2ICQVoT9PC3Fu9JsfDkvNjLitCMpuH52BnQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: session == null ? const LoginScreen() : const MainScreen(),
    );
  }
}
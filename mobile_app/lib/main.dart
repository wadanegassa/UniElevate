import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/exam_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Replace with actual Supabase credentials for production
  await Supabase.initialize(
    url: 'https://lsgtrvyjljeedowxkigs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzZ3RydnlqbGplZWRvd3hraWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2NDYzNDcsImV4cCI6MjA4NzIyMjM0N30.Oq4RUFehlxhH0Y1EsmdZrZfTunRUygooGoblh51Pg_E',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ExamProvider(
            geminiApiKey: 'AIzaSyAlBS_QJU_5sPLUBSzIcrvYcrZQTZjMd1c',
          ),
        ),
      ],
      child: const UniElevateApp(),
    ),
  );
}

class UniElevateApp extends StatelessWidget {
  const UniElevateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniElevate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto', // Defaulting to Roboto
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.cyanAccent,
          surface: Colors.black,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

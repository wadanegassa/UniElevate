import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/exam_manager_provider.dart';
import 'providers/monitor_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the same credentials as the student app
  await Supabase.initialize(
    url: 'https://lsgtrvyjljeedowxkigs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzZ3RydnlqbGplZWRvd3hraWdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE2NDYzNDcsImV4cCI6MjA4NzIyMjM0N30.Oq4RUFehlxhH0Y1EsmdZrZfTunRUygooGoblh51Pg_E',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExamManagerProvider()),
        ChangeNotifierProvider(create: (_) => MonitorProvider()),
      ],
      child: const UniElevateAdminApp(),
    ),
  );
}

class UniElevateAdminApp extends StatelessWidget {
  const UniElevateAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniElevate Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.indigoAccent,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.indigoAccent,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF111111),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.user != null) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

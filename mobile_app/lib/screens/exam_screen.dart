import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../providers/auth_provider.dart';
import '../models/aura_state.dart';
import '../widgets/aura_orb.dart';
import '../widgets/live_transcript.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final examProvider = Provider.of<ExamProvider>(context, listen: false);
      if (authProvider.user != null) {
        examProvider.startExam(
          studentId: authProvider.user!.id,
          onLogout: () {
            authProvider.logout();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExamProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => provider.startListening(),
        onLongPress: () => provider.repeatQuestion(),
        onPanUpdate: (details) {
          // Detect two-finger swipe - simplified for hackathon
          // In a real app, use a proper gesture recognizer
        },
        child: Stack(
          children: [
            // Floating particles background (Cool factor)
            ...List.generate(15, (i) => Positioned(
              top: (i * 123) % 800 + 0.0,
              left: (i * 57) % 400 + 0.0,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white, blurRadius: 4, spreadRadius: 1)],
                  ),
                ),
              ),
            )),

            // Background elements
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _formatTime(provider.remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.currentExam == null ? "Searching for Active Exam..." : "Exam: ${provider.currentExam!.title}",
                      style: TextStyle(
                        color: provider.currentExam == null ? Colors.orangeAccent : Colors.cyanAccent.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Central Aura Orb
            Center(
              child: AuraOrb(state: provider.auraState),
            ),

            // Live Transcript
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: LiveTranscript(
                transcript: provider.liveTranscript,
                isListening: provider.auraState == AuraState.studentSpeaking,
              ),
            ),

            // Finish Overlay
            if (provider.isFinished)
              Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Exam Completed",
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Return to Portal"),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }
}

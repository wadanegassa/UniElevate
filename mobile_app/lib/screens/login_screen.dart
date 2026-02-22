import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/voice_service.dart';
import '../models/aura_state.dart';
import '../widgets/aura_orb.dart';
import 'exam_screen.dart';
import '../services/voice_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  AuraState _auraState = AuraState.idle;

  bool _isWelcomeActive = true;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    
    // Auto-welcome the student
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeVoice();
    });
  }

  Future<void> _welcomeVoice() async {
    if (!mounted || !_isWelcomeActive) return;
    
    // 1. Initial Greeting
    setState(() => _auraState = AuraState.aiSpeaking);
    await _voiceService.speak(
      "Welcome to Uni Elevate. Before we begin, let's take a deep breath together.",
    );

    // 2. Breathing Sequence
    if (!mounted || !_isWelcomeActive) return;
    setState(() => _auraState = AuraState.zenBreathing);
    
    // Break delay into smaller chunks to allow faster cancellation
    for (int i = 0; i < 40; i++) {
      if (!mounted || !_isWelcomeActive) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 3. Instructions
    if (!mounted || !_isWelcomeActive) return;
    setState(() => _auraState = AuraState.aiSpeaking);
    await _voiceService.speak(
      "I am your digital proctor. Please enter your email and access command to enter the exam portal, or tap the screen for voice assistance.",
      onComplete: () {
        if (!mounted || !_isWelcomeActive) return;
        setState(() => _auraState = AuraState.idle);
      },
    );
  }

  Future<void> _startVoiceLogin() async {
    _isWelcomeActive = false; // Abort any outgoing welcome sequence
    
    if (!mounted) return;
    setState(() {
      _auraState = AuraState.aiSpeaking;
    });

    await _voiceService.speak("Please say your student email address.");
    
    if (!mounted) return;
    setState(() => _auraState = AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (email, confidence) {
        if (!mounted) return;
        setState(() {
          _emailController.text = VoiceUtils.normalizeEmail(email);
          _auraState = AuraState.aiSpeaking;
        });
        _askForCommand();
      },
      onListeningChanged: (listening) {},
      onError: () {
        if (!mounted) return;
        _voiceService.speak("I didn't hear you. Please tap the orb to try again.");
      },
    );
  }

  Future<void> _askForCommand() async {
    await _voiceService.speak("Got it. Now, please say your access command.");
    if (!mounted) return;
    setState(() => _auraState = AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (command, confidence) {
        if (!mounted) return;
        setState(() {
          // Normalize command to catch things like "Command is ALPHA" -> "ALPHA"
          _passwordController.text = VoiceUtils.normalizeCommand(command).trim();
          _auraState = AuraState.processing;
        });
        _attemptLogin();
      },
      onListeningChanged: (listening) {},
      onError: () {
        if (!mounted) return;
        _voiceService.speak("I didn't hear the command. Please try again.");
      },
    );
  }

  Future<void> _attemptLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExamScreen()),
      );
    } else {
      if (!mounted) return;
      setState(() => _auraState = AuraState.idle);
      await _voiceService.speak(authProvider.error ?? "Access refused. Please check your credentials.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      // We set resizeToAvoidBottomInset to true to allow the SingleChildScrollView to work properly
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Aura Orb (Static/Fixed)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: GestureDetector(
                onTap: _startVoiceLogin,
                child: AuraOrb(state: _auraState),
              ),
            ),
          ),

          // Content Layer (Scrollable to handle keyboard)
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "UniElevate",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    "Digital Exam System".toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  // Use a fixed spacing instead of Spacer inside scroll view
                  const SizedBox(height: 80),

                  // Dynamic Info Panel
                  AnimatedOpacity(
                    opacity: authProvider.isLoading ? 0.3 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "STUDENT EMAIL",
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                              prefixIcon: Icon(Icons.mail_outline, color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(color: Colors.white10),
                          TextField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: "ACCESS COMMAND",
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                              prefixIcon: Icon(Icons.terminal_outlined, color: Colors.indigoAccent),
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  if (authProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _attemptLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text("ACCESS PORTAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _startVoiceLogin,
                    child: const Column(
                      children: [
                        Icon(Icons.mic_none, color: Colors.cyanAccent, size: 32),
                        SizedBox(height: 8),
                        Text(
                          "TAP ORB FOR VOICE LOGIN",
                          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/voice_service.dart';
import '../models/aura_state.dart';
import '../widgets/aura_orb.dart';
import 'exam_screen.dart';

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
  bool _isVoiceMode = false;

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
    if (!mounted) return;
    setState(() => _auraState = AuraState.aiSpeaking);
    await _voiceService.speak(
      "Welcome to Uni Elevate. I am your digital proctor. Please enter your email and access command to enter the exam portal, or tap the screen for voice assistance.",
      onComplete: () {
        if (!mounted) return;
        setState(() => _auraState = AuraState.idle);
      },
    );
  }

  Future<void> _startVoiceLogin() async {
    if (!mounted) return;
    setState(() {
      _isVoiceMode = true;
      _auraState = AuraState.aiSpeaking;
    });

    await _voiceService.speak("Please say your student email address.");
    
    if (!mounted) return;
    setState(() => _auraState = AuraState.studentSpeaking);
    await _voiceService.listen(
      onResult: (email) {
        if (!mounted) return;
        setState(() {
          _emailController.text = email.replaceAll(" at ", "@").replaceAll(" dot ", ".").trim().toLowerCase();
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
      onResult: (command) {
        if (!mounted) return;
        setState(() {
          _passwordController.text = command.trim();
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
      resizeToAvoidBottomInset: false, // Keep the background fixed
      body: Stack(
        children: [
          // Aura Orb Layer
          Positioned.fill(
            child: GestureDetector(
              onTap: _startVoiceLogin,
              child: AuraOrb(state: _auraState),
            ),
          ),

          // Content Layer
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(), // Prevent bounce overscroll
                padding: EdgeInsets.only(
                  left: 32.0, 
                  right: 32.0, 
                  top: 48.0, 
                  bottom: MediaQuery.of(context).viewInsets.bottom + 48.0,
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                  const Spacer(),

                  // Dynamic Info Panel
                  AnimatedOpacity(
                    opacity: authProvider.isLoading ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
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

                  const SizedBox(height: 24),
                  
                  if (authProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        authProvider.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
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
                  
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _startVoiceLogin,
                    child: const Text(
                      "TAP ORB FOR VOICE LOGIN",
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}

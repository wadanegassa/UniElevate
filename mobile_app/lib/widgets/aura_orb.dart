import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import '../models/aura_state.dart';

class AuraOrb extends StatefulWidget {
  final AuraState state;
  const AuraOrb({super.key, required this.state});

  @override
  State<AuraOrb> createState() => _AuraOrbState();
}

class _AuraOrbState extends State<AuraOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String lottieUrl;
    Color color;

    switch (widget.state) {
      case AuraState.idle:
        lottieUrl = 'https://lottie.host/790587d0-1200-482a-a5f6-df302e1a5a81/yP5vD8l3kS.json';
        color = Colors.cyan.withValues(alpha: 0.3);
        break;
      case AuraState.aiSpeaking:
        lottieUrl = 'https://lottie.host/5a2d7f8d-7a7a-4c9f-8a0b-19335a1103f6/sXlSg2n9p2.json';
        color = Colors.blueAccent;
        break;
      case AuraState.studentSpeaking:
        lottieUrl = 'https://lottie.host/b04c8f8d-7a7a-4c9f-8a0b-19335a1103f6/sXlSg2n9p2.json';
        color = Colors.purpleAccent;
        break;
      case AuraState.processing:
        lottieUrl = 'https://lottie.host/c15c8f8d-7a7a-4c9f-8a0b-19335a1103f6/sXlSg2n9p2.json';
        color = Colors.white;
        break;
      case AuraState.zenBreathing:
        lottieUrl = 'https://lottie.host/790587d0-1200-482a-a5f6-df302e1a5a81/yP5vD8l3kS.json';
        color = const Color(0xFF6366f1); // Indigo
        break;
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow with Pulse
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Container(
                width: 300 * _pulse.value,
                height: 300 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4 * _pulse.value),
                      blurRadius: 50 * _pulse.value,
                      spreadRadius: 20 * _pulse.value,
                    ),
                  ],
                ),
              );
            },
          ),
          // Lottie Animation
          SizedBox(
            width: 250,
            height: 250,
            child: RepaintBoundary(
              child: kIsWeb 
                ? Icon(Icons.blur_on, color: color, size: 150)
                : Lottie.network(
                    lottieUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.blur_on, color: color, size: 100),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

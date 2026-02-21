import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import '../models/aura_state.dart';

class AuraOrb extends StatelessWidget {
  final AuraState state;

  const AuraOrb({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    String lottieUrl;
    Color color;

    switch (state) {
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
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 50,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
          // Lottie Animation
          SizedBox(
            width: 250,
            height: 250,
            child: RepaintBoundary(
              child: kIsWeb 
                ? Icon(Icons.blur_on, color: color, size: 150) // Simpler rendering for Web to avoid DDC errors
                : Lottie.network(
                    lottieUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.blur_on, color: color, size: 100),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

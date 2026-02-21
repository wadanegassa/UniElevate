import 'package:flutter/material.dart';

class LiveTranscript extends StatelessWidget {
  final String transcript;
  final bool isListening;

  const LiveTranscript({
    super.key,
    required this.transcript,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    if (!isListening && transcript.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isListening)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Listening...",
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          Text(
            transcript.isEmpty ? "..." : transcript,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

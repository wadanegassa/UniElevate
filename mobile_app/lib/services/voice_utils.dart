import 'package:flutter/foundation.dart';

class VoiceUtils {
  static String normalizeCommand(String text) {
    if (text.isEmpty) return "";
    String lower = text.toLowerCase().trim();
    debugPrint('VoiceUtils: Normalizing text: "$lower"');
    
    // 0. Phonetic number repair
    final numberMap = {
      'one': '1', 'two': '2', 'to': '2', 'too': '2', 'three': '3', 
      'four': '4', 'for': '4', 'five': '5', 'six': '6', 'seven': '7', 
      'eight': '8', 'ate': '8', 'nine': '9', 'zero': '0'
    };
    numberMap.forEach((word, digit) {
      lower = lower.replaceAll(RegExp('\\b$word\\b'), digit);
    });

    // 1. Check for MCQ options first (A, B, C, D, E)
    final mcqMatch = RegExp(r'\b(option|choice|answer is|it is|pick|select)?\s*([a-e])\b').firstMatch(lower);
    if (mcqMatch != null) {
      final letter = mcqMatch.group(2)!.toUpperCase();
      debugPrint('VoiceUtils: Detected MCQ Option $letter');
      return letter;
    }

    // 2. Specialized Access Command Cleaning
    final commandPhraseMatch = RegExp(r'\b(command is|mine is|say|it is|it’s)\s+([a-z0-9_-]+)\b').firstMatch(lower);
    if (commandPhraseMatch != null) {
      return commandPhraseMatch.group(2)!.toUpperCase();
    }

    // 3. Global command synonyms
    final yesSynonyms = ["yes", "yeah", "yep", "yub", "yup", "sure", "correct", "ready", "begin", "start", "ok", "okay", "proceed", "go ahead", "let's go", "do it", "positive", "affirmative", "exactly", "absolutely", "right", "true", "yaas"];
    final noSynonyms = ["no", "nope", "wrong", "stop", "wait", "negative", "incorrect", "hold on", "not yet", "cancel", "back", "re-do", "redo", "false", "nah"];
    final repeatSynonyms = ["repeat", "read again", "one more time", "come again", "pardon", "what", "can you repeat", "say that again", "tell me again", "repeat the question", "once more", "again"];
    final nextSynonyms = ["next", "skip", "continue", "move on", "next question", "go next", "pass"];

    for (final syn in yesSynonyms) {
      if (RegExp('\\b${RegExp.escape(syn)}\\b').hasMatch(lower)) return "yes";
    }
    for (final syn in noSynonyms) {
      if (RegExp('\\b${RegExp.escape(syn)}\\b').hasMatch(lower)) return "no";
    }
    for (final syn in repeatSynonyms) {
      if (RegExp('\\b${RegExp.escape(syn)}\\b').hasMatch(lower)) return "repeat";
    }
    for (final syn in nextSynonyms) {
      if (RegExp('\\b${RegExp.escape(syn)}\\b').hasMatch(lower)) return "next";
    }
    
    // Otherwise, return cleaned uppercase for raw command matching (useful for login passwords)
    return lower.toUpperCase().replaceAll(RegExp(r'\s+'), '_');
  }

  static String normalizeEmail(String text) {
    if (text.isEmpty) return "";
    
    String normalized = text.toLowerCase()
        .replaceAll(RegExp(r'\s+at\s+sign\s+'), "@")
        .replaceAll(RegExp(r'\s+at\s+'), "@")
        .replaceAll(RegExp(r'\(at\)'), "@")
        .replaceAll(RegExp(r'\[at\]'), "@")
        .replaceAll(RegExp(r'\s+dot\s+'), ".")
        .replaceAll(RegExp(r'\s+point\s+'), ".")
        .replaceAll(RegExp(r'\(dot\)'), ".")
        .replaceAll(RegExp(r'\[dot\]'), ".")
        .replaceAll(RegExp(r'\s+underscore\s+'), "_")
        .replaceAll(RegExp(r'\s+dash\s+'), "-")
        .replaceAll(RegExp(r'\s+hyphen\s+'), "-")
        // Handle common university email verbalizations
        .replaceAll(" edu ", ".edu")
        .replaceAll(" com ", ".com")
        .replaceAll(" org ", ".org")
        .replaceAll(" ", "")
        .trim();

    // Repair common phonetic errors (e.g. "gmail dot com" -> "gmail.com")
    if (normalized.endsWith("com") && !normalized.contains(".com")) {
      normalized = normalized.replaceFirst(RegExp(r'com$'), ".com");
    }
    if (normalized.endsWith("edu") && !normalized.contains(".edu")) {
      normalized = normalized.replaceFirst(RegExp(r'edu$'), ".edu");
    }

    return normalized;
  }

  static String? matchOption(String transcript, List<String> options) {
    final lowerTranscript = transcript.toLowerCase().trim();
    if (lowerTranscript.isEmpty) return null;
    
    // 1. Ordinal matching ("first", "second", "third", "last")
    final ordinals = ["first", "second", "third", "fourth", "fifth", "last"];
    for (int i = 0; i < ordinals.length; i++) {
        final ord = ordinals[i];
        if (lowerTranscript.contains(ord)) {
            int index = i;
            if (ord == "last") index = options.length - 1;
            if (index < options.length) {
                return String.fromCharCode(65 + index);
            }
        }
    }

    // 2. Exact or partial match with option text
    for (int i = 0; i < options.length; i++) {
        final optionText = options[i].toLowerCase().trim();
        if (optionText.isEmpty) continue;
        
        // Exact match is best
        if (lowerTranscript == optionText) {
            return String.fromCharCode(65 + i);
        }
        
        // If transcript contains the option text as a word
        if (optionText.length >= 3 && RegExp('\\b${RegExp.escape(optionText)}\\b').hasMatch(lowerTranscript)) {
            return String.fromCharCode(65 + i);
        }
    }
    
    return null;
  }
}

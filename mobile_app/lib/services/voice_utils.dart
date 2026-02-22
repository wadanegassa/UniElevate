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

    // Strip punctuation BEFORE phonetic letter matching to handle "hay." or "hey,"
    lower = lower.replaceAll(RegExp(r'[^\w\s]'), ''); 
    
    // 0.5. Phonetic Letter repair (A-E)
    // Helps STT engines that misinterpret single letter options
    final letterMap = {
      'hey': 'a', 'eh': 'a', 'aye': 'a', 'ay': 'a', 'ei': 'a', 'eight': 'a', 'ey': 'a', 'hay': 'a',
      'bee': 'b', 'be': 'b', 'pea': 'b', 'p': 'b', 'me': 'b', 'dissent': 'b', 'bit': 'b',
      'see': 'c', 'sea': 'c', 'si': 'c', 'say': 'c', 'she': 'c', 'xi': 'c',
      'dee': 'd', 'de': 'd', 'tea': 'd', 't': 'd', 'the': 'd', 'di': 'd', 'do': 'd',
      'ee': 'e', 'e': 'e', 'he': 'e', 'hi': 'e', 'ii': 'e', 'eat': 'e', 'each': 'e'
    };
    letterMap.forEach((word, letter) {
      if (lower.trim() == word) lower = letter; // Direct match for single word
      lower = lower.replaceAll(RegExp('\\boption $word\\b'), 'option $letter');
      lower = lower.replaceAll(RegExp('\\bchoice $word\\b'), 'choice $letter');
      lower = lower.replaceAll(RegExp('\\banswer $word\\b'), 'answer $letter');
      lower = lower.replaceAll(RegExp('\\bis $word\\b'), 'is $letter');
      lower = lower.replaceAll(RegExp('\\bit is $word\\b'), 'it is $letter');
    });

    // 1. Check for MCQ options first (A, B, C, D, E)
    // We already stripped punctuation above, so lower should be clean
    String cleanLetter = lower.trim();
    if (cleanLetter.length == 1 && RegExp(r'[a-e]').hasMatch(cleanLetter)) {
      return cleanLetter.toUpperCase();
    }

    final mcqMatch = RegExp(r'\b(option|choice|answer is|it is|it’s|pick|select|letter|my answer is|i think it is|go with|mark)\s*([a-e])\b').firstMatch(lower);
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

  static String cleanTheoryAnswer(String text) {
    if (text.isEmpty) return "";
    String lower = text.toLowerCase().trim();
    
    // Remove common speech fillers
    final fillers = [
      "ummm", "uhhh", "hmmm", "well", "like", "you know", "i mean", 
      "actually", "basically", "so yeah", "i think that", "maybe it is",
      "let me see", "i guess"
    ];
    
    String cleaned = lower;
    for (var filler in fillers) {
       cleaned = cleaned.replaceAll(RegExp('\\b$filler\\b'), '');
    }
    
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
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
    String lowerTranscript = transcript.toLowerCase().trim();
    if (lowerTranscript.isEmpty) return null;
    
    final letterMap = {
      'hey': 'a', 'eh': 'a', 'aye': 'a', 'ay': 'a', 'ei': 'a', 'eight': 'a', 'ey': 'a', 'hay': 'a',
      'bee': 'b', 'be': 'b', 'pea': 'b', 'p': 'b', 'me': 'b', 'dissent': 'b', 'bit': 'b',
      'see': 'c', 'sea': 'c', 'si': 'c', 'say': 'c', 'she': 'c', 'xi': 'c',
      'dee': 'd', 'de': 'd', 'tea': 'd', 't': 'd', 'the': 'd', 'di': 'd', 'do': 'd',
      'ee': 'e', 'e': 'e', 'he': 'e', 'hi': 'e', 'ii': 'e', 'eat': 'e', 'each': 'e'
    };
    
    // Direct phonetic replacement for the entire transcript
    if (letterMap.containsKey(lowerTranscript)) {
       lowerTranscript = letterMap[lowerTranscript]!;
    }
    
    // First run it through normalizeCommand to see if it cleanly outputs a letter a-E
    final normalized = normalizeCommand(lowerTranscript);
    if (normalized.length == 1 && RegExp(r'[A-E]').hasMatch(normalized)) {
      int idx = normalized.codeUnitAt(0) - 65;
      if (idx < options.length) return normalized;
    }
    
    // Fallback: strip punctuation and check again
    String stripped = lowerTranscript.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (stripped.length == 1 && RegExp(r'[a-eA-E]').hasMatch(stripped)) {
       String letter = stripped.toUpperCase();
       int idx = letter.codeUnitAt(0) - 65;
       if (idx < options.length) return letter;
    }
    
    // Check if transcript starts with a letter like "a is the answer"
    final startMatch = RegExp(r'^([a-eA-E])\b').firstMatch(stripped);
    if (startMatch != null) {
       String letter = startMatch.group(1)!.toUpperCase();
       int idx = letter.codeUnitAt(0) - 65;
       if (idx < options.length) return letter;
    }

    // 0.5 Number to Letter matching ("1", "2", "3")
    // Helps when students say "Option 1" or just "1"
    final numericMatch = RegExp(r'\b([1-5])\b').firstMatch(lowerTranscript);
    if (numericMatch != null) {
        int index = int.parse(numericMatch.group(1)!) - 1;
        if (index < options.length) {
            return String.fromCharCode(65 + index);
        }
    }

    // 1. Ordinal matching ("first", "second", "third", "last")
    final ordinals = {
      "first": 0, "1st": 0,
      "second": 1, "2nd": 1,
      "third": 2, "3rd": 2,
      "fourth": 3, "4th": 3,
      "fifth": 4, "5th": 4,
      "last": options.length - 1
    };
    
    for (final entry in ordinals.entries) {
        if (lowerTranscript.contains(RegExp('\\b${entry.key}\\b'))) {
            if (entry.value < options.length) {
                return String.fromCharCode(65 + entry.value);
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

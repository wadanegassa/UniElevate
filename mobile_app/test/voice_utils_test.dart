import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/voice_utils.dart';

void main() {
  group('VoiceUtils.normalizeCommand', () {
    test('should recognize YES synonyms', () {
      expect(VoiceUtils.normalizeCommand('yes'), 'yes');
      expect(VoiceUtils.normalizeCommand('yeah'), 'yes');
      expect(VoiceUtils.normalizeCommand('yep'), 'yes');
      expect(VoiceUtils.normalizeCommand('sure'), 'yes');
      expect(VoiceUtils.normalizeCommand('ok'), 'yes');
      expect(VoiceUtils.normalizeCommand('okay'), 'yes');
      expect(VoiceUtils.normalizeCommand("i'm ready"), 'yes');
      expect(VoiceUtils.normalizeCommand("let's go"), 'yes');
      expect(VoiceUtils.normalizeCommand("absolutely"), 'yes');
    });

    test('should recognize NO synonyms', () {
      expect(VoiceUtils.normalizeCommand('no'), 'no');
      expect(VoiceUtils.normalizeCommand('nope'), 'no');
      expect(VoiceUtils.normalizeCommand('wrong'), 'no');
      expect(VoiceUtils.normalizeCommand('stop'), 'no');
      expect(VoiceUtils.normalizeCommand('wait'), 'no');
      expect(VoiceUtils.normalizeCommand('try again'), 'no');
    });

    test('should recognize REPEAT synonyms', () {
      expect(VoiceUtils.normalizeCommand('repeat'), 'repeat');
      expect(VoiceUtils.normalizeCommand('one more time'), 'repeat');
      expect(VoiceUtils.normalizeCommand('read again'), 'repeat');
      expect(VoiceUtils.normalizeCommand('say that again'), 'repeat');
    });

    test('should recognize NEXT synonyms', () {
      expect(VoiceUtils.normalizeCommand('next'), 'next');
      expect(VoiceUtils.normalizeCommand('skip'), 'next');
      expect(VoiceUtils.normalizeCommand('continue'), 'next');
      expect(VoiceUtils.normalizeCommand('move on'), 'next');
    });

    test('should recognize MCQ options', () {
      expect(VoiceUtils.normalizeCommand('A'), 'A');
      expect(VoiceUtils.normalizeCommand('option b'), 'B');
      expect(VoiceUtils.normalizeCommand('choice c'), 'C');
      expect(VoiceUtils.normalizeCommand('the answer is d'), 'D');
      expect(VoiceUtils.normalizeCommand('i pick e'), 'E');
      expect(VoiceUtils.normalizeCommand('select a'), 'A');
    });

    test('should return original text if no match', () {
      expect(VoiceUtils.normalizeCommand('The capital is Paris'), 'the capital is paris');
      expect(VoiceUtils.normalizeCommand('Global warming is real'), 'global warming is real');
    });

    test('should handle punctuation and casing', () {
      expect(VoiceUtils.normalizeCommand('Yes!'), 'yes');
      expect(VoiceUtils.normalizeCommand('  NO  '), 'no');
      expect(VoiceUtils.normalizeCommand('Option B.'), 'B');
    });

    test('should match MCQ options by text', () {
      final options = ['Paris', 'London', 'Berlin', 'Madrid'];
      expect(VoiceUtils.matchOption('Paris', options), 'A');
      expect(VoiceUtils.matchOption('I think it is London', options), 'B');
      expect(VoiceUtils.matchOption('Berlin is the one', options), 'C');
      expect(VoiceUtils.matchOption('Madrid', options), 'D');
    });

    test('should return null for non-matching MCQ text', () {
      final options = ['Paris', 'London', 'Berlin', 'Madrid'];
      expect(VoiceUtils.matchOption('Rome', options), isNull);
      expect(VoiceUtils.matchOption('a', options), isNull); // Too short
    });

    test('should match MCQ options by ordinal', () {
      final options = ['Paris', 'London', 'Berlin', 'Madrid'];
      expect(VoiceUtils.matchOption('the first one', options), 'A');
      expect(VoiceUtils.matchOption('second option', options), 'B');
      expect(VoiceUtils.matchOption('third', options), 'C');
      expect(VoiceUtils.matchOption('the last one', options), 'D');
    });

    group('VoiceUtils.normalizeEmail', () {
      test('should normalize common email speech patterns', () {
        expect(VoiceUtils.normalizeEmail('test at gmail dot com'), 'test@gmail.com');
        expect(VoiceUtils.normalizeEmail('user (at) haramaya [dot] edu'), 'user@haramaya.edu');
      });
    });
  });
}

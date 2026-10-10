import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class WordStageData {
  final String word;
  final String description;
  final List<String> scrambledLetters;
  final List<String> hints;
  final int rewardCoins;

  WordStageData({
    required this.word,
    required this.description,
    required this.scrambledLetters,
    required this.hints,
    required this.rewardCoins,
  });
}

class WordItem {
  final String word;
  final String description;
  final List<String> hints;

  WordItem({
    required this.word,
    required this.description,
    required this.hints,
  });
}

/// Service that parses words.json and generates staged word scramble puzzles.
/// Guarantees:
/// 1. Deterministic, unique, non-repeating word progression within each tier.
/// 2. Hint progression that never reveals word length or isolated vowels.
///    Vowels are only revealed when both start and end letters are specified.
class WordService {
  static final WordService instance = WordService._internal();
  WordService._internal();

  final Map<int, List<WordItem>> _wordsByLength = {};
  final Map<int, List<WordItem>> _shuffledPools = {};
  bool _isLoaded = false;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/words.json');
      final dynamic raw = jsonDecode(jsonString);

      if (raw is Map<String, dynamic>) {
        raw.forEach((key, val) {
          if (val is List) {
            final len = int.tryParse(key);
            for (var item in val) {
              if (item is Map) {
                final w = item['word']?.toString().toUpperCase().trim() ?? '';
                final desc = item['description']?.toString().trim() ?? '';
                final rawHints = item['hints'];
                final List<String> hintList = [];
                if (rawHints is List) {
                  for (var h in rawHints) {
                    final hStr = h.toString().trim();
                    if (hStr.isNotEmpty) hintList.add(hStr);
                  }
                }
                if (hintList.isEmpty && desc.isNotEmpty) {
                  hintList.add(desc);
                }

                if (w.isNotEmpty && RegExp(r'^[A-Z]+$').hasMatch(w)) {
                  final effectiveLen = len ?? w.length;
                  _wordsByLength.putIfAbsent(effectiveLen, () => []).add(
                    WordItem(word: w, description: desc, hints: hintList),
                  );
                }
              }
            }
          }
        });
      }
      _isLoaded = true;
    } catch (e) {
      // Fallback baseline dictionary
      final fallbacks = _getFallbackWords();
      _wordsByLength[3] = fallbacks;
      _isLoaded = true;
    }
  }

  static List<WordItem> _getFallbackWords() {
    return [
      WordItem(
        word: 'HAM',
        description: 'A lovable energetic hamster full of bouncy charm.',
        hints: [
          'A lovable energetic hamster full of bouncy charm.',
          'Short for hamster or a savory woodland treat.',
          "The mystery word begins with the letter 'H'.",
          "The mystery word concludes with the letter 'M'.",
          "Starts with 'H' and ends with 'M', featuring vowel(s): A.",
        ],
      ),
      WordItem(
        word: 'CAT',
        description: 'A curious hunter that purrs softly in warm sunlight.',
        hints: [
          'A curious hunter that purrs softly in warm sunlight.',
          'A beloved companion known for agile jumps and climbing high perches.',
          "The mystery word begins with the letter 'C'.",
          "The mystery word concludes with the letter 'T'.",
          "Starts with 'C' and ends with 'T', featuring vowel(s): A.",
        ],
      ),
      WordItem(
        word: 'OAK',
        description: 'A mighty enduring tree that sprouts from a humble acorn.',
        hints: [
          'A mighty enduring tree that sprouts from a humble acorn.',
          'A hardwood giant producing sturdy timber and rustling leaves.',
          "The mystery word begins with the letter 'O'.",
          "The mystery word concludes with the letter 'K'.",
          "Starts with 'O' and ends with 'K', featuring vowel(s): A, O.",
        ],
      ),
    ];
  }

  int _getStartStageForLength(int wordLength) {
    if (wordLength <= 3) return 1;
    return (wordLength - 3) * 10;
  }

  List<WordItem> _getPoolForLength(int wordLength) {
    if (_shuffledPools.containsKey(wordLength)) {
      return _shuffledPools[wordLength]!;
    }

    List<WordItem> rawPool = _wordsByLength[wordLength] ?? [];
    if (rawPool.isEmpty) {
      for (int offset = 1; offset <= 4; offset++) {
        if (_wordsByLength[wordLength - offset]?.isNotEmpty ?? false) {
          rawPool = _wordsByLength[wordLength - offset]!;
          break;
        }
        if (_wordsByLength[wordLength + offset]?.isNotEmpty ?? false) {
          rawPool = _wordsByLength[wordLength + offset]!;
          break;
        }
      }
    }

    if (rawPool.isEmpty) {
      rawPool = _getFallbackWords();
    }

    // Deterministically shuffle with fixed seed per length to ensure unique sequence
    final pool = List<WordItem>.from(rawPool);
    final shuffleRng = Random(10007 + wordLength * 313);
    pool.shuffle(shuffleRng);
    _shuffledPools[wordLength] = pool;
    return pool;
  }

  bool _isBadHint(String hint) {
    final lower = hint.toLowerCase();
    // Rejects any mention of letter count or length:
    // e.g. "5 letters long", "contains 4 letters", "4-letter word", "3 letters:"
    if (RegExp(r'\b\d+\s*letters?\b', caseSensitive: false).hasMatch(hint)) return true;
    if (RegExp(r'\b\d+-letter\b', caseSensitive: false).hasMatch(hint)) return true;
    if (RegExp(r'letters\s*long', caseSensitive: false).hasMatch(hint)) return true;
    if (RegExp(r'recognized.*word', caseSensitive: false).hasMatch(hint)) return true;
    if (RegExp(r'essential idea', caseSensitive: false).hasMatch(hint)) return true;
    if (RegExp(r'woodland concept:', caseSensitive: false).hasMatch(hint)) return true;
    if (RegExp(r'The mystery word (begins|concludes)', caseSensitive: false).hasMatch(hint)) return true;
    if (hint.startsWith('Starts with ')) return true;

    // Reject vowel mention UNLESS it mentions both start AND end:
    if (lower.contains('vowel')) {
      final hasStart = lower.contains('start') || lower.contains('begin');
      final hasEnd = lower.contains('end') || lower.contains('conclude');
      if (!hasStart || !hasEnd) return true;
    }
    return false;
  }

  /// Returns stage word puzzle based on the progression curve:
  /// word_length = min(3 + (stage // 10), 10)
  /// reward = 10 + (stage // 5)
  WordStageData generateStage(int stageNumber) {
    final stage = max(1, stageNumber);
    final wordLength = min(3 + (stage ~/ 10), 10);
    final rewardCoins = 10 + (stage ~/ 5);

    final pool = _getPoolForLength(wordLength);
    final startStage = _getStartStageForLength(wordLength);
    final offset = (stage - startStage).clamp(0, 999999);

    // Pick word using permutation offset so stages within the tier never repeat
    final chosen = pool[offset % pool.length];
    final word = chosen.word.toUpperCase().trim();
    final description = chosen.description.trim();
    final firstChar = word.isNotEmpty ? word[0] : '';
    final lastChar = word.isNotEmpty ? word[word.length - 1] : '';

    final vowelsSet = word.split('').where((c) => 'AEIOUY'.contains(c)).toSet().toList()..sort();
    final vowelsStr = vowelsSet.isNotEmpty ? vowelsSet.join(', ') : '';

    // Collect and clean candidate clues from chosen word
    final cleanedClues = <String>[];
    for (final raw in chosen.hints) {
      var h = raw.trim();
      h = h.replaceAll(RegExp(r'^[Aa]n?\s+\d+-letter\s+', caseSensitive: false), 'A ');
      if (_isBadHint(h)) continue;
      if (h.isNotEmpty && !cleanedClues.contains(h) && h != description) {
        cleanedClues.add(h);
      }
    }

    final List<String> hints = [];
    // Hint 1: Primary riddle / description
    hints.add(description.isNotEmpty ? description : "A woodland mystery word waiting to be unscrambled.");

    // Hint 2: Second descriptive / contextual clue
    if (cleanedClues.isNotEmpty) {
      hints.add(cleanedClues.first);
    } else {
      hints.add("A concept closely connected to nature, creatures, and the wild.");
    }

    // Hint 3: Start letter
    hints.add("The mystery word begins with the letter '$firstChar'.");

    // Hint 4: End letter
    hints.add("The mystery word concludes with the letter '$lastChar'.");

    // Hint 5: Start + End + Vowels (ONLY mentions vowels when BOTH start & end are specified!)
    if (vowelsStr.isNotEmpty) {
      hints.add("Starts with '$firstChar' and ends with '$lastChar', featuring vowel(s): $vowelsStr.");
    } else {
      hints.add("Starts with '$firstChar' and ends with '$lastChar'.");
    }

    // Scramble letters deterministically ensuring scrambled != word
    final scrambleRng = Random(stage * 997 + 13);
    List<String> chars = word.split('');
    List<String> scrambled = List.from(chars);
    scrambled.shuffle(scrambleRng);

    if (scrambled.join('') == word && chars.toSet().length > 1) {
      for (int i = 0; i < scrambled.length - 1; i++) {
        if (scrambled[i] != scrambled[i + 1]) {
          final temp = scrambled[i];
          scrambled[i] = scrambled[i + 1];
          scrambled[i + 1] = temp;
          break;
        }
      }
    }

    return WordStageData(
      word: word,
      description: description,
      scrambledLetters: scrambled,
      hints: hints,
      rewardCoins: rewardCoins,
    );
  }
}

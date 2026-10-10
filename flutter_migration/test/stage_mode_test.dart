import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whack_a_word_ham/services/word_service.dart';
import 'package:whack_a_word_ham/services/player_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WordService generates deterministic stage word with 5 hints', () async {
    await WordService.instance.init();
    final stage1 = WordService.instance.generateStage(1);
    expect(stage1.word.isNotEmpty, isTrue);
    expect(stage1.hints.length, greaterThanOrEqualTo(5));
    expect(stage1.scrambledLetters.length, equals(stage1.word.length));
    expect(stage1.rewardCoins, equals(10));
  });

  test('WordService scales word lengths with stage number', () async {
    await WordService.instance.init();
    final stage1 = WordService.instance.generateStage(1);
    final stage15 = WordService.instance.generateStage(15);
    final stage35 = WordService.instance.generateStage(35);

    expect(stage1.word.length, equals(3));
    expect(stage15.word.length, equals(4));
    expect(stage35.word.length, equals(6));
  });

  test('WordService avoids duplicate words across stages (stage 17 and 19 are unique)', () async {
    await WordService.instance.init();
    final stage17 = WordService.instance.generateStage(17);
    final stage19 = WordService.instance.generateStage(19);

    // Specifically test user reported issue: FISH was repeated for both 17 and 19
    expect(stage17.word, isNot(equals(stage19.word)));

    // Verify all 10 stages in tier 4 (stages 10 through 19) have unique words
    final wordsTier4 = <String>{};
    for (int s = 10; s <= 19; s++) {
      final data = WordService.instance.generateStage(s);
      expect(wordsTier4.contains(data.word), isFalse, reason: 'Stage $s word ${data.word} repeated');
      wordsTier4.add(data.word);
    }
    expect(wordsTier4.length, equals(10));

    // Verify stages 1 through 9 (tier 3) also have unique words
    final wordsTier3 = <String>{};
    for (int s = 1; s <= 9; s++) {
      final data = WordService.instance.generateStage(s);
      expect(wordsTier3.contains(data.word), isFalse, reason: 'Stage $s word ${data.word} repeated');
      wordsTier3.add(data.word);
    }
    expect(wordsTier3.length, equals(9));
  });

  test('WordService hints do not mention length and only mention vowels with start and end letters', () async {
    await WordService.instance.init();

    for (int s = 1; s <= 40; s++) {
      final data = WordService.instance.generateStage(s);
      expect(data.hints.length, equals(5));

      for (int hIdx = 0; hIdx < data.hints.length; hIdx++) {
        final hint = data.hints[hIdx];
        final lower = hint.toLowerCase();

        // Rule 1: No hint should mention how long the letters are (e.g. "5 letters long", "4-letter word", etc.)
        expect(
          RegExp(r'\b\d+\s*letters?\s*(long)?\b', caseSensitive: false).hasMatch(hint),
          isFalse,
          reason: 'Stage $s hint $hIdx mentions letter count: "$hint"',
        );
        expect(
          RegExp(r'\b\d+-letter\b', caseSensitive: false).hasMatch(hint),
          isFalse,
          reason: 'Stage $s hint $hIdx mentions letter count: "$hint"',
        );

        // Rule 2: If a hint mentions vowels, it MUST also mention both start and end letters
        if (lower.contains('vowel')) {
          final hasStart = lower.contains('start') || lower.contains('begin');
          final hasEnd = lower.contains('end') || lower.contains('conclude');
          expect(
            hasStart && hasEnd,
            isTrue,
            reason: 'Stage $s hint $hIdx mentions vowels without start & end: "$hint"',
          );
        }
      }
    }
  });

  test('PlayerDataService does not award coins on completed stage replay', () async {
    SharedPreferences.setMockInitialValues({});
    final player = PlayerDataService.instance;
    await player.resetProgress();
    // Default current stage is 1
    expect(player.currentStage, equals(1));
    final initialCoins = player.coins;

    // Completing stage 1 advances to 2
    await player.completeStage(1);
    expect(player.currentStage, equals(2));
    // completeStage alone does not grant free coins
    expect(player.coins, equals(initialCoins));

    // Replaying stage 1 (which is already cleared, 1 < 2) should NOT advance stage
    await player.completeStage(1);
    expect(player.currentStage, equals(2));
    expect(player.coins, equals(initialCoins));
  });
}

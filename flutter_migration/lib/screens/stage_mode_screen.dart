import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import '../services/word_service.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';
import '../models/accessory_model.dart';
import '../widgets/wood_letter_tile.dart';
import '../widgets/wood_hint_button.dart';
import '../widgets/wood_plank_button.dart';

const List<String> hamsterGreetings = [
  "You've got this, pal! Let's crack this word!",
  "Sniffing out the clues! Squeak squeak!",
  "Believe in yourself! Every letter counts!",
  "Take your time, buddy. I know you can solve it!",
  "Together we're unstoppable! Squeak!",
];

const List<String> wrongAttemptComments = [
  "Don't give up! Look, there's a new hint for you!",
  "So close! Tap the Hint button for a fresh clue!",
  "Paws up! A helpful hint just unlocked above!",
  "Shake it off! Check the Hint button to guide you!",
  "Mistakes make us smarter! Tap the Hint button!",
];

const List<String> hintUnlockedComments = [
  "Aha! Here is a fresh clue to guide your way!",
  "Look closely at this clue, my friend!",
  "Ooh, that's a great clue! Can you spot the word now?",
  "Every hint brings us closer to victory! Squeak!",
];

const List<String> allHintsComments = [
  "You've unlocked all 5 hints! You can do this!",
  "All clues revealed! Take a breath and arrange the letters!",
];

const List<String> solveComments = [
  "WOOHOO! Brilliant wordplay! Squeak!",
  "You did it! That was amazing! High-paw!",
  "Pure genius! Look at those shiny coins!",
];

/// Stage Mode Screen reproducing the complete StageModeScreen from stage_mode.py.
class StageModeScreen extends StatefulWidget {
  final int initialStage;
  final VoidCallback onBackToMap;

  const StageModeScreen({
    super.key,
    required this.initialStage,
    required this.onBackToMap,
  });

  @override
  State<StageModeScreen> createState() => _StageModeScreenState();
}

class _StageModeScreenState extends State<StageModeScreen> with SingleTickerProviderStateMixin {
  final PlayerDataService _player = PlayerDataService.instance;

  late int _currentStage;
  late WordStageData _stageData;
  int _attemptsCount = 1;
  int _potentialReward = 10;
  final Random _random = Random();

  String _getRandomComment(List<String> list) {
    if (list.isEmpty) return "";
    return list[_random.nextInt(list.length)];
  }

  // Assembly & Scrambled pool state
  // Each tile is represented as a unique pair (id, char)
  final List<MapEntry<int, String>> _assembledTiles = [];
  final List<MapEntry<int, String>> _scrambledTiles = [];
  final Set<int> _usedTileIds = {};

  // Hint state
  int _unlockedHintsCount = 1;
  int _currentHintIndex = 0;
  bool _hasUnreadHint = false;

  // Hamster animation & speech
  String _hamsterComment = "";
  bool _isExhaling = false;
  Timer? _breathingTimer;

  // Victory celebration state
  bool _isSolved = false;
  int _coinsAwarded = 0;
  bool _showRewardPopup = false;

  // Hop bounce animation
  late final AnimationController _hopController;
  late final Animation<double> _hopAnimation;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.initialStage;

    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -20.0).chain(CurveTween(curve: Curves.easeOutQuad)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -20.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 60),
    ]).animate(_hopController);

    AudioService.instance.playBgm('bgm_stage');
    _loadStage(_currentStage);
    _startBreathingCycle();
  }

  void _startBreathingCycle() {
    _breathingTimer?.cancel();
    _breathingTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        setState(() => _isExhaling = !_isExhaling);
      }
    });
  }

  void _loadStage(int stageNumber) {
    setState(() {
      _currentStage = stageNumber;
      _stageData = WordService.instance.generateStage(_currentStage);
      _attemptsCount = 1;
      _potentialReward = _calculateReward(_attemptsCount, _currentStage);

      _unlockedHintsCount = 1;
      _currentHintIndex = 0;
      _hasUnreadHint = false;

      _hamsterComment = _getRandomComment(hamsterGreetings);
      _isSolved = false;
      _showRewardPopup = false;

      // Initialize scrambled pool
      _scrambledTiles.clear();
      _assembledTiles.clear();
      _usedTileIds.clear();

      for (int i = 0; i < _stageData.scrambledLetters.length; i++) {
        _scrambledTiles.add(MapEntry(i, _stageData.scrambledLetters[i]));
      }
    });
  }

  int _calculateReward(int attempts, int stage) {
    final base = 10 + (max(1, stage) ~/ 5);
    if (attempts <= 1) return base;
    if (attempts == 2) return max(5, (base * 0.7).toInt());
    return max(3, (base * 0.5).toInt());
  }

  void _onScrambledTileTap(int id, String char) {
    if (_isSolved || _usedTileIds.contains(id)) return;
    setState(() {
      _usedTileIds.add(id);
      _assembledTiles.add(MapEntry(id, char));
    });
  }

  void _onAssembledTileTap(int index) {
    if (_isSolved || index >= _assembledTiles.length) return;
    setState(() {
      final removed = _assembledTiles.removeAt(index);
      _usedTileIds.remove(removed.key);
    });
  }

  void _clearAssembly() {
    if (_isSolved || _assembledTiles.isEmpty) return;
    AudioService.instance.playClick();
    setState(() {
      _assembledTiles.clear();
      _usedTileIds.clear();
    });
  }

  void _shufflePool() {
    if (_isSolved) return;
    AudioService.instance.playClick();
    setState(() {
      // Shuffle only the unused tiles in the scrambled pool
      final unusedEntries = _scrambledTiles.where((e) => !_usedTileIds.contains(e.key)).toList();
      unusedEntries.shuffle();

      final List<MapEntry<int, String>> newOrder = [];
      int unusedIdx = 0;
      for (final e in _scrambledTiles) {
        if (_usedTileIds.contains(e.key)) {
          newOrder.add(e);
        } else {
          newOrder.add(unusedEntries[unusedIdx++]);
        }
      }
      _scrambledTiles
        ..clear()
        ..addAll(newOrder);
    });
  }

  void _showPreviousHint() {
    AudioService.instance.playClick();
    if (_currentHintIndex > 0) {
      setState(() => _currentHintIndex--);
    }
  }

  void _showNextHint() {
    AudioService.instance.playClick();
    if (_currentHintIndex < _unlockedHintsCount - 1) {
      setState(() => _currentHintIndex++);
    }
  }

  void _onHintButtonClick() {
    // Strictly requires active red notification mark
    if (!_hasUnreadHint || _stageData.hints.isEmpty) return;

    setState(() {
      _hasUnreadHint = false;
      if (_unlockedHintsCount < min(5, _stageData.hints.length)) {
        AudioService.instance.playHint();
        _unlockedHintsCount++;
        _currentHintIndex = _unlockedHintsCount - 1;
        _hamsterComment = _getRandomComment(hintUnlockedComments);
      } else {
        AudioService.instance.playClick();
        _hamsterComment = _getRandomComment(allHintsComments);
      }
    });
  }

  Future<void> _submitWord() async {
    if (_isSolved) return;

    final assembledWord = _assembledTiles.map((e) => e.value).join('');
    if (assembledWord.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tap letters below to assemble the word first!"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (assembledWord.toUpperCase() == _stageData.word.toUpperCase()) {
      // SOLVED!
      _isSolved = true;
      AudioService.instance.playSuccess();
      _hopController.forward(from: 0.0);

      final isFirstClear = _currentStage >= _player.currentStage;
      if (isFirstClear) {
        _coinsAwarded = _calculateReward(_attemptsCount, _currentStage);
        await _player.addCoins(_coinsAwarded);
        await _player.completeStage(_currentStage);
      } else {
        _coinsAwarded = 0;
      }

      setState(() {
        _showRewardPopup = true;
        _hamsterComment = _getRandomComment(solveComments);
      });

      // After celebratory animation, check interstitial ad and advance
      Future.delayed(const Duration(milliseconds: 1800), () async {
        if (!mounted) return;

        final completedStage = _currentStage;
        if (AdService.instance.shouldShowInterstitial(completedStage)) {
          await AdService.instance.showInterstitialDialog(context, completedStage);
        }

        if (mounted) {
          _loadStage(completedStage + 1);
        }
      });
    } else {
      // INCORRECT!
      AudioService.instance.playWrong();
      setState(() {
        _attemptsCount++;
        _potentialReward = _calculateReward(_attemptsCount, _currentStage);
        if (_unlockedHintsCount < min(5, _stageData.hints.length)) {
          _hasUnreadHint = true;
          _hamsterComment = _getRandomComment(wrongAttemptComments);
        } else {
          _hasUnreadHint = false;
          _hamsterComment = _getRandomComment(allHintsComments);
        }
      });
    }
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _hopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equippedItem = WardrobeCatalog.findById(_player.equippedAccessory);
    final activeHintText = (_stageData.hints.isNotEmpty && _currentHintIndex < _stageData.hints.length)
        ? _stageData.hints[_currentHintIndex]
        : "Unscramble the letters to reveal the hidden word.";

    final wordLength = _stageData.word.length;
    // Responsive tile sizing
    final double tileW = wordLength >= 8 ? 38.0 : (wordLength >= 6 ? 44.0 : 50.0);
    final double tileH = wordLength >= 8 ? 44.0 : (wordLength >= 6 ? 48.0 : 54.0);

    return Scaffold(
      backgroundColor: const Color(0xFF140D06),
      body: Stack(
        children: [
          // Forest Background Artwork
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Woodland Vignette
          Positioned.fill(
            child: Container(
              color: const Color(0xC7140D06),
            ),
          ),

          // Main Layout
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                children: [
                  // Top Navigation Bar & Stats
                  Row(
                    children: [
                      // Back to Stage Map
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xE63D2919),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8D582A), width: 1.5),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFF6D6), size: 22),
                          onPressed: () {
                            AudioService.instance.playClick();
                            widget.onBackToMap();
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Stage Plaque
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xEB52331F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2B774), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_rounded, color: Color(0xFFFFD54F), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "STAGE $_currentStage",
                              style: const TextStyle(
                                color: Color(0xFFFFF6D6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Attempt Counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xE6382617),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF8D582A), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gps_fixed_rounded, color: Color(0xFFF58A1F), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Try #$_attemptsCount",
                              style: const TextStyle(
                                color: Color(0xFFFFE082),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Coins Counter
                      ListenableBuilder(
                        listenable: _player,
                        builder: (context, _) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xE6382617),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${_player.coins}",
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Hamster Cheerleader Companion & Speech Bubble Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xD92E1B0E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6E4320), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // Animated Hamster Miniature with Floor Shadow & Hop Animation
                        AnimatedBuilder(
                          animation: _hopAnimation,
                          builder: (context, _) => Transform.translate(
                            offset: Offset(0, _hopAnimation.value),
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Floor shadow
                                  Positioned(
                                    bottom: 2,
                                    child: Container(
                                      width: 42,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  // Animated Breathing Hamster Base
                                  Image.asset(
                                    _isExhaling ? 'assets/images/avatar_frame2.png' : 'assets/images/avatar_frame1.png',
                                    width: 54,
                                    height: 54,
                                  ),
                                  // Equipped accessory overlay
                                  if (equippedItem != null)
                                    Positioned(
                                      top: 4,
                                      child: Image.asset(
                                        'assets/images/${equippedItem.assetName}',
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Wooden Speech Bubble Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xE626150A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF523319)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.pets_rounded, color: Color(0xFFFFD54F), size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      "Hammy's Cheer",
                                      style: TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _hamsterComment,
                                  style: const TextStyle(
                                    color: Color(0xFFFFF6D6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Target Word Clue & Stage Signboard (Carved Plaque)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xEB382212),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF855C2E), width: 1.8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: Length + Potential Reward + Wood Hint Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$wordLength-Letter Word",
                              style: const TextStyle(
                                color: Color(0xFFFFF6D6),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            // Potential Reward Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C3B19),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD700), width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 15),
                                  const SizedBox(width: 3),
                                  Text(
                                    "+$_potentialReward C",
                                    style: const TextStyle(
                                      color: Color(0xFFFFE082),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Wood Hint Button with Red Notification Badge
                            WoodHintButton(
                              text: "HINT ($_unlockedHintsCount/5)",
                              hasBadge: _hasUnreadHint,
                              badgeText: "1",
                              onPressed: _onHintButtonClick,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Clue Timber Callout Box with Left/Right Arrow Navigation
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xE624160B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF523319)),
                          ),
                          child: Row(
                            children: [
                              // Left Arrow
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, size: 24),
                                color: _currentHintIndex > 0 ? const Color(0xFFFFD54F) : Colors.white24,
                                onPressed: _currentHintIndex > 0 ? _showPreviousHint : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              // Hint Body
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD54F), size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          "HINT ${_currentHintIndex + 1} OF $_unlockedHintsCount",
                                          style: const TextStyle(
                                            color: Color(0xFFFFD54F),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '"$activeHintText"',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFFF6D6),
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right Arrow
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, size: 24),
                                color: _currentHintIndex < _unlockedHintsCount - 1
                                    ? const Color(0xFFFFD54F)
                                    : Colors.white24,
                                onPressed:
                                    _currentHintIndex < _unlockedHintsCount - 1 ? _showNextHint : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle Hint Tiers Rule
                        Text(
                          _unlockedHintsCount > 1
                              ? "Hints Unlocked: $_unlockedHintsCount/5 (Use < > to view) • 1st: 10C, 2nd: 7C, 3+: 5C"
                              : "Hints Unlocked: 1/5 • 1st: 10C, 2nd: 7C, 3+: 5C",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFBCAAA4), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Letter Assembly Wood Tray Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xEB29170A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF6E4320), width: 1.8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Assembled Tiles or Placeholder dashes
                        if (_assembledTiles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              List.filled(wordLength, "_").join("  "),
                              style: const TextStyle(
                                color: Color(0xFFBCAAA4),
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 2.0,
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: List.generate(_assembledTiles.length, (idx) {
                              final entry = _assembledTiles[idx];
                              return WoodLetterTile(
                                letter: entry.value,
                                isAssembled: true,
                                width: tileW,
                                height: tileH,
                                onTap: () => _onAssembledTileTap(idx),
                              );
                            }),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          _assembledTiles.isNotEmpty
                              ? "Tap an assembled letter to remove it"
                              : "Tap scrambled letters below",
                          style: const TextStyle(color: Color(0xFFD7CCC8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Scrambled Letters Wood Pool Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xEB331D0E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF855C2E), width: 1.8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pool Header & Shuffle Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "AVAILABLE LETTERS",
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF523319),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shuffle_rounded, color: Color(0xFFFFD54F), size: 18),
                                onPressed: _shufflePool,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Scrambled Tiles Wrap
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _scrambledTiles.map((entry) {
                            final isUsed = _usedTileIds.contains(entry.key);
                            return WoodLetterTile(
                              letter: entry.value,
                              isAssembled: false,
                              isDisabled: isUsed,
                              width: tileW,
                              height: tileH,
                              onTap: () => _onScrambledTileTap(entry.key, entry.value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Control Action Buttons (CLEAR & SUBMIT)
                  Row(
                    children: [
                      // Clear Wood Button
                      Expanded(
                        flex: 38,
                        child: WoodPlankButton(
                          text: "CLEAR",
                          icon: Icons.refresh_rounded,
                          normalBg: 'assets/images/wood_btn_clear_wide.png',
                          pressedBg: 'assets/images/wood_btn_clear_wide_pressed.png',
                          height: 52,
                          onPressed: _clearAssembly,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Submit Wood Button
                      Expanded(
                        flex: 62,
                        child: WoodPlankButton(
                          text: "SUBMIT",
                          icon: Icons.check_circle_rounded,
                          normalBg: 'assets/images/wood_btn_play_wide.png',
                          pressedBg: 'assets/images/wood_btn_play_wide_pressed.png',
                          height: 52,
                          onPressed: _submitWord,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Floating Victory Celebration Reward Popup
          if (_showRewardPopup)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xF22E7D32),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 28),
                    const SizedBox(width: 8),
                    Text(
                      "+$_coinsAwarded COINS!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
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

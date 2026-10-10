import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/letter_tile_component.dart';
import 'components/hamster_component.dart';
import '../services/word_service.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';

/// WhackGame is the central gameplay coordinator for Whack-A-Word-Ham.
class WhackGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  static const double virtualWidth = 400.0;
  static const double virtualHeight = 750.0;

  WhackGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: virtualWidth,
            height: virtualHeight,
          ),
        );

  // Reactive state notifiers for Flutter HUD overlays
  final ValueNotifier<int> stageNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> coinsNotifier = ValueNotifier<int>(150);
  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<String>> assembledLettersNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<String> currentHintNotifier = ValueNotifier<String>('');

  WordStageData? currentStageData;
  final List<String> currentPoolLetters = [];
  final List<String> assembledLetters = [];
  int _currentHintIndex = 0;

  String get targetWord => currentStageData?.word ?? '';

  HamsterComponent? hamster;

  @override
  Color backgroundColor() => const Color(0xFF1E140A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.position = Vector2(virtualWidth / 2, virtualHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    // Initialize player data & words dictionary
    await PlayerDataService.instance.init();
    await WordService.instance.init();
    await AudioService.instance.init();

    coinsNotifier.value = PlayerDataService.instance.coins;
    stageNotifier.value = PlayerDataService.instance.currentStage;

    // Spawn Hamster Companion
    hamster = HamsterComponent(
      position: Vector2(virtualWidth / 2, 220),
      size: Vector2(140, 140),
    );
    world.add(hamster!);

    // Start background music
    AudioService.instance.playBgm('bgm_stage');

    // Load active stage
    loadStage(stageNotifier.value);
  }

  void loadStage(int stageNumber) {
    stageNotifier.value = stageNumber;
    _currentHintIndex = 0;

    currentStageData = WordService.instance.generateStage(stageNumber);
    currentPoolLetters
      ..clear()
      ..addAll(currentStageData!.scrambledLetters);

    assembledLetters.clear();
    assembledLettersNotifier.value = [];
    currentHintNotifier.value = currentStageData!.hints.isNotEmpty
        ? currentStageData!.hints[0]
        : "Tap the letters below to assemble the word!";

    _renderTiles();
  }

  void _renderTiles() {
    world.removeAll(world.children.whereType<LetterTileComponent>());

    const double tileWidth = 46.0;
    const double tileHeight = 54.0;
    const double spacing = 6.0;
    final int count = currentPoolLetters.length;
    final double totalW = (count * tileWidth) + ((count - 1) * spacing);
    final double startX = (virtualWidth - totalW) / 2;

    for (int i = 0; i < count; i++) {
      final letter = currentPoolLetters[i];
      world.add(LetterTileComponent(
        letter: letter,
        size: Vector2(tileWidth, tileHeight),
        position: Vector2(startX + (i * (tileWidth + spacing)), 480),
        onTapCallback: (selectedLetter) => onPoolTileClicked(i, selectedLetter),
      ));
    }
  }

  void onPoolTileClicked(int index, String letter) {
    if (index >= currentPoolLetters.length) return;

    currentPoolLetters.removeAt(index);
    assembledLetters.add(letter);
    assembledLettersNotifier.value = List.from(assembledLetters);

    AudioService.instance.playTileTap();
    _renderTiles();

    // Check if player solved the word
    if (assembledLetters.length == currentStageData!.word.length) {
      if (assembledLetters.join('') == currentStageData!.word) {
        onStageCompleted();
      } else {
        AudioService.instance.playWrong();
      }
    }
  }

  void onAssembledTileClicked(int index) {
    if (index >= assembledLetters.length) return;

    final returnedLetter = assembledLetters.removeAt(index);
    currentPoolLetters.add(returnedLetter);
    assembledLettersNotifier.value = List.from(assembledLetters);

    AudioService.instance.playTileTap();
    _renderTiles();
  }

  void resetAssembly() {
    if (assembledLetters.isEmpty) return;
    currentPoolLetters.addAll(assembledLetters);
    assembledLetters.clear();
    assembledLettersNotifier.value = [];
    AudioService.instance.playClick();
    _renderTiles();
  }

  void shufflePool() {
    currentPoolLetters.shuffle();
    AudioService.instance.playClick();
    _renderTiles();
  }

  void revealNextHint() {
    if (currentStageData == null || currentStageData!.hints.isEmpty) return;
    _currentHintIndex = (_currentHintIndex + 1) % currentStageData!.hints.length;
    currentHintNotifier.value = currentStageData!.hints[_currentHintIndex];
    AudioService.instance.playHint();
    hamster?.hop();
  }

  Future<void> onStageCompleted() async {
    AudioService.instance.playSuccess();
    hamster?.hop();

    final isFirstClear = stageNotifier.value >= PlayerDataService.instance.currentStage;
    if (isFirstClear) {
      await PlayerDataService.instance.completeStage(stageNotifier.value);
      coinsNotifier.value = PlayerDataService.instance.coins;
      scoreNotifier.value += 100;
    }

    overlays.add('StageCleared');
  }

  void advanceToNextStage() {
    overlays.remove('StageCleared');
    loadStage(stageNotifier.value + 1);
  }

  void refreshWardrobe() {
    hamster?.updateAccessory();
  }

  @override
  void onRemove() {
    stageNotifier.dispose();
    coinsNotifier.dispose();
    scoreNotifier.dispose();
    assembledLettersNotifier.dispose();
    currentHintNotifier.dispose();
    AudioService.instance.stopBgm();
    super.onRemove();
  }
}

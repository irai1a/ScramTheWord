import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'player_data_service.dart';

/// Central Audio Service managing BGM loops and SFX sound effects via flame_audio.
class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  bool isTestEnvironment = false;
  String? _currentBgm;

  Future<void> init() async {
    if (isTestEnvironment) return;
    try {
      // Preload sound effects into memory for instant zero-latency playback
      await FlameAudio.audioCache.loadAll([
        'sfx_click.wav',
        'sfx_tile.wav',
        'sfx_success.wav',
        'sfx_wrong.wav',
        'sfx_hint.wav',
      ]);
    } catch (e) {
      debugPrint("[AudioService] Preload warning: $e");
    }
  }

  void playSfx(String fileName) {
    if (isTestEnvironment) return;
    final player = PlayerDataService.instance;
    if (!player.sfxEnabled) return;
    try {
      FlameAudio.play(fileName, volume: player.sfxVolume);
    } catch (e) {
      debugPrint("[AudioService] SFX playback error ($fileName): $e");
    }
  }

  void playClick() => playSfx('sfx_click.wav');
  void playTileTap() => playSfx('sfx_tile.wav');
  void playSuccess() => playSfx('sfx_success.wav');
  void playWrong() => playSfx('sfx_wrong.wav');
  void playHint() => playSfx('sfx_hint.wav');

  Future<void> playBgm(String trackName) async {
    if (isTestEnvironment) return;
    final player = PlayerDataService.instance;
    if (_currentBgm == trackName) return;
    _currentBgm = trackName;

    if (!player.musicEnabled) {
      FlameAudio.bgm.stop();
      return;
    }

    try {
      final fileName = '$trackName.wav';
      await FlameAudio.bgm.play(fileName, volume: player.musicVolume);
    } catch (e) {
      debugPrint("[AudioService] BGM playback error ($trackName): $e");
    }
  }

  void updateVolumes() {
    final player = PlayerDataService.instance;
    if (!player.musicEnabled) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
    }
  }

  void stopBgm() {
    FlameAudio.bgm.stop();
    _currentBgm = null;
  }
}

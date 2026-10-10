import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent Player Data Manager for Whack-A-Word-Ham.
/// Handles coins, current stage progress, high score, and unlocked/equipped wardrobe accessories.
class PlayerDataService extends ChangeNotifier {
  static const String _prefKey = 'player_data_v1';

  int _currentStage = 16;
  int _coins = 94;
  int _highScore = 0;
  List<String> _unlockedAccessories = ['cap', 'glasses', 'headphones'];
  String _equippedAccessory = 'glasses';
  double _musicVolume = 0.60;
  double _sfxVolume = 0.88;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;

  int get currentStage => _currentStage;
  int get coins => _coins;
  int get highScore => _highScore;
  List<String> get unlockedAccessories => List.unmodifiable(_unlockedAccessories);
  String get equippedAccessory => _equippedAccessory;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  static final PlayerDataService instance = PlayerDataService._internal();
  PlayerDataService._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_prefKey);
    if (dataString != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(dataString);
        _currentStage = (data['current_stage'] as num?)?.toInt() ?? 16;
        _coins = (data['coins'] as num?)?.toInt() ?? 94;
        _highScore = (data['high_score'] as num?)?.toInt() ?? 0;
        _unlockedAccessories = List<String>.from(data['unlocked_accessories'] ?? ['cap', 'glasses', 'headphones']);
        _equippedAccessory = data['equipped_accessory']?.toString() ?? 'glasses';
        _musicVolume = (data['music_volume'] as num?)?.toDouble() ?? 0.60;
        _sfxVolume = (data['sfx_volume'] as num?)?.toDouble() ?? 0.88;
        _musicEnabled = data['music_enabled'] as bool? ?? true;
        _sfxEnabled = data['sfx_enabled'] as bool? ?? true;
      } catch (e) {
        debugPrint("[PlayerDataService] Error loading data: $e");
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'current_stage': _currentStage,
      'coins': _coins,
      'high_score': _highScore,
      'unlocked_accessories': _unlockedAccessories,
      'equipped_accessory': _equippedAccessory,
      'music_volume': _musicVolume,
      'sfx_volume': _sfxVolume,
      'music_enabled': _musicEnabled,
      'sfx_enabled': _sfxEnabled,
    };
    await prefs.setString(_prefKey, jsonEncode(data));
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    await _save();
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      await _save();
      return true;
    }
    return false;
  }

  Future<void> completeStage(int completedStage) async {
    if (completedStage >= _currentStage) {
      _currentStage = completedStage + 1;
      _highScore += 100;
      await _save();
    }
  }

  Future<void> unlockAccessory(String id) async {
    if (!_unlockedAccessories.contains(id)) {
      _unlockedAccessories.add(id);
      await _save();
    }
  }

  Future<void> equipAccessory(String id) async {
    _equippedAccessory = id;
    await _save();
  }

  Future<void> setMusicSettings({required bool enabled, required double volume}) async {
    _musicEnabled = enabled;
    _musicVolume = volume.clamp(0.0, 1.0);
    await _save();
  }

  Future<void> setSfxSettings({required bool enabled, required double volume}) async {
    _sfxEnabled = enabled;
    _sfxVolume = volume.clamp(0.0, 1.0);
    await _save();
  }

  Future<void> resetProgress() async {
    _currentStage = 1;
    _coins = 150;
    _highScore = 0;
    _unlockedAccessories.clear();
    _equippedAccessory = 'empty';
    await _save();
  }
}

import 'package:flutter/material.dart';
import '../game/whack_game.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';

class SettingsOverlay extends StatefulWidget {
  final WhackGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  final PlayerDataService _player = PlayerDataService.instance;

  late bool _musicEnabled;
  late double _musicVolume;
  late bool _sfxEnabled;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    _musicEnabled = _player.musicEnabled;
    _musicVolume = _player.musicVolume;
    _sfxEnabled = _player.sfxEnabled;
    _sfxVolume = _player.sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF38220F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2B774), width: 3),
              boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  "AUDIO SETTINGS",
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 18),

                // Music Toggle & Slider
                Row(
                  children: [
                    Icon(
                      _musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
                      color: const Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 8),
                    const Text("Music", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Switch(
                      value: _musicEnabled,
                      activeThumbColor: const Color(0xFFFFD54F),
                      onChanged: (val) {
                        setState(() => _musicEnabled = val);
                        _player.setMusicSettings(enabled: _musicEnabled, volume: _musicVolume);
                        AudioService.instance.updateVolumes();
                      },
                    ),
                  ],
                ),
                Slider(
                  value: _musicVolume,
                  activeColor: const Color(0xFFFFD54F),
                  inactiveColor: Colors.brown.shade800,
                  onChanged: _musicEnabled
                      ? (val) {
                          setState(() => _musicVolume = val);
                          _player.setMusicSettings(enabled: _musicEnabled, volume: _musicVolume);
                          AudioService.instance.updateVolumes();
                        }
                      : null,
                ),

                const SizedBox(height: 8),

                // Sound Effects Toggle & Slider
                Row(
                  children: [
                    Icon(
                      _sfxEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: const Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 8),
                    const Text("Sound FX", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Switch(
                      value: _sfxEnabled,
                      activeThumbColor: const Color(0xFFFFD54F),
                      onChanged: (val) {
                        setState(() => _sfxEnabled = val);
                        _player.setSfxSettings(enabled: _sfxEnabled, volume: _sfxVolume);
                      },
                    ),
                  ],
                ),
                Slider(
                  value: _sfxVolume,
                  activeColor: const Color(0xFFFFD54F),
                  inactiveColor: Colors.brown.shade800,
                  onChanged: _sfxEnabled
                      ? (val) {
                          setState(() => _sfxVolume = val);
                          _player.setSfxSettings(enabled: _sfxEnabled, volume: _sfxVolume);
                        }
                      : null,
                ),

                const Divider(color: Color(0xFF5A361B), height: 24, thickness: 1.5),

                // Reset Progress Button
                TextButton.icon(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                  label: const Text(
                    "Reset Game Progress",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _showResetConfirmation(context),
                ),

                const SizedBox(height: 12),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF543310),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2B774), width: 1.5),
                      ),
                    ),
                    onPressed: () {
                      AudioService.instance.playClick();
                      widget.game.overlays.remove('Settings');
                      widget.game.resumeEngine();
                    },
                    child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF38220F),
        title: const Text("Reset Progress?", style: TextStyle(color: Color(0xFFFFD54F))),
        content: const Text(
          "This will reset your current stage, coin balance, and wardrobe accessories back to Level 1. Are you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            child: const Text("RESET ALL", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx);
              await _player.resetProgress();
              widget.game.coinsNotifier.value = _player.coins;
              widget.game.loadStage(1);
              widget.game.refreshWardrobe();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Game progress has been reset.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

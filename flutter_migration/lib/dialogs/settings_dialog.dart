import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';

/// Modal dialog for BGM and SFX volume controls.
/// Replicates SettingsDialog from the original Python Kivy settings_dialog.py.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _bgmVolume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();
    final player = PlayerDataService.instance;
    _bgmVolume = player.musicVolume;
    _sfxVolume = player.sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF332414),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF855C2E), width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_rounded, color: Color(0xFFFFD54F), size: 26),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Audio Settings",
                          style: TextStyle(
                            color: Color(0xFFFFF6D6),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Customize game volume",
                          style: TextStyle(
                            color: Color(0xFFD7CCC8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFFFF6D6)),
                  onPressed: () {
                    AudioService.instance.playClick();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Music Volume Row
            const Row(
              children: [
                Icon(Icons.music_note_rounded, color: Color(0xFFFFD54F), size: 20),
                SizedBox(width: 6),
                Text(
                  "Background Music (BGM)",
                  style: TextStyle(color: Color(0xFFFFF6D6), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF5BD2E),
                      inactiveTrackColor: const Color(0xFF1E140A),
                      thumbColor: const Color(0xFFFFD54F),
                      overlayColor: const Color(0x33FFD54F),
                    ),
                    child: Slider(
                      value: _bgmVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        setState(() => _bgmVolume = val);
                        PlayerDataService.instance.setMusicSettings(enabled: val > 0.01, volume: val);
                        AudioService.instance.updateVolumes();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    "${(_bgmVolume * 100).toInt()}%",
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SFX Volume Row
            const Row(
              children: [
                Icon(Icons.volume_up_rounded, color: Color(0xFFFFD54F), size: 20),
                SizedBox(width: 6),
                Text(
                  "Sound Effects (SFX)",
                  style: TextStyle(color: Color(0xFFFFF6D6), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFF5BD2E),
                      inactiveTrackColor: const Color(0xFF1E140A),
                      thumbColor: const Color(0xFFFFD54F),
                      overlayColor: const Color(0x33FFD54F),
                    ),
                    child: Slider(
                      value: _sfxVolume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (val) {
                        setState(() => _sfxVolume = val);
                        PlayerDataService.instance.setSfxSettings(enabled: val > 0.01, volume: val);
                      },
                      onChangeEnd: (val) {
                        AudioService.instance.playClick();
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    "${(_sfxVolume * 100).toInt()}%",
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A361B),
                  foregroundColor: const Color(0xFFFFF6D6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF855C2E), width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  AudioService.instance.playClick();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "DONE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../game/whack_game.dart';
import '../services/audio_service.dart';

/// Fullscreen pause / main menu overlay.
class StartMenuOverlay extends StatelessWidget {
  final WhackGame game;

  const StartMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF38220F),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2B774), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  "WHACK-A-WORD-HAM",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Woodland Word Scramble",
                  style: TextStyle(fontSize: 13, color: Color(0xFFD7CCC8)),
                ),
                const Divider(color: Color(0xFF7A4A1C), height: 28, thickness: 1.5),

                // Resume Game
                _buildMenuButton(
                  label: "RESUME GAME",
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xFF2E7D32),
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.overlays.remove('StartMenu');
                    game.resumeEngine();
                  },
                ),
                const SizedBox(height: 10),

                // Stage Map
                _buildMenuButton(
                  label: "STAGE MAP",
                  icon: Icons.map_rounded,
                  color: const Color(0xFF1565C0),
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.overlays.remove('StartMenu');
                    game.overlays.add('MapScreen');
                  },
                ),
                const SizedBox(height: 10),

                // Wardrobe Shop
                _buildMenuButton(
                  label: "WARDROBE SHOP",
                  icon: Icons.checkroom_rounded,
                  color: const Color(0xFFE65100),
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.overlays.remove('StartMenu');
                    game.overlays.add('WardrobeShop');
                  },
                ),
                const SizedBox(height: 10),

                // Restart Stage
                _buildMenuButton(
                  label: "RESTART STAGE",
                  icon: Icons.replay_rounded,
                  color: const Color(0xFF5D4037),
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.overlays.remove('StartMenu');
                    game.loadStage(game.stageNotifier.value);
                    game.resumeEngine();
                  },
                ),
                const SizedBox(height: 10),

                // Settings
                _buildMenuButton(
                  label: "SETTINGS",
                  icon: Icons.settings_rounded,
                  color: const Color(0xFF4527A0),
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.overlays.add('Settings');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2B774), width: 1.5),
          ),
          elevation: 4,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1),
        ),
      ),
    );
  }
}

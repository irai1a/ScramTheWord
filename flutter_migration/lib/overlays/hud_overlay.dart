import 'package:flutter/material.dart';
import '../game/whack_game.dart';
import '../services/audio_service.dart';

/// Comprehensive HUD overlay for gameplay.
/// Completely wrapped in SafeArea to guarantee safety from notches and gesture bars.
class HudOverlay extends StatelessWidget {
  final WhackGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        child: Column(
          children: [
            // Top Bar: Pause | Map | Stage Badge | Wardrobe | Coins
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pause Menu
                _buildCircleButton(
                  icon: Icons.pause_rounded,
                  tooltip: "Menu",
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.pauseEngine();
                    game.overlays.add('StartMenu');
                  },
                ),

                // Map Navigation Button
                _buildCircleButton(
                  icon: Icons.map_rounded,
                  tooltip: "Stage Map",
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.pauseEngine();
                    game.overlays.add('MapScreen');
                  },
                ),

                // Stage Badge
                ValueListenableBuilder<int>(
                  valueListenable: game.stageNotifier,
                  builder: (context, stage, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A2E18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2B774), width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      "STAGE $stage",
                      style: const TextStyle(
                        color: Color(0xFFFFF6D6),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                // Wardrobe Shop Button
                _buildCircleButton(
                  icon: Icons.checkroom_rounded,
                  tooltip: "Wardrobe Shop",
                  onPressed: () {
                    AudioService.instance.playClick();
                    game.pauseEngine();
                    game.overlays.add('WardrobeShop');
                  },
                ),

                // Golden Coin Badge
                ValueListenableBuilder<int>(
                  valueListenable: game.coinsNotifier,
                  builder: (context, coins, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B180A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hint Clue Plaque
            ValueListenableBuilder<String>(
              valueListenable: game.currentHintNotifier,
              builder: (context, hintText, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xCC3E2512),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF8D582A), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD54F), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hintText,
                        style: const TextStyle(
                          color: Color(0xFFFFF3E0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, color: Color(0xFFFFB74D), size: 20),
                      tooltip: "Next Hint",
                      onPressed: game.revealNextHint,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Middle: Interactive Assembled Word Slots
            ValueListenableBuilder<List<String>>(
              valueListenable: game.assembledLettersNotifier,
              builder: (context, assembled, _) {
                final targetLen = game.currentStageData?.word.length ?? 5;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xDD271609),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7A4A1C), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(targetLen, (index) {
                      final hasLetter = index < assembled.length;
                      final letter = hasLetter ? assembled[index] : '';

                      return GestureDetector(
                        onTap: hasLetter ? () => game.onAssembledTileClicked(index) : null,
                        child: Container(
                          width: 42,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: hasLetter ? const Color(0xFFE2B774) : const Color(0xFF422814),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasLetter ? const Color(0xFF8D582A) : const Color(0xFF5A361B),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: Color(0xFF2B180A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),

            const SizedBox(height: 110), // Space above Flame's scrambled tile row (y: 480)

            // Bottom Controls: Shuffle & Reset Assembly
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.shuffle_rounded,
                    label: "SHUFFLE",
                    color: const Color(0xFF6D4C41),
                    onPressed: game.shufflePool,
                  ),
                  _buildActionButton(
                    icon: Icons.refresh_rounded,
                    label: "CLEAR",
                    color: const Color(0xFF8D6E63),
                    onPressed: game.resetAssembly,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF543310),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2B774), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFFFFF6D6), size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: const Color(0xFFFFF6D6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2B774), width: 1.5),
        ),
        elevation: 4,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: const Color(0xFFFFD54F)),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

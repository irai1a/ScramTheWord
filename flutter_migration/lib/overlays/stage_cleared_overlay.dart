import 'package:flutter/material.dart';
import '../game/whack_game.dart';

/// Level victory overlay modal triggered when a player solves a word puzzle.
class StageClearedOverlay extends StatelessWidget {
  final WhackGame game;

  const StageClearedOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: SafeArea(
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E1C0C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Golden Trophy Icon
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 64),
                const SizedBox(height: 12),

                // Victory Title
                const Text(
                  "STAGE CLEARED!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF6D6),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Solved Word Display
                Text(
                  "Word: ${game.targetWord}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFE082),
                  ),
                ),
                const SizedBox(height: 16),

                // Coin Reward Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF422812),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 22),
                      SizedBox(width: 8),
                      Text(
                        "+10 COINS EARNED!",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Next Stage Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFF81C784), width: 2),
                      ),
                      elevation: 4,
                    ),
                    onPressed: game.advanceToNextStage,
                    child: const Text(
                      "NEXT STAGE",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

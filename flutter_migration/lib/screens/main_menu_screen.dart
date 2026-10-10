import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';
import '../widgets/wood_plank_button.dart';
import '../dialogs/settings_dialog.dart';

/// Main Menu screen displaying game title artwork, player stats, and primary wood buttons.
/// Replicates MainMenuScreen from the original Python Kivy main.py.
class MainMenuScreen extends StatefulWidget {
  final VoidCallback onPlayStageMode;
  final VoidCallback onOpenWardrobe;

  const MainMenuScreen({
    super.key,
    required this.onPlayStageMode,
    required this.onOpenWardrobe,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final PlayerDataService _player = PlayerDataService.instance;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playBgm('bgm_main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140D06),
      body: Stack(
        children: [
          // Forest Artwork Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Foreground Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // Top Bar with Quick Stats & Settings Cog
                  ListenableBuilder(
                    listenable: _player,
                    builder: (context, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Player Level Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xD11A1E2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2B774), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_rounded, color: Color(0xFFFFC107), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "STAGE ${_player.currentStage}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Coins Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xD11A1E2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "${_player.coins}",
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Audio Settings Button
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xE63D2919),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF8D582A), width: 1.5),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.settings_rounded, color: Color(0xFFFFEBBF), size: 22),
                            onPressed: () => SettingsDialog.show(context),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Spacer: Showcases the Whack-A-Word-Ham title & hamster holding blocks
                  const Spacer(),

                  // Wood Themed Navigation Buttons Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Button 1: Play Stage Mode (Warm Honey Oak Plank)
                        WoodPlankButton(
                          text: "PLAY STAGE MODE",
                          icon: Icons.play_circle_filled_rounded,
                          normalBg: 'assets/images/wood_btn_play_wide.png',
                          pressedBg: 'assets/images/wood_btn_play_wide_pressed.png',
                          height: 64,
                          onPressed: widget.onPlayStageMode,
                        ),
                        const SizedBox(height: 12),

                        // Button 2: Hamster Wardrobe (Carved Timber Plank)
                        WoodPlankButton(
                          text: "HAMSTER WARDROBE",
                          icon: Icons.checkroom_rounded,
                          normalBg: 'assets/images/wood_btn_shop_wide.png',
                          pressedBg: 'assets/images/wood_btn_shop_wide_pressed.png',
                          height: 58,
                          onPressed: widget.onOpenWardrobe,
                        ),
                        const SizedBox(height: 12),

                        // Button 3: Multiplayer (Ranked) - Weathered Driftwood Plank
                        const WoodPlankButton(
                          text: "MULTIPLAYER",
                          icon: Icons.emoji_events_outlined,
                          normalBg: 'assets/images/wood_btn_multiplayer_wide.png',
                          pressedBg: 'assets/images/wood_btn_multiplayer_wide.png',
                          badgeText: "COMING SOON",
                          isDisabled: true,
                          height: 54,
                          textColor: Color(0xFFB0BEC5),
                          iconColor: Color(0xFF90A4AE),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtle Footer
                  const Text(
                    "Whack-A-Word_Ham • Hamster Word Adventure",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 0.5,
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

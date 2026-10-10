import 'package:flutter/material.dart';
import '../game/whack_game.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';

class WorldTheme {
  final String name;
  final Color primaryColor;
  final IconData icon;

  const WorldTheme({required this.name, required this.primaryColor, required this.icon});
}

class MapOverlay extends StatefulWidget {
  final WhackGame game;

  const MapOverlay({super.key, required this.game});

  @override
  State<MapOverlay> createState() => _MapOverlayState();
}

class _MapOverlayState extends State<MapOverlay> {
  final ScrollController _scrollController = ScrollController();
  final PlayerDataService _player = PlayerDataService.instance;

  static const List<WorldTheme> themes = [
    WorldTheme(name: "Woodland Forest", primaryColor: Color(0xFF27AE60), icon: Icons.park_rounded),
    WorldTheme(name: "Sunny Sunflower Meadow", primaryColor: Color(0xFFF39C12), icon: Icons.local_florist_rounded),
    WorldTheme(name: "Cozy Kitchen Pantry", primaryColor: Color(0xFFD35400), icon: Icons.cake_rounded),
    WorldTheme(name: "Glowing Underground Burrow", primaryColor: Color(0xFF8E44AD), icon: Icons.auto_awesome_rounded),
    WorldTheme(name: "Golden Autumn Acorn Forest", primaryColor: Color(0xFFC0392B), icon: Icons.eco_rounded),
  ];

  WorldTheme _getThemeForStage(int stage) {
    final chapterIndex = ((stage - 1) ~/ 30) % themes.length;
    return themes[chapterIndex];
  }

  int _calculateTotalStages(int currentStage) {
    if (currentStage < 30) return 30;
    return (((currentStage - 1) ~/ 30) + 1) * 30;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-scroll to player's current stage position
      final current = _player.currentStage;
      final targetOffset = (current - 1) * 72.0;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = _player.currentStage;
    final totalStages = _calculateTotalStages(currentStage);
    final activeTheme = _getThemeForStage(currentStage);

    return Container(
      color: const Color(0xF61C1107),
      child: SafeArea(
        child: Column(
          children: [
            // Header Plaque
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF38220F),
                border: Border(bottom: BorderSide(color: Color(0xFF5A361B), width: 2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFF6D6), size: 26),
                    onPressed: () {
                      AudioService.instance.playClick();
                      widget.game.overlays.remove('MapScreen');
                      widget.game.resumeEngine();
                    },
                  ),
                  const SizedBox(width: 8),
                  Icon(activeTheme.icon, color: activeTheme.primaryColor, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "STAGE MAP",
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          activeTheme.name,
                          style: TextStyle(
                            color: activeTheme.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Lv. $currentStage",
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Stepping Stone Trail List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: totalStages,
                itemBuilder: (context, index) {
                  final stageNumber = index + 1;
                  final theme = _getThemeForStage(stageNumber);
                  final isUnlocked = stageNumber <= currentStage;
                  final isCurrent = stageNumber == currentStage;
                  final isMilestone = stageNumber % 30 == 0;
                  final isChapterStart = (stageNumber - 1) % 30 == 0 && stageNumber > 1;

                  return Column(
                    children: [
                      // Chapter Entrance Banner
                      if (isChapterStart)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.primaryColor, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(theme.icon, color: theme.primaryColor, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                "CHAPTER ${((stageNumber - 1) ~/ 30) + 1}: ${theme.name.toUpperCase()}",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Stepping Stone Node
                      GestureDetector(
                        onTap: isUnlocked
                            ? () {
                                AudioService.instance.playClick();
                                widget.game.loadStage(stageNumber);
                                widget.game.overlays.remove('MapScreen');
                                widget.game.resumeEngine();
                              }
                            : () {
                                AudioService.instance.playWrong();
                              },
                        child: Container(
                          width: isCurrent ? 84 : 70,
                          height: isCurrent ? 64 : 54,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFFFFF6D6)
                                : isUnlocked
                                    ? theme.primaryColor
                                    : const Color(0xFF33200F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFFFFD700)
                                  : isUnlocked
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : const Color(0xFF4E3018),
                              width: isCurrent ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isCurrent ? theme.primaryColor.withValues(alpha: 0.5) : Colors.black45,
                                blurRadius: isCurrent ? 8 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isMilestone
                                ? const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 28)
                                : isCurrent
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.play_arrow_rounded, color: Color(0xFF2B180A), size: 20),
                                          Text(
                                            "$stageNumber",
                                            style: const TextStyle(
                                              color: Color(0xFF2B180A),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "$stageNumber",
                                        style: TextStyle(
                                          color: isUnlocked ? Colors.white : Colors.white30,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

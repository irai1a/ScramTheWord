import 'dart:math';
import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';
import '../services/word_service.dart';
import '../models/accessory_model.dart';
import '../dialogs/settings_dialog.dart';

class MapTheme {
  final String id;
  final String name;
  final IconData icon;
  final String tagline;
  final Color completedColor;
  final Color completedBorder;
  final Color activeColor;
  final Color activeBorder;
  final Color bannerBg;
  final Color bannerBorder;

  const MapTheme({
    required this.id,
    required this.name,
    required this.icon,
    required this.tagline,
    required this.completedColor,
    required this.completedBorder,
    required this.activeColor,
    required this.activeBorder,
    required this.bannerBg,
    required this.bannerBorder,
  });
}

const List<MapTheme> mapThemes = [
  MapTheme(
    id: "woodland_forest",
    name: "Woodland Forest",
    icon: Icons.park_rounded,
    tagline: "Whispering pines & shaded mossy trails",
    completedColor: Color(0xFF24A347),
    completedBorder: Color(0xFF61E07A),
    activeColor: Color(0xFFF58A1F),
    activeBorder: Color(0xFFFFE059),
    bannerBg: Color(0xF23D291A),
    bannerBorder: Color(0xFFE0B852),
  ),
  MapTheme(
    id: "sunflower_meadow",
    name: "Sunny Sunflower Meadow",
    icon: Icons.local_florist_rounded,
    tagline: "Golden petals swaying in the sunlit breeze",
    completedColor: Color(0xFFD99A1A),
    completedBorder: Color(0xFFFFD147),
    activeColor: Color(0xFFFAB824),
    activeBorder: Color(0xFFFFEB73),
    bannerBg: Color(0xF2523810),
    bannerBorder: Color(0xFFFFD940),
  ),
  MapTheme(
    id: "kitchen_pantry",
    name: "Cozy Kitchen Pantry",
    icon: Icons.cake_rounded,
    tagline: "Warm biscuit crusts & sweet cinnamon spice",
    completedColor: Color(0xFFC26133),
    completedBorder: Color(0xFFF09461),
    activeColor: Color(0xFFF07538),
    activeBorder: Color(0xFFFFBD80),
    bannerBg: Color(0xF247291A),
    bannerBorder: Color(0xFFF2AE73),
  ),
  MapTheme(
    id: "underground_burrow",
    name: "Glowing Underground Burrow",
    icon: Icons.auto_awesome_rounded,
    tagline: "Bioluminescent fungi & secret gem caverns",
    completedColor: Color(0xFF1F8EAD),
    completedBorder: Color(0xFF4DCDEC),
    activeColor: Color(0xFF33BDDC),
    activeBorder: Color(0xFF85EAFA),
    bannerBg: Color(0xF21A2E3D),
    bannerBorder: Color(0xFF73E6F5),
  ),
  MapTheme(
    id: "autumn_forest",
    name: "Golden Autumn Acorn Forest",
    icon: Icons.eco_rounded,
    tagline: "Crisp amber leaves & ripe fallen acorns",
    completedColor: Color(0xFFC24726),
    completedBorder: Color(0xFFF27B5C),
    activeColor: Color(0xFFE65C2B),
    activeBorder: Color(0xFFFF9E73),
    bannerBg: Color(0xF24D2114),
    bannerBorder: Color(0xFFF28F6B),
  ),
];

/// Stage Map Screen replicating MapScreen from Kivy map_screen.py.
class MapScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;
  final void Function(int stageNumber) onLaunchStage;

  const MapScreen({
    super.key,
    required this.onBackToMenu,
    required this.onLaunchStage,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ScrollController _scrollController = ScrollController();
  final PlayerDataService _player = PlayerDataService.instance;

  MapTheme _getThemeForStage(int stage) {
    final chapter = ((stage - 1) ~/ 30) % mapThemes.length;
    return mapThemes[chapter];
  }

  int _calculateTotalStages(int currentStage) {
    return max(30, (((currentStage - 1) ~/ 30) + 1) * 30);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-scroll to player's current stage node
      final current = _player.currentStage;
      final targetOffset = max(0.0, (current - 1) * 95.0 - 200.0);
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = _player.currentStage;
    final totalStages = _calculateTotalStages(currentStage);
    final currentTheme = _getThemeForStage(currentStage);
    final equippedItem = WardrobeCatalog.findById(_player.equippedAccessory);

    return Scaffold(
      backgroundColor: const Color(0xFF140D06),
      body: Stack(
        children: [
          // Background Artwork
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Woodland Vignette
          Positioned.fill(
            child: Container(
              color: const Color(0xC2140D06),
            ),
          ),

          // Main Column
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  child: Row(
                    children: [
                      // Back Button to Main Menu
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xE63D2919),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8D582A), width: 1.5),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFF6D6), size: 22),
                          onPressed: () {
                            AudioService.instance.playClick();
                            widget.onBackToMenu();
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Title Wood Plaque
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xEB52331F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2B774), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(currentTheme.icon, color: const Color(0xFFFFD54F), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "STAGE MAP",
                                      style: TextStyle(
                                        color: Color(0xFFFFF6D6),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      currentTheme.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFFFD54F),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Coins Counter
                      ListenableBuilder(
                        listenable: _player,
                        builder: (context, _) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xE6382617),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${_player.coins}",
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Settings Cog
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xE63D2919),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8D582A), width: 1.5),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_rounded, color: Color(0xFFFFEBBF), size: 20),
                          onPressed: () => SettingsDialog.show(context),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Vertical Progression Trail (Winding Path)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    itemCount: totalStages,
                    itemBuilder: (context, index) {
                      final stageNum = index + 1;
                      final theme = _getThemeForStage(stageNum);
                      final isCompleted = stageNum < currentStage;
                      final isActive = stageNum == currentStage;
                      final isLocked = stageNum > currentStage;
                      final isMilestone = (stageNum % 10 == 0);
                      final isChapterMilestone = (stageNum % 30 == 0);
                      final isChapterStart = ((stageNum - 1) % 30 == 0);

                      // Calculate horizontal winding zigzag offset (-50 to +50 px)
                      final angle = (stageNum * 0.7);
                      final horizontalOffset = sin(angle) * 70.0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Chapter Entrance Banner Card at stage 1, 31, 61, 91...
                          if (isChapterStart) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 10, bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.bannerBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.bannerBorder, width: 2),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(theme.icon, color: const Color(0xFFFFD54F), size: 22),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        theme.name.toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFFFFF6D6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Text(
                                        "Stages $stageNum - ${stageNum + 29}",
                                        style: const TextStyle(
                                          color: Color(0xFFE0D5C1),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Stepping-Stone Node with Hamster Token on Active Stage
                          Transform.translate(
                            offset: Offset(horizontalOffset, 0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Hamster Avatar Token positioned over the active node!
                                if (isActive) ...[
                                  SizedBox(
                                    height: 52,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Floor shadow
                                        Positioned(
                                          bottom: 2,
                                          child: Container(
                                            width: 36,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.45),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                        // Hamster base
                                        Image.asset(
                                          'assets/images/avatar_frame1.png',
                                          width: 48,
                                          height: 48,
                                        ),
                                        // Equipped accessory overlay
                                        if (equippedItem != null)
                                          Positioned(
                                            top: 4,
                                            child: Image.asset(
                                              'assets/images/${equippedItem.assetName}',
                                              width: 36,
                                              height: 36,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Circular Stage Node Button
                                GestureDetector(
                                  onTap: () {
                                    if (isLocked) {
                                      AudioService.instance.playWrong();
                                      return;
                                    }
                                    if (isCompleted) {
                                      AudioService.instance.playClick();
                                      _showCompletedWordDialog(context, stageNum);
                                      return;
                                    }
                                    AudioService.instance.playClick();
                                    widget.onLaunchStage(stageNum);
                                  },
                                  child: Container(
                                    width: isChapterMilestone ? 66 : (isMilestone ? 60 : 54),
                                    height: isChapterMilestone ? 66 : (isMilestone ? 60 : 54),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? theme.activeColor
                                          : isCompleted
                                              ? theme.completedColor
                                              : const Color(0xFF26180E),
                                      border: Border.all(
                                        color: isActive
                                            ? theme.activeBorder
                                            : isCompleted
                                                ? theme.completedBorder
                                                : const Color(0xFF5C381E),
                                        width: isActive ? 3.5 : (isMilestone ? 3.0 : 2.0),
                                      ),
                                      boxShadow: [
                                        if (isActive)
                                          BoxShadow(
                                            color: theme.activeColor.withValues(alpha: 0.6),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          )
                                        else
                                          const BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 5,
                                            offset: Offset(0, 3),
                                          ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Milestone Crown / Star icon
                                        if (isChapterMilestone)
                                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFE082), size: 18)
                                        else if (isMilestone)
                                          const Icon(Icons.star_rounded, color: Color(0xFFFFE082), size: 16),

                                        // Stage number
                                        Text(
                                          "$stageNum",
                                          style: TextStyle(
                                            color: isLocked ? const Color(0xFF755C48) : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isChapterMilestone ? 16 : 14,
                                          ),
                                        ),

                                        // Completed checkmark or Locked padlock
                                        if (isCompleted && !isMilestone)
                                          const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                                        else if (isLocked && !isMilestone)
                                          const Icon(Icons.lock_rounded, color: Color(0xFF755C48), size: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletedWordDialog(BuildContext context, int stageNum) {
    final stageData = WordService.instance.generateStage(stageNum);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C1E12), Color(0xFF191008)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD49B35), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4D28),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 16),
                            SizedBox(width: 5),
                            Text(
                              "CLEARED",
                              style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8C6541), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, color: Color(0xFFD1A87E), size: 14),
                            SizedBox(width: 4),
                            Text(
                              "REPLAY DISABLED",
                              style: TextStyle(
                                color: Color(0xFFD1A87E),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stage Title
                  Text(
                    "Stage $stageNum Solved Word",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Big Word Tile Display
                  Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: stageData.word.split('').map((letter) {
                        return Container(
                          width: 44,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF5A391E), Color(0xFF3B2311)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: Color(0xFFFFF8E1),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Definition / Description Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21140A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6B4524)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: Color(0xFFFFB300), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Word Meaning:",
                              style: TextStyle(
                                color: Color(0xFFFFB300),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stageData.description,
                          style: const TextStyle(
                            color: Color(0xFFE8D7C3),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Clues & Hints Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21140A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6B4524)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFCA28), size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Revealed Clues:",
                              style: TextStyle(
                                color: Color(0xFFFFCA28),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...stageData.hints.take(3).map((hint) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("• ", style: TextStyle(color: Color(0xFFFFCA28), fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    hint,
                                    style: const TextStyle(
                                      color: Color(0xFFD6C2AA),
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hamster Note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF382312).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Text("🐹", style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You already solved this word! Replays are disabled so you can focus on advancing.",
                            style: TextStyle(
                              color: Color(0xFFB89F82),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Close button
                  ElevatedButton(
                    onPressed: () {
                      AudioService.instance.playClick();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD49B35),
                      foregroundColor: const Color(0xFF26180E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Back to Map",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

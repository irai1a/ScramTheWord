import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';
import '../models/accessory_model.dart';
import '../dialogs/settings_dialog.dart';

/// Hamster Wardrobe screen replicating AvatarShopScreen from avatar_shop.py.
class WardrobeScreen extends StatefulWidget {
  final VoidCallback onBackToMenu;

  const WardrobeScreen({super.key, required this.onBackToMenu});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final PlayerDataService _player = PlayerDataService.instance;
  String? _previewAccessoryId;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playBgm('bgm_wardrobe');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _player,
      builder: (context, _) {
        final activeEquippedId = _player.equippedAccessory;
        final previewId = _previewAccessoryId ?? activeEquippedId;
        final previewItem = WardrobeCatalog.findById(previewId);

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

              // Vignette
              Positioned.fill(
                child: Container(
                  color: const Color(0xC7140D06),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    // Top Navigation Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      child: Row(
                        children: [
                          // Back Button
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
                                AudioService.instance.playBgm('bgm_main');
                                widget.onBackToMenu();
                              },
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Title Plaque
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xEB52331F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2B774), width: 1.5),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.checkroom_rounded, color: Color(0xFFFFD54F), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    "HAMSTER WARDROBE",
                                    style: TextStyle(
                                      color: Color(0xFFFFF6D6),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Coins Counter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xE6382617),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                            ),
                            child: Row(
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
                          const SizedBox(width: 6),

                          // Settings
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

                    // Top Avatar Showcase Preview
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xD92E1B0E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8D582A), width: 1.8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Floor Shadow
                                Positioned(
                                  bottom: 6,
                                  child: Container(
                                    width: 84,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.40),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                // Base Hamster
                                Image.asset(
                                  'assets/images/avatar_frame1.png',
                                  width: 100,
                                  height: 100,
                                ),
                                // Live Equipped Accessory Overlay
                                if (previewItem != null)
                                  Positioned(
                                    top: 10,
                                    child: Image.asset(
                                      'assets/images/${previewItem.assetName}',
                                      width: 76,
                                      height: 76,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            previewItem != null ? "Wearing: ${previewItem.name}" : "Original Woodland Hamster",
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Accessories Grid
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: WardrobeCatalog.accessories.length,
                        itemBuilder: (context, index) {
                          final item = WardrobeCatalog.accessories[index];
                          final isOwned = _player.unlockedAccessories.contains(item.id);
                          final isEquipped = activeEquippedId == item.id;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isEquipped
                                  ? const Color(0xEB422A17)
                                  : const Color(0xEB301C0D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isEquipped
                                    ? const Color(0xFFFFD54F)
                                    : const Color(0xFF6E4320),
                                width: isEquipped ? 2.5 : 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail Box
                                Container(
                                  width: 62,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1208),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF5A361B)),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Image.asset(
                                    'assets/images/${item.assetName}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          color: isEquipped ? const Color(0xFFFFD54F) : const Color(0xFFFFF6D6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          color: Color(0xFFD7CCC8),
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${item.price} Coins",
                                            style: const TextStyle(
                                              color: Color(0xFFFFE082),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Button
                                SizedBox(
                                  width: 104,
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEquipped
                                          ? const Color(0xFF388E3C)
                                          : isOwned
                                              ? const Color(0xFFF57C00)
                                              : const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () async {
                                      AudioService.instance.playClick();
                                      if (isEquipped) {
                                        // Unequip
                                        await _player.equipAccessory('empty');
                                        setState(() => _previewAccessoryId = null);
                                      } else if (isOwned) {
                                        // Equip
                                        await _player.equipAccessory(item.id);
                                        setState(() => _previewAccessoryId = item.id);
                                      } else {
                                        // Buy
                                        final success = await _player.spendCoins(item.price);
                                        if (success) {
                                          await _player.unlockAccessory(item.id);
                                          await _player.equipAccessory(item.id);
                                          setState(() => _previewAccessoryId = item.id);
                                          AudioService.instance.playSuccess();
                                        } else {
                                          AudioService.instance.playWrong();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Not enough coins! Solve more stages to earn coins."),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    child: Text(
                                      isEquipped
                                          ? "EQUIPPED"
                                          : isOwned
                                              ? "EQUIP"
                                              : "BUY (${item.price}C)",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}

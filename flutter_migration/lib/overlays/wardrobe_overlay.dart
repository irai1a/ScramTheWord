import 'package:flutter/material.dart';
import '../game/whack_game.dart';
import '../models/accessory_model.dart';
import '../services/player_data_service.dart';
import '../services/audio_service.dart';

/// Wardrobe Shop Overlay allowing players to purchase, equip, and preview accessories.
class WardrobeOverlay extends StatefulWidget {
  final WhackGame game;

  const WardrobeOverlay({super.key, required this.game});

  @override
  State<WardrobeOverlay> createState() => _WardrobeOverlayState();
}

class _WardrobeOverlayState extends State<WardrobeOverlay> {
  final PlayerDataService _player = PlayerDataService.instance;

  @override
  void initState() {
    super.initState();
    AudioService.instance.playBgm('bgm_wardrobe');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xF21C1107),
      child: SafeArea(
        child: Column(
          children: [
            // Header Bar: Close | Title | Coins
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFF6D6), size: 28),
                    onPressed: () {
                      AudioService.instance.playClick();
                      AudioService.instance.playBgm('bgm_stage');
                      widget.game.refreshWardrobe();
                      widget.game.overlays.remove('WardrobeShop');
                      widget.game.resumeEngine();
                    },
                  ),
                  const Text(
                    "WOODLAND WARDROBE",
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38220F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          "${_player.coins}",
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF5A361B), thickness: 1.5, height: 1),

            // Accessories Grid List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: WardrobeCatalog.accessories.length,
                itemBuilder: (context, index) {
                  final item = WardrobeCatalog.accessories[index];
                  final isUnlocked = _player.unlockedAccessories.contains(item.id);
                  final isEquipped = _player.equippedAccessory == item.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEquipped
                          ? const Color(0xFF4A3419)
                          : isUnlocked
                              ? const Color(0xFF33200F)
                              : const Color(0xFF24160B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEquipped
                            ? const Color(0xFFFFD700)
                            : isUnlocked
                                ? const Color(0xFF8D582A)
                                : const Color(0xFF4E3018),
                        width: isEquipped ? 2.5 : 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Accessory Icon / Preview Box
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1208),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5A361B), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/${item.assetName}',
                            width: 48,
                            height: 48,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.checkroom_rounded,
                              color: Color(0xFFFFD54F),
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: isEquipped ? const Color(0xFFFFD54F) : const Color(0xFFFFF6D6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  color: Color(0xFFBCAAA4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Action Button (Equip / Unequip / Buy)
                        _buildItemActionButton(item, isUnlocked, isEquipped),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemActionButton(Accessory item, bool isUnlocked, bool isEquipped) {
    if (isEquipped) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF795548),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          AudioService.instance.playClick();
          await _player.equipAccessory('empty');
          setState(() {});
        },
        child: const Text("UNEQUIP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    if (isUnlocked) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          AudioService.instance.playClick();
          await _player.equipAccessory(item.id);
          setState(() {});
        },
        child: const Text("EQUIP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    // Locked - Can purchase
    final canAfford = _player.coins >= item.price;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? const Color(0xFFE65100) : Colors.grey.shade800,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: canAfford
          ? () async {
              AudioService.instance.playSuccess();
              final success = await _player.spendCoins(item.price);
              if (success) {
                await _player.unlockAccessory(item.id);
                await _player.equipAccessory(item.id);
                setState(() {});
              }
            }
          : () {
              AudioService.instance.playWrong();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Not enough coins! Play more stages to earn coins.")),
              );
            },
      icon: const Icon(Icons.monetization_on_rounded, size: 16, color: Color(0xFFFFD700)),
      label: Text("${item.price}", style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/audio_service.dart';

/// Clickable carved wooden letter tile widget with authentic wood-grain textures.
/// Replicates LetterTile from the original Python Kivy stage_mode.py.
class WoodLetterTile extends StatefulWidget {
  final String letter;
  final bool isAssembled;
  final bool isDisabled;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const WoodLetterTile({
    super.key,
    required this.letter,
    this.isAssembled = false,
    this.isDisabled = false,
    this.width = 46.0,
    this.height = 52.0,
    this.onTap,
  });

  @override
  State<WoodLetterTile> createState() => _WoodLetterTileState();
}

class _WoodLetterTileState extends State<WoodLetterTile> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.isDisabled || widget.onTap == null) return;
    AudioService.instance.playTileTap();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    String bgAsset;
    if (_isPressed && !widget.isDisabled) {
      bgAsset = 'assets/images/wood_tile_pressed.png';
    } else if (widget.isAssembled) {
      bgAsset = 'assets/images/wood_tile_assembled.png';
    } else {
      bgAsset = 'assets/images/wood_tile_normal.png';
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isDisabled) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (!widget.isDisabled) {
          setState(() => _isPressed = false);
          _handleTap();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Opacity(
        opacity: widget.isDisabled ? 0.30 : 1.0,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tile texture background
              Positioned.fill(
                child: Image.asset(
                  bgAsset,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: widget.isAssembled ? const Color(0xFFE2B774) : const Color(0xFFC48E52),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF7A4A1C), width: 2),
                    ),
                  ),
                ),
              ),

              // Embossed letter text
              Transform.translate(
                offset: Offset(0, _isPressed ? 1.5 : -1.0),
                child: Text(
                  widget.letter.toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFF3B1D06),
                    fontWeight: FontWeight.w900,
                    fontSize: widget.height * 0.48,
                    fontFamily: 'serif',
                    shadows: const [
                      Shadow(
                        color: Color(0x33000000),
                        offset: Offset(1, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

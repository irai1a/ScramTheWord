import 'package:flutter/material.dart';
import '../services/audio_service.dart';

/// A tactile wood-carved push button widget with embossed typography and state feedback.
/// Replicates WoodPlankButton from the original Python Kivy main.py.
class WoodPlankButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final String normalBg;
  final String pressedBg;
  final VoidCallback? onPressed;
  final bool isDisabled;
  final String? badgeText;
  final double height;
  final Color textColor;
  final Color iconColor;

  const WoodPlankButton({
    super.key,
    required this.text,
    this.icon,
    this.normalBg = 'assets/images/wood_btn_play_wide.png',
    this.pressedBg = 'assets/images/wood_btn_play_wide_pressed.png',
    this.onPressed,
    this.isDisabled = false,
    this.badgeText,
    this.height = 58.0,
    this.textColor = const Color(0xFFFFF6E0),
    this.iconColor = const Color(0xFFFFEBBA),
  });

  @override
  State<WoodPlankButton> createState() => _WoodPlankButtonState();
}

class _WoodPlankButtonState extends State<WoodPlankButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.isDisabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
    AudioService.instance.playClick();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.isDisabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgAsset = (_isPressed && !widget.isDisabled) ? widget.pressedBg : widget.normalBg;
    final hasBadge = widget.badgeText != null && widget.badgeText!.isNotEmpty;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Opacity(
        opacity: widget.isDisabled ? 0.55 : 1.0,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // High-resolution wood texture image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    bgAsset,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: _isPressed ? const Color(0xFF6B421E) : const Color(0xFF8D582A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2B774), width: 2),
                      ),
                    ),
                  ),
                ),
              ),

              // Embossed content row with tactile dip on press
              Transform.translate(
                offset: Offset(0, _isPressed ? 2.0 : 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.iconColor, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.1,
                        shadows: const [
                          Shadow(
                            color: Color(0xAA000000),
                            offset: Offset(1, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating "COMING SOON" or status badge
              if (hasBadge)
                Positioned(
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC73829),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white70, width: 1),
                    ),
                    child: Text(
                      widget.badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
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

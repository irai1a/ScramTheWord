import 'package:flutter/material.dart';
import '../services/audio_service.dart';

/// Clickable wooden tag-style Hint button with reactive red notification badge.
/// Replicates WoodHintButton from the original Python Kivy stage_mode.py.
class WoodHintButton extends StatefulWidget {
  final String text;
  final bool hasBadge;
  final String badgeText;
  final VoidCallback? onPressed;

  const WoodHintButton({
    super.key,
    required this.text,
    required this.hasBadge,
    this.badgeText = "1",
    this.onPressed,
  });

  @override
  State<WoodHintButton> createState() => _WoodHintButtonState();
}

class _WoodHintButtonState extends State<WoodHintButton> {
  bool _isPressed = false;

  void _handleTap() {
    // The hint button can ONLY be clicked when it has the red notification mark!
    if (!widget.hasBadge || widget.onPressed == null) return;
    AudioService.instance.playClick();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.hasBadge;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Main Warm Bark Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isPressed
                  ? const Color(0xFF221408)
                  : isClickable
                      ? const Color(0xFF4A301A)
                      : const Color(0xFF332213),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isClickable ? const Color(0xFFFFD54F) : const Color(0xFF8D582A),
                width: isClickable ? 2.0 : 1.5,
              ),
              boxShadow: [
                if (isClickable)
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  size: 16,
                  color: isClickable ? const Color(0xFFFFD54F) : const Color(0xFFBCAAA4),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: isClickable ? Colors.white : const Color(0xFFD7CCC8),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Floating Red Notification Badge (Circle with "1")
          if (widget.hasBadge)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

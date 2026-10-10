import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// A tactile wooden letter tile rendered directly onto Flame's virtual canvas.
class LetterTileComponent extends PositionComponent with TapCallbacks {
  final String letter;
  final void Function(String letter) onTapCallback;

  bool isPressed = false;

  LetterTileComponent({
    required this.letter,
    required Vector2 size,
    required Vector2 position,
    required this.onTapCallback,
  }) : super(size: size, position: position, anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Wooden background card fill
    final bgPaint = Paint()
      ..color = isPressed ? const Color(0xFFC48E52) : const Color(0xFFE2B774)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Carved border stroke
    final borderPaint = Paint()
      ..color = const Color(0xFF7A4A1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect, borderPaint);

    // Letter text rendering
    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(
          color: Color(0xFF3B1D06),
          fontSize: 26,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.x - textPainter.width) / 2,
      (size.y - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    isPressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    isPressed = false;
    onTapCallback(letter);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    isPressed = false;
  }
}

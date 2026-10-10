import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../services/player_data_service.dart';
import '../../services/audio_service.dart';
import '../../models/accessory_model.dart';

/// Animated Hamster Companion Hero.
/// Switches between frame1 (inhale) and frame2 (exhale) for gentle idle breathing,
/// renders the currently equipped wardrobe accessory, and bounces when tapped!
class HamsterComponent extends PositionComponent with TapCallbacks {
  Sprite? _frame1;
  Sprite? _frame2;
  Sprite? _accessorySprite;

  bool _isExhaling = false;
  double _breathTimer = 0.0;
  static const double _breathInterval = 1.4;

  double _hopY = 0.0;
  double _hopVelocity = 0.0;
  static const double _gravity = 800.0;

  HamsterComponent({required Vector2 position, required Vector2 size})
      : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      _frame1 = await Sprite.load('avatar_frame1.png');
      _frame2 = await Sprite.load('avatar_frame2.png');
    } catch (e) {
      debugPrint("[HamsterComponent] Sprite load warning: $e");
    }

    updateAccessory();
  }

  Future<void> updateAccessory() async {
    final equippedId = PlayerDataService.instance.equippedAccessory;
    final item = WardrobeCatalog.findById(equippedId);
    if (item != null) {
      try {
        _accessorySprite = await Sprite.load(item.assetName);
      } catch (e) {
        debugPrint("[HamsterComponent] Accessory load warning: $e");
        _accessorySprite = null;
      }
    } else {
      _accessorySprite = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Idle breathing cycle
    _breathTimer += dt;
    if (_breathTimer >= _breathInterval) {
      _breathTimer = 0.0;
      _isExhaling = !_isExhaling;
    }

    // Physical hop bounce physics
    if (_hopY < 0.0 || _hopVelocity != 0.0) {
      _hopVelocity += _gravity * dt;
      _hopY += _hopVelocity * dt;
      if (_hopY >= 0.0) {
        _hopY = 0.0;
        _hopVelocity = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(0, _hopY);

    final currentSprite = _isExhaling ? (_frame2 ?? _frame1) : _frame1;
    if (currentSprite != null) {
      currentSprite.render(canvas, size: size);
    } else {
      // Fallback cute avatar placeholder
      final paint = Paint()..color = const Color(0xFFD49755);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2.2, paint);
    }

    // Overlay equipped accessory
    if (_accessorySprite != null) {
      // Accessory bounds positioned naturally over hamster head
      final accSize = Vector2(size.x * 0.75, size.y * 0.55);
      final accPos = Vector2((size.x - accSize.x) / 2, size.y * 0.05);
      _accessorySprite!.render(canvas, position: accPos, size: accSize);
    }

    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    hop();
    AudioService.instance.playClick();
  }

  void hop() {
    if (_hopY == 0.0) {
      _hopVelocity = -280.0;
    }
  }
}

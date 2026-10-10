# Whack-A-Word-Ham: Flutter + Flame Engine Migration Blueprint

This directory contains the foundational Flutter & Flame architecture migrating *Whack-A-Word-Ham* from Python/Kivy.

---

## 1. Why Move from Kivy to Flutter + Flame?

| Architectural Dimension | Python / Kivy (Old) | Flutter + Flame (New) |
| :--- | :--- | :--- |
| **Hardware Notches & Punch-Holes** | Custom manual math required; frequently clipped by status bars, dynamic islands, or camera cutouts. | Native `SafeArea` automatically queries Android `WindowInsets` & iOS Safe Area margins. |
| **Aspect Ratio Scaling** | Absolute or percentage sizing stretched tiles or pushed letters off-screen on ultra-tall (20:9) or tablet devices. | `CameraComponent.withFixedResolution(400, 750)` locks a virtual coordinate space. Letters never stretch or clip. |
| **UI Menus & Dialogs** | Canvas drawing collision bugs, double-parenting exceptions, SDL2 touch coordinate mismatches. | Flutter's declarative widget system handles HUD, coin counters, and dialogs cleanly. |
| **Performance & Game Loop** | Single-threaded Python GIL; audio segfaults in `libSDL2_mixer`. | 60/120 FPS hardware-accelerated Skia / Impeller engine with separate audio isolates. |

---

## 2. Project Directory Structure

```
flutter_migration/
├── pubspec.yaml                      # Dependencies (flame, flame_audio, shared_preferences)
├── README.md                         # Migration architecture & setup guide
├── assets/
│   ├── images/                       # Hamster frames, wardrobe accessories, wood textures
│   ├── audio/                        # BGM loops (stage, wardrobe) and sound effects
│   └── words.json                    # Vocabulary dictionary & definitions
└── lib/
    ├── main.dart                     # App entry point, orientation lock, GameWidget mount
    ├── game/
    │   ├── whack_game.dart           # Central FlameGame coordinator with FixedResolutionViewport
    │   └── components/
    │       ├── hamster_component.dart      # Animated breathing hamster with accessory layering
    │       └── letter_tile_component.dart  # Tactile canvas-rendered letter tiles with TapCallbacks
    ├── services/
    │   ├── player_data_service.dart  # Persistent SharedPreferences manager (coins, stages, wardrobe)
    │   ├── word_service.dart         # Stage generator, progressive length curves, hints
    │   └── audio_service.dart        # FlameAudio BGM & zero-latency sound effects
    ├── models/
    │   └── accessory_model.dart      # Wardrobe accessory catalog & pricing
    └── overlays/
        ├── hud_overlay.dart          # SafeArea HUD (coins, stage plaque, hint box, assembly slots)
        ├── start_menu_overlay.dart   # Pause menu with Stage Map & Wardrobe shortcuts
        ├── map_overlay.dart          # 30-level dynamic chapter progression with 5 cycling themes
        ├── wardrobe_overlay.dart     # Accessory shop with Buy, Equip, Unequip mechanics
        ├── settings_overlay.dart     # BGM & SFX sliders, progress reset modal
        └── stage_cleared_overlay.dart# Victory modal with +10 coins reward
```

---

## 3. Core Mechanics

### A. Viewport & Aspect Ratio (`lib/game/whack_game.dart`)
```dart
WhackGame()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: 400.0,
          height: 750.0,
        ),
      );
```
- **Virtual Resolution (400 x 750)**: All game elements (hamster, letter tiles, wood boards) exist in this coordinate system.
- Flame scales the canvas uniformly. On ultra-tall screens (e.g. 20:9), extra vertical space is seamlessly filled by the forest theme background color (`#1E140A`), completely eliminating stretched text or cut-off tiles.

### B. Screen-Safe HUD Overlays (`lib/overlays/hud_overlay.dart`)
- Rather than rendering buttons directly inside Flame's canvas, HUD elements are rendered as **Flutter Overlays** wrapped in `SafeArea`.
- This ensures touch targets (Back, Pause, Hint, Coins) sit cleanly below the camera notch and above Android's navigation gesture pill.

### C. Reactive State Binding (`ValueNotifier`)
- `WhackGame` exposes `ValueNotifier<int> coinsNotifier`, `stageNotifier`, and `assembledWordNotifier`.
- Overlays use `ValueListenableBuilder` to re-render badges instantly without triggering expensive widget tree rebuilds or stuttering the Flame game loop.

---

## 4. Quickstart: Running the Flutter Project

Once Flutter SDK is installed on your computer:

```bash
cd flutter_migration
flutter pub get
flutter run
```

# Whack-A-Word_Ham 🐹✨

A delightful, modern word-scramble game featuring hamster avatars, built using **Kivy** and **KivyMD 2.0**.

---

## 🚀 Features

- **Illustrated Main Menu Background**: Vibrant full-screen woodland illustration featuring the Whack-A-Word-Ham hero logo, chubby hamsters, and acorn scenery with floating glassmorphism capsules.
- **Hamster Avatar System**: Every player is represented by an adorable hamster champion with customizeable accessories (Cap, Glasses, Headphones, Ninja Mask, Crown, Wizard Hat).
- **MDScreenManager with 4 Screens**:
  1. **`MainMenuScreen`**:
     - Player status bar (Stage level badge, Coin balance, theme toggle).
     - Full woodland background artwork.
     - **Play Stage Mode** (Warm primary button).
     - **Hamster Wardrobe** (Avatar shop button).
     - **Multiplayer (Ranked)** (Disabled button with **COMING SOON** badge).
  2. **`StageModeScreen`**:
     - Word scramble gameplay powered by [words.json](file:///c:/Users/user/ScramTheWord/words.json).
     - Subtle word clues tailored for every stage to guide players and prevent ambiguity.
     - Attempt-based reward scaling:
       - **1st attempt**: 10 coins
       - **2nd attempt**: 7 coins
       - **3+ attempts**: 5 coins
     - Animated solve celebration dialog with sparkling coin counter increments.
     - Interactive assembly area and letter tiles.
  3. **`AvatarShopScreen`**:
     - Live hamster avatar preview showing base hamster and equipped accessory overlay in real time.
     - Dynamic reactive coin counter.
     - Scrollable wardrobe grid with buy/equip/unequip functionality.
  4. **`MultiplayerScreen`**:
     - Feature preview card detailing upcoming 1v1 speed unscramble duels and ranked seasons.
- **Local Data Persistence (`PlayerDataManager`)**:
  - Uses Kivy's `JsonStore` to save progress to `player_data.json`.
  - Seamless state synchronization across all screens.

---

## 📦 Requirements & Installation

Dependencies are installed in your Python environment:
```bash
pip install kivy kivymd pillow
```

---

## ▶️ Running the Game

Launch the game by executing:
```bash
python main.py
```

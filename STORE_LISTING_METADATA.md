# Google Play Store Listing Metadata - Whack-A-Word-Ham

This document contains the ready-to-copy metadata for your Google Play Console store listing.

---

## 1. App Title (Max 30 characters)
```text
Whack-A-Word-Ham
```
*(16 / 30 characters)*

---

## 2. Short Description (Max 80 characters)
Copy and paste this into the **Short description** field:

```text
Unscramble letters, solve fun puzzles, and customize your cute hamster hero!
```
*(76 / 80 characters)*

### Alternative Options:
- `Unscramble words, earn coins, and dress up your cute hamster in the forest!` *(75 / 80)*
- `Solve fun word scramble puzzles and dress up your cute woodland hamster!` *(72 / 80)*

---

## 3. Full Description (Max 4,000 characters)
Copy and paste this into the **Full description** field:

```text
Step into the enchanting woodland world of Whack-A-Word-Ham, the delightfully cozy word puzzle adventure where brain-teasing vocabulary challenges meet an adorable hamster companion!

Can you unscramble the jumbled letter tiles and discover the hidden words? Tap, arrange, and assemble letters to solve fun word puzzles, earn shiny golden coins, and journey through a handcrafted forest trail filled with rewarding stages.

Whether you have a quick 2-minute break or want to relax for an evening of brain exercise, Whack-A-Word-Ham delivers the perfect blend of mental challenge, charming forest aesthetics, and wholesome fun for puzzle lovers of all ages!

---------------------------------------------------
WHY YOU WILL LOVE WHACK-A-WORD-HAM
---------------------------------------------------

ADDICTIVE WORD SCRAMBLE GAMEPLAY
Test your vocabulary and spelling skills! Each level presents you with a jumble of rustic wooden letter tiles. Tap to arrange them into the correct word, hit Submit, and celebrate with satisfying animations and audio cues.

JOURNEY ACROSS THE FOREST MAP
Explore a sprawling woodland trail packed with progressive stage challenges. Start with simple 3-letter warm-ups and advance to brain-stretching multi-letter puzzles as you climb through the forest canopy.

STUCK? CALL ON WOODLAND HINTS!
Encounter a tricky scramble? Tap the magical hint button to reveal letter clues and keep your winning streak alive!

DRESS UP YOUR HAMSTER HERO
Visit the Woodland Wardrobe! Earn coins by completing stages and unlock an adorable collection of stylish accessories to customize your hamster:
* Royal Golden Crown
* Sneaky Ninja Mask
* Mystical Wizard Hat
* Modern Streetwear Headphones
* Classic Cool Sunglasses & Reading Glasses
* Sporty Woodland Caps

SOOTHING WOODLAND AESTHETIC & AUDIO
Immerse yourself in hand-crafted woodgrain cards, lush foliage backgrounds, and gentle acoustic soundtrack melodies accompanied by tactile wooden clacks and cheerful victory chimes.

100% OFFLINE & FAMILY-FRIENDLY
No Wi-Fi? No problem! Whack-A-Word-Ham is fully playable offline. Play anywhere—on airplanes, subways, road trips, or cozy evenings at home.

---------------------------------------------------
BRAIN BENEFITS & FUN FOR ALL AGES
---------------------------------------------------
* Expand Vocabulary: Discover new words and reinforce everyday spelling.
* Sharpen Focus: Boost cognitive pattern recognition and problem-solving skills.
* Relax & Unwind: Stress-free pacing with no punishing countdowns or unfair timers.

Download Whack-A-Word-Ham today and begin your cozy woodland word puzzle journey!
```
*(2,624 / 4,000 characters)*

---

### Version 1.0.9 (Pacing Enhancement - Ads Every 10 Stages):
```text
<en-US>
What's New in Version 1.0.9:
• Significantly reduced ad frequency: Interstitial ads now only appear every 10 stages (at milestone levels 10, 20, 30...) for a relaxed and uninterrupted puzzle flow!
• Enhanced anti-spam ad pacing safeguards.
• Target SDK Android 16 (API level 36) compliance and stability improvements.
</en-US>
```

### Version 1.0.8 (Google AdMob Interstitial Ads Integration):
```text
<en-US>
What's New in Version 1.0.8:
• Integrated Google AdMob interstitial ads between stage completions.
• Minimum SDK updated to Android 6.0 (API level 23) for seamless advertising SDK compatibility while maintaining Target API 36 (Android 16).
• Thread-safe ad preloading for smooth, stutter-free stage transitions.
• Performance enhancements and overall stability improvements.
</en-US>
```

### Version 1.0.7:
```text
<en-US>
What's New in Version 1.0.7:
• Updated Target SDK to Android 16 (API level 36) in full compliance with Google Play Store standards.
• Infinite Stage Progression: The stage map dynamically expands 30 levels ahead as you conquer each chapter!
• 5 Beautiful Cycling World Themes: Journey through Woodland Forest, Sunny Sunflower Meadow, Cozy Kitchen Pantry, Glowing Underground Burrow, and Golden Autumn Acorn Forest!
• Chapter Banners & Milestone Crowns: Celebrate your grand achievements every 30 levels with decorative chapter banners and milestone crests.
• Enhanced Map Navigation: Streamlined header plaque featuring live theme icons, themed stepping stones, and smooth auto-scrolling.
• Security, performance, and gameplay optimizations.
</en-US>
```

### Initial Release (v1.0.0):
```text
<en-US>
Welcome to the initial release of Whack-A-Word-Ham!
• Progressive stage levels with increasing vocabulary challenges.
• Unscramble rustic letter tiles to earn shiny golden coins.
• Woodland Wardrobe: Customize your hamster hero with crowns, ninja masks, wizard hats, headphones, and cool glasses!
• Dynamic hint clues to help you when you are stuck.
• Preloading screen for smooth and instantaneous level navigation.
</en-US>
```

---

## 5. Google Play Console Declarations (App Content)

### Ads Declaration:
- Go to **Policy and programmes > App content > Ads**.
- Select: **"Yes, my app contains ads"**.
- (Google AdMob is integrated for interstitial ads between stages).

### Data Safety Form (AdMob Requirements):
When filling out the Google Play Data Safety questionnaire:
1. **Does your app collect or share any of the required user data types?** -> **Yes** (via third-party SDK: Google Mobile Ads / AdMob).
2. **Data types collected by Google Mobile Ads SDK:**
   - **Device or other IDs:** Device or other IDs (Advertising ID / AAID) -> Used for Advertising or marketing, Fraud prevention & security, Analytics. Collected, transmitted over HTTPS (encrypted in transit), not tied to user identity.
   - **App info and performance:** Crash logs, Diagnostics, Other app performance data -> Used for Analytics, Fraud prevention & security.
3. **Data encryption:** All data collected by Google Play services and AdMob is encrypted in transit using HTTPS.
4. **Data deletion:** Users can reset or delete their advertising identifier directly in Android OS settings (**Settings > Google > Ads**).


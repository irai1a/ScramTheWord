# Complete Guide: Developing, Debugging & Publishing Python/Kivy Apps on Google Play
### *An End-to-End Blueprint & Diagnostic Manual for Mobile Python Developers*

This document is a complete, self-contained reference guide for developing mobile applications using **Python, Kivy, and KivyMD**, resolving mobile-specific runtime crashes, configuring cryptographic code signing, and publishing Android App Bundles (`.aab`) to the **Google Play Console**.

Keep this file and drop it into any future project workspace to avoid common pitfalls and speed up your production release!

---

# Table of Contents
1. [Part 1: The 5 Major Mobile Crash Gotchas & Solutions](#part-1-the-5-major-mobile-crash-gotchas--solutions)
2. [Part 2: The Global Crash Boundary (Fail-Safe Error Handler)](#part-2-the-global-crash-boundary-fail-safe-error-handler)
3. [Part 3: Code Signing & Release Keystores ("All uploaded bundles must be signed")](#part-3-code-signing--release-keystores)
4. [Part 4: Google Play Package Naming & App ID Rules](#part-4-google-play-package-naming--app-id-rules)
5. [Part 5: Icons & Graphics: Code vs. Play Console](#part-5-icons--graphics-code-vs-play-console)
6. [Part 6: Store Listing & Privacy Policy Requirements](#part-6-store-listing--privacy-policy-requirements)
7. [Part 7: Drop-in GitHub Actions CI/CD Workflow Template](#part-7-drop-in-github-actions-cicd-workflow-template)
8. [Part 8: Target API Level Requirements (API 36 / Android 16 Google Play Policy)](#part-8-target-api-level-requirements-api-36--android-16-google-play-policy)
9. [Part 9: Integrating Google AdMob in Python/Kivy (Native Java Bridge Architecture)](#part-9-integrating-google-admob-in-pythonkivy-native-java-bridge-architecture)

---

# Part 1: The 5 Major Mobile Crash Gotchas & Solutions

| # | Gotcha | Level | Error / Symptom | Solution |
|---|---|---|---|---|
| **1** | **Missing Transitive Dependencies** | Python / Pip | `ModuleNotFoundError: No module named 'asyncgui'` | Explicitly declare all nested dependencies in `buildozer.spec`. |
| **2** | **Native SDL2_mixer Memory Segfault** | C / Native | Instant silent exit to phone home screen with zero traceback | Eliminate `.unload()`, remove rapid `stop()` before `play()`, guard audio calls. |
| **3** | **Touch Coordinate Space Mismatch** | Kivy Touch Loop | Stuck buttons, missed touches, or crash during screen switch | Transform grabbed Window coordinates using `self.parent.to_widget(*touch.pos)`. |
| **4** | **Missing KivyMD Icon Glyphs** | KV / Resource | `KeyError: 'icon_name'` when screen renders | Validate all icon strings against `kivymd.icon_definitions.md_icons`. |
| **5** | **Widget Double-Parenting** | Kivy Tree | `WidgetException: Cannot add widget, it already has a parent` | Safely detach from previous parent (`parent.remove_widget(self)`) before `add_widget()`. |

---

### Gotcha 1: Missing Transitive Dependencies in Buildozer

#### The Problem:
On desktop, `pip install kivymd` installs everything recursively. However, **python-for-android (Buildozer) does NOT resolve transitive dependencies**. It only installs packages explicitly written in `buildozer.spec`:
- `kivymd 2.0.0` requires `asynckivy`
- `asynckivy` requires `asyncgui`
- `asyncgui` requires `exceptiongroup` (on Python < 3.11)
- `exceptiongroup` requires `typing_extensions` (on Python < 3.13)
- `materialyoucolor` and `materialshapes` require `pillow`

If `asyncgui` or `exceptiongroup` is omitted, the app compiles without warning, but crashes on Android the moment any button or widget triggers a touch/hover state!

#### The Fix in `buildozer.spec`:
Always explicitly enumerate the complete dependency tree:
```ini
requirements = python3, kivy==2.3.0, kivymd==2.0.0, pillow, materialyoucolor, materialshapes, asynckivy, asyncgui, exceptiongroup, typing_extensions
```

---

### Gotcha 2: Native C Audio Segfaults (`SIGSEGV` / Signal 11)

#### The Problem:
Kivy's `audio_sdl2` uses native C libraries (`libSDL2_mixer.so`).
1. **Calling `.unload()` on an active sound**: When `sound.unload()` is called on a looping or playing sound, SDL2 frees the C `Mix_Chunk` memory pointer while the audio thread is actively streaming audio to Android's `AudioTrack`. This causes a native Segmentation Fault (`SIGSEGV`).
2. **Calling `.stop()` immediately before `.play()`**: Causes channel collision and race conditions in the C mixer.

**Crucial Fact**: Native C segfaults **cannot** be caught by Python `try...except`. The Android OS immediately terminates the process and returns to the home screen.

#### The Fix:
- **Never call `.unload()`** on sounds that might be active. Let Python's garbage collector manage memory.
- Avoid calling `.stop()` right before `.play()`; let SDL2 mix multiple sound channels naturally.
- Wrap all sound triggers in safe helper functions:
```python
def play_sfx(sound_name):
    try:
        sound = _cached_sounds.get(sound_name)
        if sound:
            sound.volume = sfx_volume
            sound.play()
    except Exception as e:
        print(f"[AudioManager] Non-fatal audio warning: {e}")
```

---

### Gotcha 3: Touch Coordinate Mismatch in RelativeLayout

#### The Problem:
When custom buttons inherit from `ButtonBehavior, MDRelativeLayout` or `RelativeLayout`:
- On `on_touch_down`, `touch.grab(self)` grabs the touch.
- On `on_touch_up`, Kivy passes **raw Window coordinates** (e.g. `(540, 1120)` on a 1080x2400 phone screen).
- Calling `self.collide_point(*touch.pos)` checks Window coordinates against local coordinates (e.g. `0` to `200`), causing release events to fail or touch events to leak into the next screen.

#### The Fix:
Convert Window coordinates to local coordinates using `self.parent.to_widget()`:
```python
def on_touch_up(self, touch):
    try:
        if touch.grab_current is not self:
            return False
        touch.ungrab(self)
        self.state = "normal"

        is_hit = self.collide_point(*touch.pos)
        if not is_hit and self.parent and hasattr(self.parent, "to_widget"):
            local_pos = self.parent.to_widget(*touch.pos)
            is_hit = self.collide_point(*local_pos)

        if is_hit:
            self.dispatch("on_release")
        return True
    except Exception as e:
        print(f"[CustomButton] touch_up error: {e}")
        return False
```

---

### Gotcha 4: Missing KivyMD Icon Glyphs

#### The Problem:
KivyMD resolves icons via an internal dictionary (`kivymd.icon_definitions.md_icons`). If an invalid name is passed (e.g., `icon: "sparkles"` instead of `icon: "star-four-points"`), KivyMD raises an unhandled `KeyError` that crashes screen rendering.

#### The Fix:
Validate all KV icons before building:
```python
from kivymd.icon_definitions import md_icons
import re

with open("game.kv", "r", encoding="utf-8") as f:
    matches = re.findall(r'icon:\s*["\']([a-zA-Z0-9_-]+)["\']', f.read())
invalid = [i for i in matches if i not in md_icons]
if invalid:
    raise ValueError(f"Invalid KivyMD icons found: {invalid}")
```

---

### Gotcha 5: Widget Double-Parenting (`WidgetException`)

#### The Problem:
In Kivy, a widget can have only **one** parent. Re-opening modal dialogs (such as `SettingsDialog`) across different screens calls `target.add_widget(self)` without detaching from the previous screen, throwing `WidgetException: Cannot add widget, it already has a parent`.

#### The Fix:
Always detach before adding:
```python
def open(self, target_parent=None):
    if target_parent is None:
        target_parent = MDApp.get_running_app().root

    if self.parent and self.parent is not target_parent:
        self.parent.remove_widget(self)

    if not self.parent:
        target_parent.add_widget(self)
```

---

# Part 2: The Global Crash Boundary (Fail-Safe Error Handler)

Without an error boundary, any unhandled Python exception causes Android to close the app to the home screen with zero feedback.

With a **Global Crash Handler**, the exception is intercepted, written to `crash_log.txt` on the phone, and displayed on a diagnostic recovery screen so the user can send you a screenshot.

### Drop-in Code Template:
```python
import os
import traceback
from kivy.base import ExceptionHandler, ExceptionManager
from kivy.clock import Clock

class GlobalCrashHandler(ExceptionHandler):
    def handle_exception(self, inst):
        try:
            from kivymd.app import MDApp
            app = MDApp.get_running_app()
            
            tb = traceback.format_exc()
            print(f"[FATAL_CAUGHT] {inst}\n{tb}")

            # 1. Save traceback to device storage
            try:
                log_file = os.path.join(app.user_data_dir, "crash_log.txt")
                with open(log_file, "w", encoding="utf-8") as f:
                    f.write(f"Exception: {inst}\n\nTraceback:\n{tb}")
            except Exception:
                pass

            # 2. Switch to CrashScreen and stay alive
            if app and app.root and app.root.has_screen("crash_screen"):
                screen = app.root.get_screen("crash_screen")
                screen.error_summary = str(inst)
                screen.error_details = tb
                Clock.schedule_once(lambda dt: setattr(app.root, "current", "crash_screen"), 0)
                return ExceptionManager.PASS  # Prevents app from closing!
        except Exception as e:
            print(f"[CrashHandler Error] {e}")

        return ExceptionManager.RAISE

# Register once at application launch:
ExceptionManager.register(GlobalCrashHandler())
```

---

# Part 3: Code Signing & Release Keystores

### Why Google Rejects Unsigned Bundles:
Google Play requires every uploaded `.aab` to be signed with a **cryptographic upload key** (`.keystore`). Google verifies this signature to ensure that only the legitimate developer can update the app.

### Step 1: Generate a Release Keystore
Run this command using Java's `keytool`:
```bash
keytool -genkeypair -v \
  -keystore keystore/my-release.keystore \
  -alias my-key-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "MySecurePassword123" \
  -keypass "MySecurePassword123" \
  -dname "CN=MyApp, OU=MyStudio, O=MyStudio, L=City, ST=State, C=US"
```

### Step 2: Sign the `.aab` Bundle
Run `jarsigner` on the `.aab` file:
```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore keystore/my-release.keystore \
  -storepass "MySecurePassword123" \
  -keypass "MySecurePassword123" \
  bin/myapp-release.aab my-key-alias
```

### Step 3: Verify the Signature
```bash
jarsigner -verify bin/myapp-release.aab
# Output MUST say: "jar verified."
```

> [!CRITICAL]
> **Backup your keystore file!**
> When you upload your first signed `.aab`, Google Play binds that specific keystore as your **Upload Key**. Every future update (v1.0.5, v1.1.0, etc.) **must be signed with this exact keystore and alias**.

---

# Part 4: Google Play Package Naming & App ID Rules

1. **At least two segments required**: Google Play strictly requires reverse-domain notation (`domain.appname`, e.g. `org.gamestudio.whackawordham`). A single word (like `whackawordham`) will be rejected.
2. **Buildozer mapping**:
   - `package.domain = org.gamestudio`
   - `package.name = whackawordham`
   - Android Package ID = `org.gamestudio.whackawordham`
3. **Must match exactly**: The package name created in Google Play Console **must match** the package name compiled inside the `.aab`.
4. **Versioning rules**:
   - `version = 1.0.5` (string shown to players).
   - `android.numeric_version = 6` (integer that must strictly increase with each new release: `1, 2, 3, 4, 5, 6...`).
5. **Target API Level requirement**:
   - Google Play periodically updates its minimum target API requirement.
   - You must configure `android.api = 36` in `buildozer.spec`.
   - If Google Play rejects your bundle with *"Your app currently targets API level X and must target at least API level Y"*, simply update `android.api = Y` in `buildozer.spec` and bump `android.numeric_version`.

---

# Part 5: Icons & Graphics: Code vs. Play Console

| Graphic Item | Where it is set | Uploaded to Console? |
|---|---|---|
| **Phone App Library / Home Screen Icon** | In `buildozer.spec` (`icon.filename = ...`) | ❌ No. Android reads it directly from the compiled APK/AAB. |
| **Play Store Search Icon** | Google Play Console (512x512 PNG, 32-bit) | ✅ Yes. Uploaded under *Store presence* ➔ *Main store listing*. |
| **Play Store Feature Graphic (Banner)** | Google Play Console (1024x500 PNG/JPEG) | ✅ Yes. Top banner on your store page. |
| **Screenshots** | Google Play Console (min 2 phone screenshots) | ✅ Yes. |

---

# Part 6: Store Listing & Privacy Policy Requirements

### Privacy Policy Rules:
- Google requires an active, public `https://` webpage link.
- It must state what data is collected (e.g. game progress stored locally on device; no personal data or trackers collected or shared).
- **Easiest Free Method (GitHub Pages)**:
  1. Add an `index.html` file in a `docs/` folder in your repo.
  2. In your GitHub repo, go to **Settings** ➔ **Pages** ➔ select branch **`main`** and folder **`/docs`**.
  3. Your URL will be live at: `https://<username>.github.io/<repo>/`

### Store Listing Limits:
- **App Title**: Max 30 characters
- **Short Description**: Max 80 characters
- **Full Description**: Max 4,000 characters

---

# Part 7: Drop-in GitHub Actions CI/CD Workflow Template

Place this file at `.github/workflows/build_android.yml`. It handles caching, dependency installation, debug APK building, release AAB building, and automated `jarsigner` keystore signing on every push:

```yaml
name: Build & Sign Android APK & AAB

on:
  workflow_dispatch:
  push:
    branches: [ main, master ]

jobs:
  build:
    name: Build APK and Signed AAB
    runs-on: ubuntu-22.04

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Python 3.10
        uses: actions/setup-python@v5
        with:
          python-version: '3.10'

      - name: Cache Buildozer Global Directory
        uses: actions/cache@v4
        with:
          path: ~/.buildozer
          key: ${{ runner.os }}-buildozer-global-${{ hashFiles('buildozer.spec') }}
          restore-keys: |
            ${{ runner.os }}-buildozer-global-

      - name: Cache Buildozer Project Directory
        uses: actions/cache@v4
        with:
          path: .buildozer
          key: ${{ runner.os }}-buildozer-project-${{ hashFiles('buildozer.spec') }}
          restore-keys: |
            ${{ runner.os }}-buildozer-project-

      - name: Install System Dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y --no-install-recommends \
            build-essential git ccache zip unzip autoconf libtool pkg-config \
            zlib1g-dev libncurses5-dev libncursesw5-dev libtinfo5 cmake \
            libffi-dev libssl-dev libsqlite3-dev

      - name: Install Python Build Dependencies
        run: |
          python -m pip install --upgrade pip setuptools wheel
          python -m pip install "cython<3.0" buildozer virtualenv

      - name: Build Debug APK
        run: |
          buildozer -v android debug

      - name: Build Release AAB (Android App Bundle)
        run: |
          buildozer -v android release

      - name: Sign Release AAB with Keystore
        run: |
          for aab in bin/*-release.aab; do
            if [ -f "$aab" ]; then
              echo "Signing $aab..."
              jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
                -keystore keystore/whackawordham-release.keystore \
                -storepass "WhackWordHam2026!Key" \
                -keypass "WhackWordHam2026!Key" \
                "$aab" whackawordham
              jarsigner -verify "$aab"
            fi
          done

      - name: Upload Android Binaries as Artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: Android-Binaries
          path: bin/*
          retention-days: 14
```

---

# Part 8: Target API Level Requirements (API 36 / Android 16 Google Play Policy)

### 1. Google Play's Target API Policy
Starting **August 31, 2026**, Google Play requires all new apps and app updates submitted to the Google Play Store to target **Android 16 (API Level 36)** or higher.

If your `.aab` targets API level 34 or lower, Google Play Console will reject the bundle with the error:
> *"Your app currently targets API level 34 and must target at least API level 36 to ensure it is built on the latest APIs optimized for security and performance."*

---

### 2. The Buildozer / Python-for-Android Gotcha
Even when you configure `android.api = 36` in `buildozer.spec`, Python-for-Android (`p4a`) may continue packaging your `.aab` with an older target API (e.g. 34) because:
1. **Cached Distribution (`project.properties`)**: Buildozer creates `project.properties` once when the distribution (`dist`) is initialized. If Buildozer restores a previously cached `.buildozer` directory from GitHub Actions or local builds, `project.properties` retains `target=android-34` and Buildozer's code skips updating it!
2. **Missing CLI Arguments**: Buildozer historically passed `--minsdk` and `--ndk-api` to `p4a`, but omitted `--android_api`. Without `--android_api`, `p4a` fell back to parsing `project.properties` or its internal default.

---

### 3. The 3-Step Permanent Solution

#### Step 1: Update `buildozer.spec`
Add both `android.api` and `p4a.extra_args` to `buildozer.spec`:
```ini
# (int) Target Android API (API 36 required by Google Play Store)
android.api = 36

# (str) Pass explicit target API to python-for-android toolchain
p4a.extra_args = --android_api=36
```

#### Step 2: Enforce in CI/CD Workflow (`build_android.yml`)
Add an automated enforcement step right before `buildozer -v android debug` and `buildozer -v android release`:
```bash
# Update any existing project.properties in caches
find . -name "project.properties" -exec sed -i 's/target=android-[0-9]\+/target=android-36/g' {} + || true
find ~/.buildozer -name "project.properties" -exec sed -i 's/target=android-[0-9]\+/target=android-36/g' {} + || true

# Update any existing build.gradle in caches
find . -name "build.gradle" -exec sed -i 's/compileSdkVersion [0-9]\+/compileSdkVersion 36/g' {} + || true
find . -name "build.gradle" -exec sed -i 's/targetSdkVersion [0-9]\+/targetSdkVersion 36/g' {} + || true
find ~/.buildozer -name "build.gradle" -exec sed -i 's/compileSdkVersion [0-9]\+/compileSdkVersion 36/g' {} + || true
find ~/.buildozer -name "build.gradle" -exec sed -i 's/targetSdkVersion [0-9]\+/targetSdkVersion 36/g' {} + || true

# Patch build.tmpl.gradle templates across the system
find . -name "build.tmpl.gradle" -exec sed -i 's/compileSdkVersion {{ android_api }}/compileSdkVersion 36/g' {} + || true
find . -name "build.tmpl.gradle" -exec sed -i 's/targetSdkVersion {{ android_api }}/targetSdkVersion 36/g' {} + || true
find ~/.buildozer -name "build.tmpl.gradle" -exec sed -i 's/compileSdkVersion {{ android_api }}/compileSdkVersion 36/g' {} + || true
find ~/.buildozer -name "build.tmpl.gradle" -exec sed -i 's/targetSdkVersion {{ android_api }}/targetSdkVersion 36/g' {} + || true
```

#### Step 3: Automated AAB Target SDK Verification
Add a Python verification step after signing the AAB in your CI/CD pipeline to inspect `base/manifest/AndroidManifest.xml` inside the `.aab` file:
```python
import zipfile, re, sys, glob

aab_files = glob.glob("bin/*-release.aab")
if not aab_files:
    sys.exit(1)

with zipfile.ZipFile(aab_files[0]) as z:
    manifest = z.read("base/manifest/AndroidManifest.xml")
    m = re.search(rb"targetSdkVersion\x1a\x02(\d+)", manifest) or re.search(rb"targetSdkVersion[^\d]*(\d{2})", manifest)
    if not m:
        print("ERROR: targetSdkVersion not found in AAB manifest!")
        sys.exit(1)
    target_sdk = int(m.group(1).decode())
    print(f"Verified targetSdkVersion: {target_sdk}")
    if target_sdk < 36:
        print(f"ERROR: targetSdkVersion is {target_sdk}, which is below Google Play's required API 36!")
        sys.exit(1)
    print("SUCCESS: Target API level is verified to be 36 or higher!")
```
This guarantees that any built `.aab` submitted to Google Play is 100% compliant with the latest Android 16 (API 36) policy!

---

# Part 9: Integrating Google AdMob in Python/Kivy (Native Java Bridge Architecture)

Integrating mobile ads into a Python/Kivy application requires bridging Python to Android's native Java SDK. A naive attempt using Pyjnius directly from Python almost always fails due to three fatal pitfalls:

### 1. The Three Fatal AdMob Pitfalls in Python/Kivy

| # | Pitfall | Symptom / Error | Root Cause & Solution |
|---|---|---|---|
| **1** | **UI Thread Violation** | `android.view.ViewRootImpl$CalledFromWrongThreadException: Only the original thread that created a view hierarchy can touch its views.` | Google Mobile Ads SDK requires `MobileAds.initialize`, `load()`, and `show()` to execute strictly on Android's UI Main Thread. Python runs on a separate subthread. **Solution:** Dispatch all ad operations inside `activity.runOnUiThread(...)`. |
| **2** | **Pyjnius Abstract Class Limitation** | `TypeError: PythonJavaClass can only implement Java Interfaces` | AdMob callbacks (`InterstitialAdLoadCallback`, `FullScreenContentCallback`) are Java **abstract classes**, not interfaces. Pyjnius cannot subclass Java abstract classes. **Solution:** Write a native Java helper bridge (`AdMobBridge.java`) in `src/` to implement the callbacks natively. |
| **3** | **Missing Application ID in Manifest** | Immediate crash on app launch: `The Google Mobile Ads SDK was initialized incorrectly. AdMob publishers should follow the instructions here: ...` | AdMob requires `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="..." />` inside `<application>`. **Solution:** Add `android.meta_data = com.google.android.gms.ads.APPLICATION_ID=<APP_ID>` in `buildozer.spec`. |

---

### 2. Required `buildozer.spec` Settings for AdMob

```ini
# 1. Minimum SDK: Google Mobile Ads SDK requires minSdk 23 or higher
android.minapi = 23
android.ndk_api = 23

# 2. Target API: Keep target at 36 (Android 16 Google Play compliance)
android.api = 36

# 3. Permissions: INTERNET and ACCESS_NETWORK_STATE
android.permissions = INTERNET, ACCESS_NETWORK_STATE

# 4. Include custom Java bridge source folder
android.add_src = src

# 5. Gradle dependency for Google Mobile Ads SDK
android.gradle_dependencies = com.google.android.gms:play-services-ads:25.4.0

# 6. AdMob App ID in AndroidManifest meta-data (CRITICAL to prevent launch crash)
android.meta_data = com.google.android.gms.ads.APPLICATION_ID=ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX
```

---

### 3. The Native Thread-Safe Java Bridge (`src/org/gamestudio/<appname>/AdMobBridge.java`)

Place this file under `src/org/gamestudio/<appname>/AdMobBridge.java` and register `android.add_src = src` in `buildozer.spec`:

```java
package org.gamestudio.whackawordham;

import android.app.Activity;
import android.util.Log;
import androidx.annotation.NonNull;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

public class AdMobBridge {
    private static final String TAG = "AdMobBridge";
    private static InterstitialAd mInterstitialAd = null;
    private static boolean isInitialized = false;
    private static boolean isLoading = false;
    private static String mAdUnitId = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX";

    public static void init(final Activity activity, final String adUnitId) {
        if (activity == null) return;
        if (adUnitId != null && !adUnitId.trim().isEmpty()) {
            mAdUnitId = adUnitId.trim();
        }
        activity.runOnUiThread(() -> {
            try {
                MobileAds.initialize(activity, initializationStatus -> {
                    Log.i(TAG, "AdMob SDK initialization complete.");
                    isInitialized = true;
                    loadInterstitial(activity);
                });
            } catch (Exception e) {
                Log.e(TAG, "Error initializing MobileAds: " + e.getMessage(), e);
            }
        });
    }

    public static void loadInterstitial(final Activity activity) {
        if (activity == null || isLoading || mInterstitialAd != null) return;
        activity.runOnUiThread(() -> {
            try {
                isLoading = true;
                AdRequest adRequest = new AdRequest.Builder().build();
                InterstitialAd.load(activity, mAdUnitId, adRequest, new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
                        mInterstitialAd = interstitialAd;
                        isLoading = false;
                        mInterstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                            @Override
                            public void onAdDismissedFullScreenContent() {
                                mInterstitialAd = null;
                                loadInterstitial(activity); // Auto-preload next ad!
                            }
                            @Override
                            public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                                mInterstitialAd = null;
                                isLoading = false;
                                loadInterstitial(activity);
                            }
                            @Override
                            public void onAdShowedFullScreenContent() {
                                mInterstitialAd = null;
                            }
                        });
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                        mInterstitialAd = null;
                        isLoading = false;
                    }
                });
            } catch (Exception e) {
                isLoading = false;
            }
        });
    }

    public static boolean isAdLoaded() {
        return mInterstitialAd != null;
    }

    public static void showInterstitial(final Activity activity) {
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (mInterstitialAd != null) {
                mInterstitialAd.show(activity);
            } else {
                loadInterstitial(activity);
            }
        });
    }
}
```

---

### 4. Python Wrapper Module (`ad_manager.py`)

A clean Python wrapper using Pyjnius with an automatic desktop mock fallback:

```python
import sys
from kivy.utils import platform

ADMOB_APP_ID = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
INTERSTITIAL_AD_UNIT_ID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"

_is_initialized = False

def init_ads():
    global _is_initialized
    if _is_initialized:
        return
    if platform == "android":
        try:
            from jnius import autoclass
            PythonActivity = autoclass("org.kivy.android.PythonActivity")
            activity = PythonActivity.mActivity
            if activity:
                AdMobBridge = autoclass("org.gamestudio.whackawordham.AdMobBridge")
                AdMobBridge.init(activity, INTERSTITIAL_AD_UNIT_ID)
                _is_initialized = True
        except Exception as e:
            print(f"[AdManager] Init error: {e}")
    else:
        _is_initialized = True
        print(f"[AdManager Mock] AdMob initialized with App ID: {ADMOB_APP_ID}")

def is_interstitial_ready() -> bool:
    if platform == "android":
        try:
            from jnius import autoclass
            AdMobBridge = autoclass("org.gamestudio.whackawordham.AdMobBridge")
            return bool(AdMobBridge.isAdLoaded())
        except Exception:
            return False
    return True

def show_interstitial_ad(stage_number: int = 0) -> bool:
    if platform == "android":
        try:
            from jnius import autoclass
            PythonActivity = autoclass("org.kivy.android.PythonActivity")
            activity = PythonActivity.mActivity
            if activity:
                AdMobBridge = autoclass("org.gamestudio.whackawordham.AdMobBridge")
                AdMobBridge.showInterstitial(activity)
                return True
        except Exception as e:
            print(f"[AdManager] Error showing ad: {e}")
            return False
    else:
        print(f"[AdManager Desktop Mock] Interstitial ad shown after level {stage_number}!")
        return True
```

Call `init_ads()` in `on_start()` and `show_interstitial_ad(stage_number=completed_stage)` upon stage completion.


---

### 5. Google Play Console Compliance for Ads
1. **Ads Declaration**: Under **Policy > App content > Ads**, select **"Yes, my app contains ads"**.
2. **Data Safety Form**: Declare collection of **Device or other IDs** (Advertising ID) for advertising and fraud prevention, encrypted in transit over HTTPS.
3. **AdMob Propagation**: Note that newly created AdMob ad units can take up to 1 hour to start serving live ads.


[app]

# (str) Title of your application
title = Whack-A-Word-Ham

# (str) Package name (lowercase alphanumeric without spaces or special characters)
package.name = whackawordham

# (str) Package domain (needed for unique Android package identifier: e.g. org.gamestudio.whackawordham)
package.domain = org.gamestudio

# (str) Source code where the main.py lives
source.dir = .

# (list) Source files to include (let empty to include all the files)
# Bundle Python scripts, Kivy KV styles, sprite images, dictionary JSONs, and audio assets
source.include_exts = py, kv, png, jpg, json, wav, ogg

# (list) List of directory names in the source directory to exclude
# Keeps local test scripts, cache directories, and virtual environments out of the final APK/AAB
source.exclude_dirs = tests, bin, venv, .venv, scratch, .git, .idea, .vscode, .gemini, build

# (list) List of file patterns to exclude from compilation
source.exclude_patterns = Makefile, *.pyc, *.pyo, *.spec.bak, test_*

# (str) Application versioning
# Increment version and numeric code for every new release uploaded to Google Play
version = 1.0.3
# (int) Android application version code (must be strictly incremented for Play Store updates)
android.numeric_version = 4

# (list) Application requirements
requirements = python3, kivy==2.3.0, kivymd==2.0.0, materialyoucolor, materialshapes, asynckivy

# (str) Supported orientation (one of landscape, sensorLandscape, portrait or all)
# Portrait is required because the progression map and word-whacking tiles are designed vertically
orientation = portrait

# -----------------------------------------------------------------------------
# Icons and Presplash (Splash Screen) Configuration
# -----------------------------------------------------------------------------

# (str) Icon of the application (recommended: 512x512 or 1024x1024 PNG)
# Points to the hamster avatar as the default game icon; change to your custom icon prior to release
icon.filename = %(source.dir)s/assets/avatar_base.png

# (str) Presplash of the application (shown during Kivy runtime initialization)
# Recommended: 1080x1920 PNG matching the game's forest theme
presplash.filename = %(source.dir)s/assets/main_menu_bg.png

# (str) Presplash background color (for adaptive splash screens)
# Deep forest cedar brown tone matching the game aesthetic
presplash.color = #261708

# -----------------------------------------------------------------------------
# Android Engine Configuration & Google Play Store Compliance
# -----------------------------------------------------------------------------

# (bool) Fullscreen mode (1 = immersive fullscreen hiding Android navigation/status bars, 0 = windowed)
fullscreen = 1

# (list) Permissions required by the application
# INTERNET is included for local network testing and future multiplayer/update connectivity
android.permissions = INTERNET

# (list) Features required by the application
# android.features = android.hardware.touchscreen

# (int) Target Android API (API 34 = Android 14, meets current Google Play Store compliance)
# To target Android 15 in late 2025/2026, set to 35
android.api = 34

# (int) Minimum API supported (API 21 = Android 5.0 Lollipop, compatible with ~99% of Android devices)
android.minapi = 21

# (str) Android NDK version to use (25b is stable with Python-for-Android and Kivy 2.3)
android.ndk = 25b

# (int) Android NDK API level (matches minapi for cross-compilation stability)
android.ndk_api = 21

# (list) Target Architectures for Android binaries
# arm64-v8a (64-bit mandatory for Google Play) and armeabi-v7a (32-bit legacy support)
android.archs = arm64-v8a, armeabi-v7a

# (bool) Automatically accept Android SDK license agreements during build
android.accept_sdk_license = True

# (bool) Allow backup of user data (set to True to allow game save data backup via Google Drive)
android.allow_backup = True

# (str) Android entry point activity
android.entrypoint = org.kivy.android.PythonActivity

# (str) Android app theme (Theme.NoTitleBar.Fullscreen ensures no default Android action bar interferes)
android.manifest.intent_filters = 
android.manifest.launch_mode = singleTask

# -----------------------------------------------------------------------------
# Python-for-Android (P4A) Build Options
# -----------------------------------------------------------------------------

# (str) python-for-android branch to use (pinned to v2024.01.21 for stable Python 3.11.5 + Kivy 2.3.0 compatibility)
p4a.branch = v2024.01.21

# (str) python-for-android packaging format (apk for local testing, aab for Google Play Store upload)
# Change to 'aab' when building the release bundle: buildozer android release
android.release_artifact = aab
android.debug_artifact = apk

# -----------------------------------------------------------------------------
# Google Play Release Keystore Signing Configuration (Optional for Release)
# -----------------------------------------------------------------------------
# To sign your release APK or AAB for the Google Play Store, uncomment and set the following:
# android.keystore = /path/to/your/release-key.keystore
# android.keyalias = mykeyalias
# android.keystore_passwd = mykeystorepassword
# android.keyalias_passwd = mykeyaliaspassword

[buildozer]

# (int) Log level (0 = error only, 1 = info, 2 = debug with full compile diagnostics)
log_level = 2

# (int) Display warning if buildozer is run as root (0 = False, 1 = True)
warn_on_root = 1

# (str) Directory where buildozer stores cached SDKs, NDKs, and build outputs
build_dir = ./.buildozer

# (str) Directory where compiled APK and AAB output packages are placed
bin_dir = ./bin

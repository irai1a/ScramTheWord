# Whack-A-Word-Ham: Android Build Guide (APK & AAB)

Buildozer is the official packaging tool for Kivy and KivyMD. Because Buildozer compiles C/C++ libraries and invokes the Android NDK/SDK toolchains, **it requires a Linux environment (Linux kernel, POSIX toolchains, GNU build tools)**. Buildozer raises `NotImplementedError: Windows platform not yet working for Android` when run directly in native Windows PowerShell/CMD.

To build your **APK** (for local Android testing) and **AAB** (for Google Play Store), choose one of the three options below.

---

## Option 1: GitHub Actions (Recommended — 100% Cloud Automated)

A pre-configured GitHub Actions workflow has been added at [`.github/workflows/build_android.yml`](.github/workflows/build_android.yml).

1. Push your project to GitHub.
2. In your repository on GitHub, click on the **Actions** tab.
3. Select **"Build Android APK & AAB"** on the left menu.
4. Click **"Run workflow"** -> **"Run workflow"**.
5. Once the build completes (~10-15 minutes on the first build, ~2-3 minutes with cache on subsequent builds):
   - Scroll down to the **Artifacts** section at the bottom of the run page.
   - Click to download **`Whack-A-Word-Ham-Binaries.zip`**.
6. Extract the downloaded zip into your local [`bin/`](bin/) folder:
   - `whackawordham-1.0.0-arm64-v8a_armeabi-v7a-debug.apk` (Install directly on your phone)
   - `whackawordham-1.0.0-release.aab` (Upload to Google Play Console)

---

## Option 2: Build Locally using Windows Subsystem for Linux (WSL)

If you prefer building locally on your Windows PC:

### Step 1: Install Ubuntu on WSL
Open PowerShell as **Administrator** and run:
```powershell
wsl --install -d Ubuntu
```
*(Restart your computer if prompted)*

### Step 2: Open Ubuntu and Navigate to Your Project
Launch the Ubuntu terminal from your Start menu, then navigate to this folder:
```bash
cd /mnt/c/Users/user/ScramTheWord
```

### Step 3: Install Required Linux Dependencies
```bash
sudo apt update
sudo apt install -y git zip unzip openjdk-17-jdk python3-pip autoconf libtool pkg-config zlib1g-dev libncurses5-dev libncursesw5-dev libtinfo5 cmake libffi-dev libssl-dev libsqlite3-dev
pip3 install --user --upgrade buildozer cython virtualenv
```

### Step 4: Run the Build Commands
To build the debug APK:
```bash
~/.local/bin/buildozer android debug
```
To build the release AAB:
```bash
~/.local/bin/buildozer android release
```
The output files will be placed automatically into the [`bin/`](bin/) directory.

---

## Option 3: Free Cloud Build using Google Colab

If you do not want to install WSL on your computer, you can build on Google Colab's free Linux environment:

1. Open [Google Colab](https://colab.research.google.com/).
2. Create a new notebook.
3. Run the following cell to install dependencies:
   ```python
   !sudo apt update
   !sudo apt install -y openjdk-17-jdk git zip unzip autoconf libtool pkg-config zlib1g-dev libncurses5-dev libncursesw5-dev libtinfo5 cmake libffi-dev libssl-dev
   !pip install --upgrade buildozer cython virtualenv
   ```
4. Zip your `ScramTheWord` project folder and upload it to Colab, then unzip it:
   ```python
   !unzip ScramTheWord.zip -d /content/ScramTheWord
   %cd /content/ScramTheWord
   ```
5. Run the build commands:
   ```python
   !buildozer android debug
   !buildozer android release
   ```
6. Download the generated `.apk` and `.aab` from `/content/ScramTheWord/bin/` into your local [`bin/`](bin/) directory.

# Android Release Keystore Information

This directory contains the official cryptographic release keystore used to sign the **Whack-A-Word-Ham** Android App Bundle (`.aab`) for Google Play Store releases.

---

### Keystore Credentials
- **Keystore File**: `keystore/whackawordham-release.keystore`
- **Key Alias**: `whackawordham`
- **Keystore Password**: `WhackWordHam2026!Key`
- **Key Password**: `WhackWordHam2026!Key`
- **Algorithm**: RSA 2048-bit (SHA256withRSA)
- **Validity**: 10,000 days (Expires in year 2054)

---

### IMPORTANT NOTICE FOR GOOGLE PLAY:
> [!IMPORTANT]
> When you upload your first `.aab` to Google Play Console, Google Play permanently registers this key as your **Upload Key**.
>
> All future updates (v1.0.5, v1.1.0, etc.) **must be signed with this exact keystore and alias**.
> If you lose this keystore file, you would have to contact Google Play Developer Support to reset your upload key. Keep this file safe and backed up.

---

### Automated Signing
The GitHub Actions workflow (`.github/workflows/build_android.yml`) is already configured to automatically sign every release `.aab` using this keystore on every push to `main`.

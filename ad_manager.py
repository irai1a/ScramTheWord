"""Google AdMob Interstitial Ads Manager for Whack-A-Word-Ham.

Coordinates with the native AdMobBridge Java class on Android devices
and provides transparent, crash-safe mock behavior when developing on desktop.
"""

import sys
from kivy.utils import platform

# Official AdMob Production IDs registered for Whack-A-Word-Ham
ADMOB_APP_ID = "ca-app-pub-8319421439790948~2491725486"
INTERSTITIAL_AD_UNIT_ID = "ca-app-pub-8319421439790948/4810284561"

# How often to display interstitial ads:
# Set to 10 so ads only appear every 10 stages for a comfortable, non-intrusive player experience
AD_STAGE_INTERVAL = 10

# Internal state tracking
_is_initialized = False
_stages_completed_since_ad = 0
_total_ads_shown = 0


def init_ads():
    """Initialize Google Mobile Ads SDK on app launch."""
    global _is_initialized
    if _is_initialized:
        return

    print("[AdManager] Initializing Google Mobile Ads SDK...", flush=True)

    if platform == "android":
        try:
            from jnius import autoclass
            PythonActivity = autoclass("org.kivy.android.PythonActivity")
            activity = PythonActivity.mActivity

            if activity:
                AdMobBridge = autoclass("org.gamestudio.whackawordham.AdMobBridge")
                AdMobBridge.init(activity, INTERSTITIAL_AD_UNIT_ID)
                _is_initialized = True
                print("[AdManager] Native Android AdMobBridge initialized successfully.", flush=True)
            else:
                print("[AdManager] Warning: PythonActivity.mActivity is null during init.", flush=True)
        except Exception as e:
            print(f"[AdManager] Error initializing native AdMob: {e}", flush=True)
    else:
        # Desktop development mock
        _is_initialized = True
        print(f"[AdManager Desktop Mock] AdMob initialized with App ID: {ADMOB_APP_ID}", flush=True)


def is_interstitial_ready() -> bool:
    """Check if an interstitial ad is pre-loaded and ready to display."""
    if platform == "android":
        try:
            from jnius import autoclass
            AdMobBridge = autoclass("org.gamestudio.whackawordham.AdMobBridge")
            return bool(AdMobBridge.isAdLoaded())
        except Exception as e:
            print(f"[AdManager] Error checking isAdLoaded: {e}", flush=True)
            return False
    else:
        return True


def show_interstitial_ad(stage_number: int = 0, force: bool = False) -> bool:
    """Display an interstitial ad every 10 stages or at milestone levels (10, 20, 30...).

    Args:
        stage_number: The stage number that was just completed.
        force: If True, bypasses the interval check and shows immediately.

    Returns:
        bool: True if an ad display attempt was triggered.
    """
    global _stages_completed_since_ad, _total_ads_shown

    _stages_completed_since_ad += 1

    # Show ad if:
    # 1. Force is True
    # 2. Player has cleared 10 stages since the last ad
    # 3. Stage number is a milestone multiple of 10 (e.g. 10, 20, 30...) AND at least 3 stages have passed since last ad
    should_show = (
        force
        or (_stages_completed_since_ad >= AD_STAGE_INTERVAL)
        or (stage_number > 0 and (stage_number % AD_STAGE_INTERVAL == 0) and _stages_completed_since_ad >= 3)
    )

    if not should_show:
        print(
            f"[AdManager] Stage {stage_number} cleared. "
            f"Ad progress: {_stages_completed_since_ad}/{AD_STAGE_INTERVAL} (Next ad at Stage 10/20/30 or after 10 completed levels).",
            flush=True,
        )
        return False

    print(f"[AdManager] Showing interstitial ad after Stage {stage_number} completion!", flush=True)
    _stages_completed_since_ad = 0
    _total_ads_shown += 1

    if platform == "android":
        try:
            from jnius import autoclass
            PythonActivity = autoclass("org.kivy.android.PythonActivity")
            activity = PythonActivity.mActivity

            if activity:
                AdMobBridge = autoclass("org.gamestudio.whackawordham.AdMobBridge")
                AdMobBridge.showInterstitial(activity)
                return True
            else:
                print("[AdManager] Warning: PythonActivity.mActivity is null when attempting to show ad.", flush=True)
                return False
        except Exception as e:
            print(f"[AdManager] Error showing native interstitial: {e}", flush=True)
            return False
    else:
        # Desktop mock presentation
        print(
            f"[AdManager Desktop Mock] *** INTERSTITIAL AD DISPLAYED (Ad Unit: {INTERSTITIAL_AD_UNIT_ID}) ***",
            flush=True,
        )
        return True

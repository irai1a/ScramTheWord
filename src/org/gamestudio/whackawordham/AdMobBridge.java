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

/**
 * Thread-safe Java bridge for Google AdMob Interstitial Ads in Whack-A-Word-Ham.
 * Dispatches all AdMob SDK interactions to Android's UI thread and auto-preloads
 * consecutive interstitial ads so gameplay transitions are seamless and crash-free.
 */
public class AdMobBridge {
    private static final String TAG = "AdMobBridge";
    private static InterstitialAd mInterstitialAd = null;
    private static boolean isInitialized = false;
    private static boolean isLoading = false;
    private static String mAdUnitId = "ca-app-pub-8319421439790948/4810284561";

    /**
     * Initialize the Google Mobile Ads SDK on the UI thread and preload the first interstitial.
     */
    public static void init(final Activity activity, final String adUnitId) {
        if (activity == null) {
            Log.w(TAG, "Activity is null. Skipping AdMob initialization.");
            return;
        }
        if (adUnitId != null && !adUnitId.trim().isEmpty()) {
            mAdUnitId = adUnitId.trim();
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.d(TAG, "Initializing Google Mobile Ads SDK with Ad Unit: " + mAdUnitId);
                    MobileAds.initialize(activity, new OnInitializationCompleteListener() {
                        @Override
                        public void onInitializationComplete(@NonNull InitializationStatus initializationStatus) {
                            Log.i(TAG, "AdMob SDK initialization complete.");
                            isInitialized = true;
                            loadInterstitial(activity);
                        }
                    });
                } catch (Exception e) {
                    Log.e(TAG, "Error initializing MobileAds: " + e.getMessage(), e);
                }
            }
        });
    }

    /**
     * Preload an Interstitial Ad in the background so it is ready when a stage completes.
     */
    public static void loadInterstitial(final Activity activity) {
        if (activity == null) return;
        if (isLoading || mInterstitialAd != null) {
            Log.d(TAG, "Ad already loaded or currently loading. Skipping duplicate request.");
            return;
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    isLoading = true;
                    Log.d(TAG, "Requesting new Interstitial Ad from AdMob...");
                    AdRequest adRequest = new AdRequest.Builder().build();
                    InterstitialAd.load(activity, mAdUnitId, adRequest, new InterstitialAdLoadCallback() {
                        @Override
                        public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
                            mInterstitialAd = interstitialAd;
                            isLoading = false;
                            Log.i(TAG, "Interstitial Ad successfully loaded and ready to display!");

                            mInterstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                                @Override
                                public void onAdDismissedFullScreenContent() {
                                    Log.i(TAG, "Interstitial Ad dismissed by player. Auto-preloading next ad...");
                                    mInterstitialAd = null;
                                    loadInterstitial(activity);
                                }

                                @Override
                                public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                                    Log.e(TAG, "Failed to show interstitial ad: " + adError.getMessage());
                                    mInterstitialAd = null;
                                    isLoading = false;
                                    loadInterstitial(activity);
                                }

                                @Override
                                public void onAdShowedFullScreenContent() {
                                    Log.i(TAG, "Interstitial Ad displayed on screen.");
                                    mInterstitialAd = null;
                                }
                            });
                        }

                        @Override
                        public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                            mInterstitialAd = null;
                            isLoading = false;
                            Log.w(TAG, "Failed to load Interstitial Ad: " + loadAdError.getMessage()
                                    + " (Code: " + loadAdError.getCode() + ")");
                        }
                    });
                } catch (Exception e) {
                    isLoading = false;
                    Log.e(TAG, "Unexpected error in loadInterstitial: " + e.getMessage(), e);
                }
            }
        });
    }

    /**
     * Check whether an interstitial ad is currently cached and ready to show.
     */
    public static boolean isAdLoaded() {
        return mInterstitialAd != null;
    }

    /**
     * Show the interstitial ad if ready. If not ready, triggers a background load.
     */
    public static void showInterstitial(final Activity activity) {
        if (activity == null) {
            Log.w(TAG, "Cannot show interstitial: activity is null.");
            return;
        }

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (mInterstitialAd != null) {
                        Log.i(TAG, "Showing Interstitial Ad to player.");
                        mInterstitialAd.show(activity);
                    } else {
                        Log.d(TAG, "Interstitial Ad not loaded yet. Requesting load for next opportunity.");
                        loadInterstitial(activity);
                    }
                } catch (Exception e) {
                    Log.e(TAG, "Error displaying interstitial: " + e.getMessage(), e);
                }
            }
        });
    }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdService handles interstitial advertisements every 10 stages matching ad_manager.py.
/// AdMob App ID: ca-app-pub-8319421439790948~2491725486
/// Interstitial Unit ID: ca-app-pub-8319421439790948/4810284561
class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  static const String admobAppId = "ca-app-pub-8319421439790948~2491725486";
  static const String interstitialAdUnitId = "ca-app-pub-8319421439790948/4810284561";
  static const int adStageInterval = 10;

  int _stagesSinceLastAd = 0;
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;

  void init() {
    debugPrint("[AdService] Initializing Google Mobile Ads with App ID: $admobAppId");
    if (!kIsWeb) {
      try {
        MobileAds.instance.initialize().then((_) {
          debugPrint("[AdService] Google Mobile Ads initialized successfully.");
          _preloadInterstitialAd();
        });
      } catch (e) {
        debugPrint("[AdService] Error initializing Google Mobile Ads: $e");
      }
    } else {
      debugPrint("[AdService] Web platform detected: using in-app sponsored ad simulation.");
    }
  }

  void _preloadInterstitialAd() {
    if (kIsWeb || _isAdLoading || _interstitialAd != null) return;
    _isAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("[AdService] Interstitial ad loaded successfully.");
          _interstitialAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint("[AdService] Interstitial ad failed to load: $error");
          _interstitialAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  /// Checks if an interstitial ad should be shown based on completed stage number.
  bool shouldShowInterstitial(int completedStage) {
    _stagesSinceLastAd++;
    final isMilestone = completedStage > 0 && (completedStage % adStageInterval == 0);
    final intervalReached = _stagesSinceLastAd >= adStageInterval;

    debugPrint(
      "[AdService] Stage $completedStage completed. Progress towards ad: "
      "$_stagesSinceLastAd / $adStageInterval stages (Milestone: $isMilestone).",
    );

    if (isMilestone || intervalReached) {
      _stagesSinceLastAd = 0;
      return true;
    }
    return false;
  }

  /// Displays either the native AdMob interstitial ad (on mobile) or the simulated preview dialog (on web/desktop).
  Future<void> showInterstitialDialog(BuildContext context, int completedStage) async {
    debugPrint("[AdService] Triggering interstitial ad presentation for stage $completedStage");

    if (!kIsWeb && _interstitialAd != null) {
      // Native Mobile AdMob display
      final ad = _interstitialAd!;
      _interstitialAd = null;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint("[AdService] Interstitial ad dismissed by user.");
          ad.dispose();
          _preloadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint("[AdService] Interstitial ad failed to show: $error");
          ad.dispose();
          _preloadInterstitialAd();
        },
      );

      await ad.show();
      return;
    }

    // Web / Desktop / Fallback in-app sponsored preview dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InterstitialAdDialog(stage: completedStage),
    );

    // Attempt to preload for next time if on native
    if (!kIsWeb) {
      _preloadInterstitialAd();
    }
  }
}

class _InterstitialAdDialog extends StatefulWidget {
  final int stage;
  const _InterstitialAdDialog({required this.stage});

  @override
  State<_InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<_InterstitialAdDialog> {
  int _countdown = 3;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
        _startTimer();
      } else {
        setState(() {
          _countdown = 0;
          _canClose = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E140A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFC48E52), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B1D06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "SPONSORED ADVERTISEMENT",
                    style: TextStyle(fontSize: 10, color: Color(0xFFFFD54F), fontWeight: FontWeight.bold),
                  ),
                ),
                if (_canClose)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A1504),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$_countdown",
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF2D1B0D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5A361B)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/avatar_frame1.png',
                      width: 72,
                      height: 72,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Whack-A-Word-Ham",
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Stage ${widget.stage} Cleared! Thank you for playing!",
                      style: const TextStyle(color: Color(0xFFD7CCC8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_canClose)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "CONTINUE ADVENTURE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              )
            else
              const Text(
                "Ad will close automatically in a moment...",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}

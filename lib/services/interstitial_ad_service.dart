import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  // Google's official test ad unit IDs
  static const String _androidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  bool get isReady => !kIsWeb && _interstitialAd != null;

  void loadAd() {
    // AdMob is not supported on Web; early exit to prevent crashes
    if (kIsWeb || _interstitialAd != null || _isLoading) {
      return;
    }

    _isLoading = true;

    final String adUnitId = defaultTargetPlatform == TargetPlatform.android
        ? _androidInterstitialUnitId
        : _iosInterstitialUnitId;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _interstitialAd = null;
              loadAd();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
                  ad.dispose();
                  _interstitialAd = null;
                  loadAd();
                },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  void showAd() {
    if (kIsWeb || _interstitialAd == null) {
      return;
    }

    _interstitialAd!.show();
  }

  void dispose() {
    if (!kIsWeb) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }
}

import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  // Google's official test ad unit IDs
  static const String _androidInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  bool get isReady => _interstitialAd != null;

  void loadAd() {
    if (_interstitialAd != null || _isLoading) {
      return;
    }

    _isLoading = true;

    final String adUnitId = Platform.isAndroid
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
            onAdFailedToShowFullScreenContent: (
              InterstitialAd ad,
              AdError error,
            ) {
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
    if (_interstitialAd == null) {
      return;
    }

    _interstitialAd!.show();
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

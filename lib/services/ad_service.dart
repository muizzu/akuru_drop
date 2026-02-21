import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';
import '../config/constants.dart';
import 'storage_service.dart';

class AdService {
  final StorageService _storage;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  bool _isInitialized = false;

  AdService(this._storage);

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadInterstitialAd();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  // Banner Ad
  BannerAd? createBannerAd() {
    if (!_isInitialized) return null;
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed: $error');
          ad.dispose();
        },
      ),
    )..load();
    return _bannerAd;
  }

  // Interstitial Ad
  void _loadInterstitialAd() {
    if (!_isInitialized) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial load failed: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  bool get shouldShowInterstitial {
    final levelsSince = _storage.levelsCompletedSinceAd;
    if (levelsSince < kAdFrequencyLevels) return false;

    final lastAd = _storage.lastAdTime;
    if (lastAd != null) {
      final elapsed = DateTime.now().difference(lastAd);
      if (elapsed < kAdMinInterval) return false;
    }
    return true;
  }

  Future<void> showInterstitial() async {
    if (_interstitialAd == null || !shouldShowInterstitial) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
    await _storage.recordAdShown();
    _interstitialAd = null;
  }

  void recordLevelComplete() {
    _storage.setLevelsCompletedSinceAd(_storage.levelsCompletedSinceAd + 1);
  }

  // Rewarded Ad
  void _loadRewardedAd() {
    if (!_isInitialized) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad load failed: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  Future<bool> showRewardedAd({required Function(int amount) onReward}) async {
    if (_rewardedAd == null) return false;

    bool rewarded = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
        onReward(reward.amount.toInt());
      },
    );
    _rewardedAd = null;
    return rewarded;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
  }
}

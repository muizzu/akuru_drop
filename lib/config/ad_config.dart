import 'dart:io' show Platform;

class AdConfig {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    }
    return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    }
    return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test ID
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    }
    return 'ca-app-pub-3940256099942544/1712485313'; // iOS Test ID
  }

  static const String appId = 'ca-app-pub-3940256099942544~3347511713'; // Test ID
}

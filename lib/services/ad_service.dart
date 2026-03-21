import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class AdService {
  static BannerAd? _bannerAd;
  static bool _isBannerLoaded = false;

  static String get _bannerAdUnitId =>
      dotenv.env['ADMOB_BANNER_ID'] ?? '';

  // Initialize AdMob
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['AB209C2574323D6748644C7EADD53ADA'],
      ),
    );
  }

  // Load banner ad
  static Future<BannerAd?> loadBannerAd() async {
    final completer = Completer<BannerAd?>();

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerLoaded = true;
          completer.complete(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerLoaded = false;
          ad.dispose();
          completer.complete(null);
        },
      ),
    );

    await _bannerAd!.load();
    return completer.future;
  }

  // Dispose banner ad
  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }
}
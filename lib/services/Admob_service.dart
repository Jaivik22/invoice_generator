import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/invoice_generator_app.dart';

class AdUnits {
  static const String interstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String rewardedTest = 'ca-app-pub-3940256099942544/5224354917';
  static const String nativeTest = 'ca-app-pub-3940256099942544/2247696110';
  static const String bannerTest = 'ca-app-pub-3940256099942544/6300978111'; // Banner test ID
  static String interstitial = interstitialTest;
  static String rewarded = rewardedTest;
  static String native = nativeTest;
  static String banner = bannerTest;

  static Future<void> loadFromRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: Duration(seconds: 10),
          minimumFetchInterval: Duration(hours: 1),
        ),
      );
      await remoteConfig.fetchAndActivate();
      final jsonString = remoteConfig.getString('ad_units');
      if (jsonString.isEmpty) return;
      final Map<String, dynamic> adUnitsMap = jsonDecode(jsonString);
      interstitial = _safeId(adUnitsMap['interstitial'], interstitialTest);
      rewarded = _safeId(adUnitsMap['rewarded'], rewardedTest);
      native = _safeId(adUnitsMap['native'], nativeTest);
      banner = _safeId(adUnitsMap['banner'], bannerTest);
    } catch (e) {
      print('Failed to load Remote Config: $e');
    }
  }

  static String _safeId(String? id, String fallback) {
    if (id == null || id.isEmpty) return fallback;
    if (id.startsWith('ca-app-pub-') && id.length > 20) return id;
    return fallback;
  }
}

class AdController extends GetxController {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;
  final RxBool isAdLoading = false.obs;
  final RxBool isAdLoaded = false.obs;
  final RxBool isRewardedLoading = false.obs;
  final RxBool isRewardedLoaded = false.obs;
  final RxBool isNativeLoading = false.obs;
  final RxBool isNativeLoaded = false.obs;
  @override
  void onInit() {
    super.onInit();
    initialize();
  }
  void checkAndLoadAdsIfNeeded() {
    Connectivity().checkConnectivity().then((status) {
      if (status != ConnectivityResult.none &&
          !isAdLoaded.value &&
          !isAdLoading.value) {
        initializeAds();
      }
    });
  }



  StreamSubscription? _connectivitySubscription;

  Future<void> initialize() async {
    preloadInterstitialAd();

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch) {
      await prefs.setBool('is_first_launch', false);
      print("First launch detected — skipping ad preload.");
      return;
    }

    // check internet status first
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      print("No internet connection — waiting for internet to load ads.");
      listenForInternetAndLoadAds();
    } else {
      await initializeAds();
    }
  }

  Future<void> initializeAds() async {
    await AdUnits.loadFromRemoteConfig();
    await MobileAds.instance.initialize();
    preloadInterstitialAd();
    preloadRewardedAd();
    preloadNativeAd();
    preloadBannerAd();
  }

  void listenForInternetAndLoadAds() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        print("Internet available — loading ads.");
        _connectivitySubscription?.cancel(); // stop listening once internet is back
        initializeAds();
      }
    });
  }

  void preloadInterstitialAd() {
    final adUnitId = AdUnits.interstitial;
    if (isAdLoading.value || isAdLoaded.value) return;
    isAdLoading.value = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          isAdLoaded.value = true;
          isAdLoading.value = false;
          _interstitialAd
              ?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              isAdLoaded.value = false;
              preloadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              isAdLoaded.value = false;
              preloadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          isAdLoading.value = false;
        },
      ),
    );
  }

  void showOrLoadInterstitialAd(BuildContext context) {
    final adUnitId = AdUnits.interstitial;

    void goToNextPage() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const InvoiceHomePage(invoiceKey: null),
        ),
      );
    }

    if (isAdLoaded.value && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          isAdLoaded.value = false;
          preloadInterstitialAd();
          goToNextPage();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          isAdLoaded.value = false;
          preloadInterstitialAd();
          goToNextPage();
        },
      );

      _interstitialAd!.show();
    } else {
      if (Get.context == null) {
        debugPrint('Cannot show dialog: no context available');
        goToNextPage(); // fallback if no context
        return;
      }

      Get.generalDialog(
        barrierDismissible: false,
        barrierLabel: "Loading",
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Loading Interstitial Ad...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      );

      isAdLoading.value = true;

      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            Get.back();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                isAdLoaded.value = false;
                preloadInterstitialAd();
                goToNextPage();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                isAdLoaded.value = false;
                preloadInterstitialAd();
                goToNextPage();
              },
            );

            ad.show();
            isAdLoaded.value = false;
            isAdLoading.value = false;
          },
          onAdFailedToLoad: (LoadAdError error) {
            Get.back();
            isAdLoading.value = false;
            goToNextPage();
          },
        ),
      );
    }
  }

  void preloadRewardedAd({int retryCount = 0, int maxRetries = 3}) {
    final adUnitId = AdUnits.rewarded;
    if (isRewardedLoading.value || isRewardedLoaded.value || retryCount >= maxRetries) return;
    isRewardedLoading.value = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          isRewardedLoaded.value = true;
          isRewardedLoading.value = false;
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              isRewardedLoaded.value = false;
              preloadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              isRewardedLoaded.value = false;
              preloadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Rewarded Ad failed to load: ${error.code} - ${error.message}');
          isRewardedLoading.value = false;
          Future.delayed(Duration(seconds: 5), () {
            preloadRewardedAd(retryCount: retryCount + 1);
          });
        },
      ),
    );
  }

  void showOrLoadRewardedAd({required VoidCallback onRewarded, int retryCount = 0, int maxRetries = 3}) {
    final adUnitId = AdUnits.rewarded;
    if (isRewardedLoaded.value && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          onRewarded();
        },
      );
    } else if (retryCount < maxRetries) {
      if (Get.context == null) {
        debugPrint('Cannot show dialog: no context available');
        onRewarded(); // fallback if no context
        return;
      }
      Get.generalDialog(
        barrierDismissible: true, // Made dismissible
        barrierLabel: "Loading",
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Loading Rewarded Ad...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      );
      isRewardedLoading.value = true;
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            Get.back();
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                preloadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                preloadRewardedAd();
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) {
                print('User earned reward: ${reward.amount} ${reward.type}');
                onRewarded();
              },
            );
            isRewardedLoaded.value = false;
            isRewardedLoading.value = false;
          },
            onAdFailedToLoad: (LoadAdError error) {
              print('Rewarded Ad failed to load: ${error.code} - ${error.message}');
              Get.back();
              isRewardedLoading.value = false;

              if (retryCount + 1 >= maxRetries) {
                // Max retries reached → proceed anyway
                print("Max retries reached. Proceeding without ad.");
                onRewarded();
              } else {
                Future.delayed(Duration(seconds: 5), () {
                  showOrLoadRewardedAd(
                    onRewarded: onRewarded,
                    retryCount: retryCount + 1,
                    maxRetries: maxRetries,
                  );
                });
              }
            }
        ),
      );
    }
  }


  void preloadNativeAd() {
    final adUnitId = AdUnits.native;
    if (isNativeLoading.value || isNativeLoaded.value) return;
    isNativeLoading.value = true;
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          isNativeLoaded.value = true;
          isNativeLoading.value = false;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          isNativeLoading.value = false;
        },
      ),
    )..load();
  }

  NativeAd? get nativeAd => _nativeAd;


  final RxBool isBannerLoading = false.obs;
  final RxBool isBannerLoaded = false.obs;
  BannerAd? _bannerAd;

  void preloadBannerAd({int retryCount = 0, int maxRetries = 3}) {
    final adUnitId = AdUnits.banner;
    if (isBannerLoading.value || isBannerLoaded.value || retryCount >= maxRetries) return;
    isBannerLoading.value = true;
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('Banner Ad loaded');
          isBannerLoaded.value = true;
          isBannerLoading.value = false;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Banner Ad failed to load: ${error.code} - ${error.message}');
          ad.dispose();
          isBannerLoading.value = false;
          Future.delayed(Duration(seconds: 5), () {
            preloadBannerAd(retryCount: retryCount + 1);
          });
        },
        onAdOpened: (Ad ad) => print('Banner Ad opened'),
        onAdImpression: (Ad ad) => print('Banner Ad impression'),
      ),
    )..load();
  }

  Widget getBannerAdWidget() {
    if (isBannerLoaded.value && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return SizedBox.shrink();
  }

  @override
  void onClose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    _bannerAd?.dispose(); // Added banner ad disposal
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}

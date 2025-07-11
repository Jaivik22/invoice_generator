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
    final prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt('launch_count') ?? 0;

    launchCount += 1;
    await prefs.setInt('launch_count', launchCount);

    print("Launch count: $launchCount");

    if (launchCount <= 2) {
      print("Skipping ads — first or second launch.");
      return;
    }

    // Now proceed with ad logic
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      print("No internet connection — waiting for internet to load ads.");
      listenForInternetAndLoadAds();
    } else {
      await initializeAds(); // <- inside this you can call preloadInterstitialAd()
    }
  }



  Future<void> initializeAds() async {
    await AdUnits.loadFromRemoteConfig();
    await MobileAds.instance.initialize();
    preloadInterstitialAd();
    preloadRewardedAd();
    preloadNativeAd();
    preloadBannerAd1();
    preloadBannerAd2();
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
    if (isAdLoading.value || isAdLoaded.value) return;

    isAdLoading.value = true;

    InterstitialAd.load(
      adUnitId: AdUnits.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          isAdLoaded.value = true;
          isAdLoading.value = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
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
          isAdLoaded.value = false;
        },
      ),
    );
  }

  Future<bool> canShowAds() async {
    final prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt('launch_count') ?? 0;
    return launchCount > 2;
  }

  Future<void> showOrLoadInterstitialAd(BuildContext context, {required VoidCallback onAdFinished}) async {
    if (!await canShowAds()) {
    print("Skipping interstitial ad due to launch count");
    // Directly continue your navigation or flow here since ad skipped
    onAdFinished();
    return;
    }
    if (isAdLoaded.value && _interstitialAd != null) {
      try {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            isAdLoaded.value = false;
            preloadInterstitialAd();
            onAdFinished();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            isAdLoaded.value = false;
            preloadInterstitialAd();
            onAdFinished();
          },
        );
        _interstitialAd!.show();
        isAdLoaded.value = false;
        _interstitialAd = null;
      } catch (e) {
        onAdFinished();
      }
    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "Loading",
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text("Loading Interstitial Ad...", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        },
      );

      InterstitialAd.load(
        adUnitId: AdUnits.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            Navigator.of(context, rootNavigator: true).pop();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                preloadInterstitialAd();
                onAdFinished();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                preloadInterstitialAd();
                onAdFinished();
              },
            );

            try {
              ad.show();
            } catch (e) {
              onAdFinished();
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            Navigator.of(context, rootNavigator: true).pop();
            onAdFinished();
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
  final RxBool isBanner1Loaded = false.obs;
  final RxBool isBanner2Loaded = false.obs;
  BannerAd? _bannerAd1;
  BannerAd? _bannerAd2;


  void preloadBannerAd1() {
    if (isBanner1Loaded.value) return;

    _bannerAd1 = BannerAd(
      adUnitId: AdUnits.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => isBanner1Loaded.value = true,
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          isBanner1Loaded.value = false;
        },
      ),
    )..load();
  }

  void preloadBannerAd2() {
    if (isBanner2Loaded.value) return;

    _bannerAd2 = BannerAd(
      adUnitId: AdUnits.banner,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) => isBanner2Loaded.value = true,
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          isBanner2Loaded.value = false;
        },
      ),
    )..load();
  }


  Widget getBannerAdWidget1() {
    if (isBanner1Loaded.value && _bannerAd1 != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd1!.size.width.toDouble(),
        height: _bannerAd1!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd1!),
      );
    }
    return SizedBox.shrink();
  }

  Widget getBannerAdWidget2() {
    if (isBanner2Loaded.value && _bannerAd2 != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd2!.size.width.toDouble(),
        height: _bannerAd2!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd2!),
      );
    }
    return SizedBox.shrink();
  }


  @override
  void onClose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
    _bannerAd1?.dispose(); // Added banner ad disposal
    _bannerAd2?.dispose(); // Added banner ad disposal
    _connectivitySubscription?.cancel();
    super.onClose();
  }
}

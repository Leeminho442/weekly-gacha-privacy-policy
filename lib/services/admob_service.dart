import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

/// AdMob 광고 관리 서비스
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // 광고 초기화 여부
  bool _isInitialized = false;
  
  // 배너 광고
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  
  // 보상형 광고
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  /// 광고 단위 ID (테스트/프로덕션)
  static const String _bannerAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // 테스트 배너 ID
      : 'ca-app-pub-1090799510694393/9138375990'; // 프로덕션 배너 광고 ID
      
  static const String _rewardedAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917' // 테스트 보상형 ID
      : 'ca-app-pub-1090799510694393/6738717014'; // 프로덕션 보상형 광고 ID

  /// AdMob 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Google Mobile Ads SDK 초기화
      await MobileAds.instance.initialize();
      
      // 광고 설정
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: kDebugMode ? ['YOUR_TEST_DEVICE_ID'] : [],
        ),
      );
      
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ AdMob initialized successfully');
      }
      
      // 배너 광고 미리 로드
      loadBannerAd();
      
      // 보상형 광고 미리 로드
      loadRewardedAd();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AdMob initialization failed: $e');
      }
    }
  }

  /// 배너 광고 로드
  void loadBannerAd() {
    // 웹 플랫폼에서는 광고 미지원
    if (kIsWeb) return;
    
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          if (kDebugMode) {
            debugPrint('✅ Banner ad loaded');
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdReady = false;
          ad.dispose();
          if (kDebugMode) {
            debugPrint('❌ Banner ad failed to load: $error');
          }
          
          // 5초 후 재시도
          Future.delayed(const Duration(seconds: 5), () {
            loadBannerAd();
          });
        },
      ),
    );

    _bannerAd?.load();
  }

  /// 보상형 광고 로드
  void loadRewardedAd() {
    // 웹 플랫폼에서는 광고 미지원
    if (kIsWeb) return;
    
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          
          // 광고 닫힘 감지
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
              
              // 다음 광고 미리 로드
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
              
              if (kDebugMode) {
                debugPrint('❌ Rewarded ad failed to show: $error');
              }
              
              // 다음 광고 미리 로드
              loadRewardedAd();
            },
          );
          
          if (kDebugMode) {
            debugPrint('✅ Rewarded ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          if (kDebugMode) {
            debugPrint('❌ Rewarded ad failed to load: $error');
          }
          
          // 10초 후 재시도
          Future.delayed(const Duration(seconds: 10), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  /// 배너 광고 표시 여부
  bool get isBannerAdReady => _isBannerAdReady;

  /// 배너 광고 가져오기
  BannerAd? get bannerAd => _bannerAd;

  /// 보상형 광고 표시 가능 여부
  bool get isRewardedAdReady => _isRewardedAdReady;

  /// 보상형 광고 표시
  /// [onUserEarnedReward]: 사용자가 보상을 받았을 때 호출되는 콜백
  Future<void> showRewardedAd({
    required Function() onUserEarnedReward,
    Function()? onAdDismissed,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Rewarded ad is not ready yet');
      }
      return;
    }

    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) {
        if (kDebugMode) {
          debugPrint('✅ User earned reward: ${reward.amount} ${reward.type}');
        }
        onUserEarnedReward();
      },
    );

    // 광고 닫힘 콜백
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        
        if (onAdDismissed != null) {
          onAdDismissed();
        }
        
        // 다음 광고 미리 로드
        loadRewardedAd();
      },
    );
  }

  /// 리소스 정리
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
    
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}

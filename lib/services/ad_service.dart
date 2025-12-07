import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // 테스트 광고 ID (실제 배포 시 변경 필요)
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // 테스트 배너 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // 테스트 배너 ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // 테스트 보상형 광고 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // 테스트 보상형 광고 ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// AdMob SDK 초기화
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// 배너 광고 생성
  BannerAd createBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('배너 광고 로드 완료');
        },
        onAdFailedToLoad: (ad, error) {
          print('배너 광고 로드 실패: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
    return _bannerAd!;
  }

  /// 보상형 광고 로드
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('보상형 광고 로드 완료');
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          // 광고 이벤트 리스너 설정
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('보상형 광고 표시 시작');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('보상형 광고 닫힘');
              ad.dispose();
              _isRewardedAdReady = false;
              // 다음 광고 미리 로드
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('보상형 광고 표시 실패: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              // 다음 광고 미리 로드
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('보상형 광고 로드 실패: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  /// 보상형 광고 표시 (보상 콜백 포함)
  Future<bool> showRewardedAd(Function(int reward) onRewarded) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      print('보상형 광고가 준비되지 않았습니다');
      return false;
    }

    bool rewardEarned = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('보상 획득: ${reward.amount} ${reward.type}');
        onRewarded(reward.amount.toInt());
        rewardEarned = true;
      },
    );

    return rewardEarned;
  }

  /// 보상형 광고 준비 여부 확인
  bool get isRewardedAdReady => _isRewardedAdReady;

  /// 리소스 정리
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}

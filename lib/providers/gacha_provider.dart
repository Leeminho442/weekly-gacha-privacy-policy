import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import '../models/card_data.dart';
import '../services/gacha_service.dart';

class GachaProvider with ChangeNotifier {
  final GachaService _gachaService = GachaService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<OwnedCard> _ownedCards = [];
  Map<String, CardStock> _cardStocks = {};
  int _dailyPulls = 3;
  int _bonusTickets = 0; // 쿠폰/초대로 받은 보너스 티켓
  int _dailyAdWatches = 0; // 오늘 시청한 광고 횟수
  DateTime? _lastResetDate;
  DateTime? _lastAdResetDate;
  bool _isLoading = false;
  
  static const int maxDailyAdWatches = 5; // 일일 광고 시청 제한
  
  String? get currentUserId => _auth.currentUser?.uid;

  List<OwnedCard> get ownedCards => _ownedCards;
  Map<String, CardStock> get cardStocks => _cardStocks;
  int get dailyPulls => _dailyPulls;
  int get bonusTickets => _bonusTickets;
  int get totalPulls => _dailyPulls + _bonusTickets; // 총 사용 가능한 뽑기 수
  bool get isLoading => _isLoading;
  
  // 광고 시청 관련
  int get dailyAdWatches => _dailyAdWatches;
  int get remainingAdWatches => maxDailyAdWatches - _dailyAdWatches;
  bool get canWatchAd => _dailyAdWatches < maxDailyAdWatches;

  GachaProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('[GachaProvider] Starting initialization...');
      }
      
      await _gachaService.initializeStock();
      if (kDebugMode) {
        print('[GachaProvider] Stock initialized');
      }
      
      await _loadData();
      if (kDebugMode) {
        print('[GachaProvider] Data loaded successfully');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('[GachaProvider] Initialization error: $e');
      }
      // 에러 발생 시에도 로딩 상태 해제 및 기본값 설정
      _isLoading = false;
      _dailyPulls = 3;
      _bonusTickets = 0;
      _ownedCards = [];
      notifyListeners();
    }
  }

  Future<void> _loadData() async {
    final userId = currentUserId;
    if (userId == null) {
      // 로그인하지 않은 상태 - 기본값만 설정
      if (kDebugMode) {
        print('[GachaProvider] User not logged in - using default values');
      }
      _dailyPulls = 3;
      _bonusTickets = 0;
      _ownedCards = [];
      _cardStocks = await _gachaService.getAllStocks();
      notifyListeners();
      return;
    }
    
    try {
      if (kDebugMode) {
        print('[GachaProvider] Loading data for user: $userId');
      }
      
      // Firestore에서 사용자 데이터 로드
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        if (kDebugMode) {
          print('[GachaProvider] User document exists');
        }
        final data = userDoc.data()!;
        _dailyPulls = data['dailyPulls'] ?? 3;
        _bonusTickets = data['bonusTickets'] ?? 0;
        _dailyAdWatches = data['dailyAdWatches'] ?? 0;
        
        final lastReset = data['lastResetDate'] as Timestamp?;
        if (lastReset != null) {
          _lastResetDate = lastReset.toDate();
        }
        
        final lastAdReset = data['lastAdResetDate'] as Timestamp?;
        if (lastAdReset != null) {
          _lastAdResetDate = lastAdReset.toDate();
        }
      } else {
        // 신규 사용자 - 기본값
        if (kDebugMode) {
          print('[GachaProvider] New user - setting defaults');
        }
        _dailyPulls = 3;
        _bonusTickets = 0;
        _dailyAdWatches = 0;
      }
      
      // Check if we need to reset daily pulls and ad watches
      await _checkDailyReset();
      await _checkAdReset();
      
      // Load owned cards
      if (kDebugMode) {
        print('[GachaProvider] Loading owned cards...');
      }
      _ownedCards = await _gachaService.getUserCards(userId);
      if (kDebugMode) {
        print('[GachaProvider] Loaded ${_ownedCards.length} cards');
      }
      
      // Load card stocks
      if (kDebugMode) {
        print('[GachaProvider] Loading card stocks...');
      }
      _cardStocks = await _gachaService.getAllStocks();
      if (kDebugMode) {
        print('[GachaProvider] Loaded ${_cardStocks.length} card stocks');
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[GachaProvider] Load data error: $e');
        print('[GachaProvider] Stack trace: $stackTrace');
      }
      // 에러 발생 시 기본값
      _dailyPulls = 3;
      _bonusTickets = 0;
      _ownedCards = [];
      _cardStocks = {};
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final userId = currentUserId;
    if (userId == null) return;
    
    try {
      await _firestore.collection('users').doc(userId).update({
        'dailyPulls': _dailyPulls,
        'bonusTickets': _bonusTickets,
        'dailyAdWatches': _dailyAdWatches,
        'lastResetDate': FieldValue.serverTimestamp(),
        'lastAdResetDate': _lastAdResetDate != null 
            ? Timestamp.fromDate(_lastAdResetDate!) 
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Save data error: $e');
    }
  }

  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    if (_lastResetDate == null ||
        now.difference(_lastResetDate!).inHours >= 24) {
      _dailyPulls = 3;
      _lastResetDate = now;
      await _saveData(); // Firestore에 저장
    }
  }
  
  Future<void> _checkAdReset() async {
    final now = DateTime.now();
    if (_lastAdResetDate == null ||
        now.difference(_lastAdResetDate!).inHours >= 24) {
      _dailyAdWatches = 0;
      _lastAdResetDate = now;
      await _saveData(); // Firestore에 저장
    }
  }

  Future<OwnedCard?> pullGacha() async {
    if (totalPulls <= 0) {
      throw Exception('남은 뽑기 횟수가 없습니다!');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }
      
      final pulledCard = await _gachaService.pullCard(userId);
      
      if (pulledCard == null) {
        _isLoading = false;
        notifyListeners();
        throw Exception('해당 등급의 모든 카드가 품절되었습니다!');
      }

      _ownedCards.add(pulledCard);
      
      // 보너스 티켓을 먼저 소진, 그 다음 일일 뽑기 소진
      if (_bonusTickets > 0) {
        _bonusTickets--;
      } else {
        _dailyPulls--;
      }
      
      // Update stocks
      _cardStocks = await _gachaService.getAllStocks();
      
      await _saveData();
      
      _isLoading = false;
      notifyListeners();

      return pulledCard;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  /// 보너스 티켓 추가 (쿠폰/초대 보상)
  Future<void> addBonusTickets(int amount) async {
    _bonusTickets += amount;
    await _saveData();
    notifyListeners();
  }
  
  /// 광고 시청 후 보상 처리
  Future<void> rewardAdWatch() async {
    if (!canWatchAd) {
      throw Exception('오늘의 광고 시청 횟수를 모두 사용했습니다!');
    }
    
    await _checkAdReset(); // 자정 넘었으면 리셋
    
    _dailyAdWatches++;
    _bonusTickets++; // 광고 시청 시 보너스 티켓 1개 지급
    
    await _saveData();
    notifyListeners();
  }

  /// 사용자 데이터 새로고침 (쿠폰 사용 후 등)
  Future<void> refreshUserData() async {
    await _loadData();
  }

  bool hasCard(String cardId) {
    return _ownedCards.any((card) => card.cardId == cardId);
  }

  List<OwnedCard> getCardsByCardId(String cardId) {
    return _ownedCards.where((card) => card.cardId == cardId).toList();
  }

  int get totalCards => _ownedCards.length;
  int get uniqueCards => 
      _ownedCards.map((card) => card.cardId).toSet().length;
  int get totalPossibleCards => CardData.allCards.length;

  // 컬렉션용 카드 리스트 (중복 카드를 하나로 묶음)
  List<CollectedCard> get collectedCards {
    final Map<String, List<OwnedCard>> cardGroups = {};
    
    // cardId별로 그룹화
    for (final card in _ownedCards) {
      if (!cardGroups.containsKey(card.cardId)) {
        cardGroups[card.cardId] = [];
      }
      cardGroups[card.cardId]!.add(card);
    }
    
    // CollectedCard로 변환
    return cardGroups.entries
        .map((entry) => CollectedCard.fromOwnedCards(entry.value))
        .toList()
      ..sort((a, b) {
        // 등급별로 정렬 (높은 등급부터)
        if (a.rarity != b.rarity) {
          return b.rarity.index.compareTo(a.rarity.index);
        }
        // 같은 등급이면 이름순
        return a.name.compareTo(b.name);
      });
  }

  // 등급별 소유 카드 수
  int getCardCountByRarity(CardRarity rarity) {
    return _ownedCards.where((card) => card.rarity == rarity).length;
  }

  // 재고 새로고침
  Future<void> refreshStocks() async {
    _isLoading = true;
    notifyListeners();
    
    _cardStocks = await _gachaService.getAllStocks();
    
    _isLoading = false;
    notifyListeners();
  }

  // 테스트용: 재고 리셋
  Future<void> resetAllData() async {
    _isLoading = true;
    notifyListeners();
    
    await _gachaService.resetStock();
    await _initialize();
  }
  
  // 특정 카드의 발행된 수량 조회 (보유자 수 근사값)
  int getIssuedCardCount(String cardId) {
    // Firestore의 currentSupply (실제 발행된 수량)를 반환
    final stock = _cardStocks[cardId];
    
    if (stock != null) {
      return stock.currentSupply; // 현재 발행된 수량
    }
    
    // 재고 정보가 없는 경우 0 반환
    return 0;
  }
  
  // 로그아웃
  Future<void> logout() async {
    try {
      await _auth.signOut();
      
      // 상태 초기화
      _ownedCards = [];
      _cardStocks = {};
      _dailyPulls = 3;
      _bonusTickets = 0;
      _dailyAdWatches = 0;
      _lastResetDate = null;
      _lastAdResetDate = null;
      _isLoading = false;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout error: $e');
      }
      rethrow;
    }
  }
}

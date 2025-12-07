import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../models/card_data.dart';

/// 시즌 관리 서비스
class SeasonService {
  static const String _currentSeasonKey = 'current_season';
  static const String _seasonHistoryKey = 'season_history';
  
  // 시즌 1의 기본 발행량
  static const int baseSeasonSupply = 10000;
  
  // 시즌 주기: 7일 (1주일)
  static const Duration seasonDuration = Duration(days: 7);

  /// 현재 시즌 가져오기
  Future<Season> getCurrentSeason() async {
    final prefs = await SharedPreferences.getInstance();
    final seasonJson = prefs.getString(_currentSeasonKey);
    
    if (seasonJson != null) {
      final data = _parseSeasonJson(seasonJson);
      final season = Season.fromFirestore(data);
      
      // 시즌이 종료되었는지 확인
      if (season.isEnded) {
        return await _createNextSeason(season);
      }
      
      return season;
    } else {
      // 첫 시즌 생성
      return await _createFirstSeason();
    }
  }

  /// 첫 시즌 생성
  Future<Season> _createFirstSeason() async {
    final now = DateTime.now();
    final startDate = _getNextMonday(now); // 다음 월요일 00:00
    final endDate = startDate.add(seasonDuration);
    
    final season = Season(
      seasonNumber: 1,
      startDate: startDate,
      endDate: endDate,
      totalSupply: baseSeasonSupply,
      participantCount: 0,
      isActive: true,
    );
    
    await _saveSeason(season);
    return season;
  }

  /// 다음 시즌 생성 (자동 전환)
  Future<Season> _createNextSeason(Season previousSeason) async {
    final stats = await getSeasonStats(previousSeason.seasonName);
    
    // 동적 발행량 계산: 이전 시즌 참여자 수 x 100
    int newTotalSupply;
    if (stats.uniqueParticipants > 0) {
      newTotalSupply = stats.uniqueParticipants * 100;
    } else {
      // 참여자가 없으면 이전 시즌과 동일
      newTotalSupply = previousSeason.totalSupply;
    }
    
    // 최소 발행량 보장 (1,000장)
    if (newTotalSupply < 1000) {
      newTotalSupply = 1000;
    }
    
    final now = DateTime.now();
    final startDate = _getNextMonday(now);
    final endDate = startDate.add(seasonDuration);
    
    final newSeason = Season(
      seasonNumber: previousSeason.seasonNumber + 1,
      startDate: startDate,
      endDate: endDate,
      totalSupply: newTotalSupply,
      participantCount: 0,
      isActive: true,
    );
    
    // 이전 시즌 히스토리에 저장
    await _saveSeasonHistory(previousSeason);
    
    // 새 시즌 저장
    await _saveSeason(newSeason);
    
    // 카드 재고 초기화
    await _resetCardStocksForNewSeason(newSeason);
    
    return newSeason;
  }

  /// 다음 월요일 00:00 계산
  DateTime _getNextMonday(DateTime date) {
    // 현재가 월요일이고 아직 시간이 남았으면 이번 주 월요일
    // 아니면 다음 주 월요일
    final daysUntilMonday = (DateTime.monday - date.weekday + 7) % 7;
    
    DateTime nextMonday;
    if (daysUntilMonday == 0 && date.hour == 0 && date.minute == 0) {
      // 정확히 월요일 00:00
      nextMonday = date;
    } else if (daysUntilMonday == 0) {
      // 월요일이지만 시간이 지났으면 다음 주
      nextMonday = DateTime(date.year, date.month, date.day + 7);
    } else {
      nextMonday = DateTime(date.year, date.month, date.day + daysUntilMonday);
    }
    
    // 00:00:00으로 설정
    return DateTime(nextMonday.year, nextMonday.month, nextMonday.day);
  }

  /// 시즌 저장
  Future<void> _saveSeason(Season season) async {
    final prefs = await SharedPreferences.getInstance();
    final json = _seasonToJson(season.toFirestore());
    await prefs.setString(_currentSeasonKey, json);
  }

  /// 시즌 히스토리 저장
  Future<void> _saveSeasonHistory(Season season) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_seasonHistoryKey) ?? [];
    
    final json = _seasonToJson(season.toFirestore());
    history.add(json);
    
    await prefs.setStringList(_seasonHistoryKey, history);
  }

  /// 새 시즌을 위한 카드 재고 초기화
  Future<void> _resetCardStocksForNewSeason(Season newSeason) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 총 발행량 기준으로 등급별 발행량 재계산
    final rarityRatios = {
      CardRarity.normal: 0.50,      // 50%
      CardRarity.rare: 0.30,         // 30%
      CardRarity.superRare: 0.15,    // 15%
      CardRarity.ultraRare: 0.048,   // 4.8%
      CardRarity.secret: 0.002,      // 0.2%
    };
    
    for (final card in CardData.allCards) {
      // 등급별 비율에 따라 최대 발행량 계산
      final raritySupply = (newSeason.totalSupply * rarityRatios[card.rarity]!).round();
      // CardRarity enum을 String으로 변환
      final rarityString = card.rarity.toString().split('.').last;
      final cardsOfRarity = CardData.getCardsByRarity(rarityString);
      final maxSupplyPerCard = (raritySupply / cardsOfRarity.length).round();
      
      // 재고 초기화
      await prefs.setInt('card_stock_${card.id}', 0);
      await prefs.setInt('card_max_supply_${card.id}', maxSupplyPerCard);
    }
  }

  /// 시즌 통계 조회
  Future<SeasonStats> getSeasonStats(String seasonName) async {
    final prefs = await SharedPreferences.getInstance();
    final ownedCardsData = prefs.getStringList('owned_cards') ?? [];
    
    // 참여자 수 계산 (실제로는 고유 user_id 기준)
    final uniqueUsers = <String>{};
    int totalIssued = 0;
    final rarityCount = <CardRarity, int>{
      CardRarity.normal: 0,
      CardRarity.rare: 0,
      CardRarity.superRare: 0,
      CardRarity.ultraRare: 0,
      CardRarity.secret: 0,
    };
    
    for (final data in ownedCardsData) {
      final parts = data.split('|');
      if (parts.length >= 3) {
        totalIssued++;
        uniqueUsers.add('user_001'); // Mock user ID
        
        // 등급 카운트
        final cardId = parts[0];
        final card = CardData.getCardById(cardId);
        if (card != null) {
          rarityCount[card.rarity] = (rarityCount[card.rarity] ?? 0) + 1;
        }
      }
    }
    
    final season = await getCurrentSeason();
    
    return SeasonStats(
      seasonName: seasonName,
      totalCardsIssued: totalIssued,
      totalSupply: season.totalSupply,
      uniqueParticipants: uniqueUsers.length,
      rarityDistribution: rarityCount,
    );
  }

  /// 모든 시즌 히스토리 조회
  Future<List<Season>> getSeasonHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_seasonHistoryKey) ?? [];
    
    return history.map((json) {
      final data = _parseSeasonJson(json);
      return Season.fromFirestore(data);
    }).toList();
  }

  /// 참여자 수 증가
  Future<void> incrementParticipantCount() async {
    final season = await getCurrentSeason();
    final updatedSeason = Season(
      seasonNumber: season.seasonNumber,
      startDate: season.startDate,
      endDate: season.endDate,
      totalSupply: season.totalSupply,
      participantCount: season.participantCount + 1,
      isActive: season.isActive,
    );
    
    await _saveSeason(updatedSeason);
  }

  // JSON 파싱 헬퍼
  Map<String, dynamic> _parseSeasonJson(String json) {
    final parts = json.split('|');
    return {
      'season_number': int.parse(parts[0]),
      'start_date': parts[1],
      'end_date': parts[2],
      'total_supply': int.parse(parts[3]),
      'participant_count': int.parse(parts[4]),
      'is_active': parts[5] == 'true',
    };
  }

  String _seasonToJson(Map<String, dynamic> data) {
    return '${data['season_number']}|${data['start_date']}|${data['end_date']}|${data['total_supply']}|${data['participant_count']}|${data['is_active']}';
  }
}

enum CardRarity {
  normal,
  rare,
  superRare,
  ultraRare,
  secret,
}

class GachaCard {
  final String id; // 카드 종류 ID (예: "sakura_girl")
  final String name;
  final CardRarity rarity;
  final String imagePath;
  final String description;
  final int maxSupply; // 이 카드의 최대 발행량
  
  GachaCard({
    required this.id,
    required this.name,
    required this.rarity,
    required this.imagePath,
    required this.description,
    required this.maxSupply,
  });

  String get rarityText {
    switch (rarity) {
      case CardRarity.normal:
        return '노말';
      case CardRarity.rare:
        return '레어';
      case CardRarity.superRare:
        return '슈퍼레어';
      case CardRarity.ultraRare:
        return '울트라레어';
      case CardRarity.secret:
        return '시크릿';
    }
  }

  String get rarityTextEn {
    switch (rarity) {
      case CardRarity.normal:
        return 'NORMAL';
      case CardRarity.rare:
        return 'RARE';
      case CardRarity.superRare:
        return 'SUPER RARE';
      case CardRarity.ultraRare:
        return 'ULTRA RARE';
      case CardRarity.secret:
        return 'SECRET';
    }
  }

  double get pullChance {
    switch (rarity) {
      case CardRarity.normal:
        return 0.70; // 70%
      case CardRarity.rare:
        return 0.20; // 20%
      case CardRarity.superRare:
        return 0.07; // 7%
      case CardRarity.ultraRare:
        return 0.025; // 2.5%
      case CardRarity.secret:
        return 0.005; // 0.5%
    }
  }
}

// 개별 카드 인스턴스 (실제로 뽑은 카드 한 장)
class OwnedCard {
  final String ownedCardId; // Firestore 문서 ID
  final String cardId; // 카드 종류 ID
  final String userId; // 소유자 ID
  final int serialNumber; // 시리얼 넘버 (No.0001)
  final String season; // 시즌 정보 (예: "Season 1")
  final DateTime obtainedAt; // 획득 날짜
  
  // 카드 정보 (join용)
  final String name;
  final CardRarity rarity;
  final String imagePath;
  final String description;
  final int maxSupply;

  OwnedCard({
    required this.ownedCardId,
    required this.cardId,
    required this.userId,
    required this.serialNumber,
    required this.season,
    required this.obtainedAt,
    required this.name,
    required this.rarity,
    required this.imagePath,
    required this.description,
    required this.maxSupply,
  });

  // 복사본 생성
  OwnedCard copyWith({
    String? ownedCardId,
    String? cardId,
    String? userId,
    int? serialNumber,
    String? season,
    DateTime? obtainedAt,
    String? name,
    CardRarity? rarity,
    String? imagePath,
    String? description,
    int? maxSupply,
  }) {
    return OwnedCard(
      ownedCardId: ownedCardId ?? this.ownedCardId,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      serialNumber: serialNumber ?? this.serialNumber,
      season: season ?? this.season,
      obtainedAt: obtainedAt ?? this.obtainedAt,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      maxSupply: maxSupply ?? this.maxSupply,
    );
  }
}

// 컬렉션용 카드 (중복 카드를 하나로 묶어서 관리)
class CollectedCard {
  final String cardId; // 카드 종류 ID
  final String name;
  final CardRarity rarity;
  final String imagePath;
  final String description;
  final int maxSupply;
  final List<int> serialNumbers; // 보유한 시리얼 넘버 리스트
  final int count; // 보유 수량

  CollectedCard({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.imagePath,
    required this.description,
    required this.maxSupply,
    required this.serialNumbers,
  }) : count = serialNumbers.length;

  // 대표 시리얼 넘버 (가장 빠른 번호)
  int get representativeSerial {
    if (serialNumbers.isEmpty) return 0;
    return serialNumbers.reduce((a, b) => a < b ? a : b);
  }

  String get representativeSerialText {
    return 'No.${representativeSerial.toString().padLeft(4, '0')}';
  }

  String get rarityText {
    switch (rarity) {
      case CardRarity.normal:
        return '노말';
      case CardRarity.rare:
        return '레어';
      case CardRarity.superRare:
        return '슈퍼레어';
      case CardRarity.ultraRare:
        return '울트라레어';
      case CardRarity.secret:
        return '시크릿';
    }
  }

  // OwnedCard 리스트에서 CollectedCard 생성
  static CollectedCard fromOwnedCards(List<OwnedCard> ownedCards) {
    if (ownedCards.isEmpty) {
      throw Exception('ownedCards cannot be empty');
    }

    final first = ownedCards.first;
    final serialNumbers = ownedCards.map((card) => card.serialNumber).toList()
      ..sort(); // 시리얼 넘버 오름차순 정렬

    return CollectedCard(
      cardId: first.cardId,
      name: first.name,
      rarity: first.rarity,
      imagePath: first.imagePath,
      description: first.description,
      maxSupply: first.maxSupply,
      serialNumbers: serialNumbers,
    );
  }

  // 새 시리얼 넘버 추가
  CollectedCard addSerial(int serialNumber) {
    final newSerials = [...serialNumbers, serialNumber]..sort();
    return CollectedCard(
      cardId: cardId,
      name: name,
      rarity: rarity,
      imagePath: imagePath,
      description: description,
      maxSupply: maxSupply,
      serialNumbers: newSerials,
    );
  }
}

// OwnedCard의 확장 메서드들 (파일 상단의 OwnedCard 클래스에 추가되어야 하지만 여기서 정의)
extension OwnedCardExtension on OwnedCard {
  String get serialNumberText {
    return 'No.${serialNumber.toString().padLeft(4, '0')}';
  }

  String get rarityText {
    switch (rarity) {
      case CardRarity.normal:
        return '노말';
      case CardRarity.rare:
        return '레어';
      case CardRarity.superRare:
        return '슈퍼레어';
      case CardRarity.ultraRare:
        return '울트라레어';
      case CardRarity.secret:
        return '시크릿';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'card_id': cardId,
      'user_id': userId,
      'serial_number': serialNumber,
      'season': season,
      'obtained_at': obtainedAt.toIso8601String(),
    };
  }
}

// 카드 발행 통계 (서버에서 관리)
class CardStock {
  final String cardId;
  final int currentSupply; // 현재 발행된 수량
  final int maxSupply; // 최대 발행량
  final String season;

  CardStock({
    required this.cardId,
    required this.currentSupply,
    required this.maxSupply,
    required this.season,
  });

  bool get isAvailable => currentSupply < maxSupply;
  int get remainingSupply => maxSupply - currentSupply;
  double get supplyPercentage => 
      maxSupply > 0 ? (currentSupply / maxSupply) * 100 : 0;

  Map<String, dynamic> toFirestore() {
    return {
      'card_id': cardId,
      'current_supply': currentSupply,
      'max_supply': maxSupply,
      'season': season,
    };
  }

  factory CardStock.fromFirestore(Map<String, dynamic> data) {
    return CardStock(
      cardId: data['card_id'] as String,
      currentSupply: data['current_supply'] as int,
      maxSupply: data['max_supply'] as int,
      season: data['season'] as String,
    );
  }
}

// 시즌 정보
class Season {
  final int seasonNumber; // 시즌 번호 (1, 2, 3...)
  final DateTime startDate; // 시작 일시
  final DateTime endDate; // 종료 일시
  final int totalSupply; // 이번 시즌 총 발행량
  final int participantCount; // 참여자 수
  final bool isActive; // 현재 활성 시즌인지

  Season({
    required this.seasonNumber,
    required this.startDate,
    required this.endDate,
    required this.totalSupply,
    required this.participantCount,
    required this.isActive,
  });

  String get seasonName => 'Season $seasonNumber';
  
  Duration get remainingTime => endDate.difference(DateTime.now());
  bool get isEnded => DateTime.now().isAfter(endDate);
  
  int get daysRemaining => remainingTime.inDays;
  int get hoursRemaining => remainingTime.inHours % 24;

  Map<String, dynamic> toFirestore() {
    return {
      'season_number': seasonNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_supply': totalSupply,
      'participant_count': participantCount,
      'is_active': isActive,
    };
  }

  factory Season.fromFirestore(Map<String, dynamic> data) {
    return Season(
      seasonNumber: data['season_number'] as int,
      startDate: DateTime.parse(data['start_date'] as String),
      endDate: DateTime.parse(data['end_date'] as String),
      totalSupply: data['total_supply'] as int,
      participantCount: data['participant_count'] as int? ?? 0,
      isActive: data['is_active'] as bool,
    );
  }
}

// 시즌 통계
class SeasonStats {
  final String seasonName;
  final int totalCardsIssued; // 총 발행된 카드 수
  final int totalSupply; // 총 발행량
  final int uniqueParticipants; // 고유 참여자 수
  final Map<CardRarity, int> rarityDistribution; // 등급별 발행 수
  
  SeasonStats({
    required this.seasonName,
    required this.totalCardsIssued,
    required this.totalSupply,
    required this.uniqueParticipants,
    required this.rarityDistribution,
  });

  double get issuedPercentage => 
      totalSupply > 0 ? (totalCardsIssued / totalSupply) * 100 : 0;
  
  int get remainingCards => totalSupply - totalCardsIssued;
  
  double get participationRate => 
      totalSupply > 0 ? (uniqueParticipants / (totalSupply / 100)) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'season_name': seasonName,
      'total_cards_issued': totalCardsIssued,
      'total_supply': totalSupply,
      'unique_participants': uniqueParticipants,
      'rarity_distribution': rarityDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}

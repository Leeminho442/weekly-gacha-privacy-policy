import 'card_model.dart';

class CardData {
  static const String currentSeason = "Season 1";
  static const int totalSeasonSupply = 10000; // 시즌 1 총 발행량

  static final List<GachaCard> allCards = [
    // ===== NORMAL CARDS (60% = 6,000장, 20종) =====
    // 각 카드당 300장씩 발행
    ...List.generate(20, (index) {
      final cardNumber = index + 1;
      return GachaCard(
        id: 'normal_$cardNumber',
        name: _getNormalCardName(cardNumber),
        rarity: CardRarity.normal,
        imagePath: 'assets/cards/common_card_${(index % 5) + 1}.png',
        description: _getNormalCardDesc(cardNumber),
        maxSupply: 300,
      );
    }),

    // ===== RARE CARDS (25% = 2,500장, 20종) =====
    // 각 카드당 125장씩 발행
    ...List.generate(20, (index) {
      final cardNumber = index + 1;
      return GachaCard(
        id: 'rare_$cardNumber',
        name: _getRareCardName(cardNumber),
        rarity: CardRarity.rare,
        imagePath: 'assets/cards/rare_card_${(index % 4) + 1}.png',
        description: _getRareCardDesc(cardNumber),
        maxSupply: 125,
      );
    }),

    // ===== SUPER RARE CARDS (10% = 1,000장, 10종) =====
    // 각 카드당 100장씩 발행
    ...List.generate(10, (index) {
      final cardNumber = index + 1;
      return GachaCard(
        id: 'sr_$cardNumber',
        name: _getSuperRareCardName(cardNumber),
        rarity: CardRarity.superRare,
        imagePath: 'assets/cards/super_rare_card_${(index % 3) + 1}.png',
        description: _getSuperRareCardDesc(cardNumber),
        maxSupply: 100,
      );
    }),

    // ===== ULTRA RARE CARDS (4% = 400장, 10종) =====
    // 각 카드당 40장씩 발행
    ...List.generate(10, (index) {
      final cardNumber = index + 1;
      return GachaCard(
        id: 'ur_$cardNumber',
        name: _getUltraRareCardName(cardNumber),
        rarity: CardRarity.ultraRare,
        imagePath: 'assets/cards/super_rare_card_${(index % 3) + 1}.png',
        description: _getUltraRareCardDesc(cardNumber),
        maxSupply: 40,
      );
    }),

    // ===== SECRET CARDS (1% = 100장, 10종) =====
    // 각 카드당 10장씩 발행
    ...List.generate(10, (index) {
      final cardNumber = index + 1;
      return GachaCard(
        id: 'secret_$cardNumber',
        name: _getSecretCardName(cardNumber),
        rarity: CardRarity.secret,
        imagePath: 'assets/cards/super_rare_card_${(index % 3) + 1}.png',
        description: _getSecretCardDesc(cardNumber),
        maxSupply: 10,
      );
    }),
  ];

  // Normal 카드 이름 생성
  static String _getNormalCardName(int number) {
    final names = [
      '사쿠라', '하루', '미코', '유키', '아이리',
      '소라', '히나', '렌', '카에데', '나나',
      '유이', '리오', '타쿠미', '코하루', '아오이',
      '사야', '미사키', '류세이', '아카리', '하루토'
    ];
    return names[number - 1];
  }

  static String _getNormalCardDesc(int number) {
    final descs = [
      '귀여운 핑크 헤어 소녀', '청순한 블루 헤어 소년', '활발한 고양이 귀 소녀',
      '지적인 안경 소년', '상냥한 포니테일 소녀', '하늘을 닮은 파란 눈동자',
      '밝은 미소의 소녀', '차가운 인상의 소년', '단풍처럼 붉은 머리카락',
      '작고 귀여운 소녀', '사랑스러운 트윈테일', '시원한 매력의 소년',
      '성실한 반장 타입', '봄꽃 같은 소녀', '푸른 하늘 같은 소년',
      '우아한 검은 머리', '활기찬 에너지', '별을 닮은 소년',
      '환한 빛의 소녀', '따뜻한 봄의 소년'
    ];
    return descs[number - 1];
  }

  // Rare 카드 이름 생성
  static String _getRareCardName(int number) {
    final names = [
      '루나', '스텔라', '플레임', '아쿠아', '윈디',
      '썬더', '프로스트', '블레이즈', '오션', '스카이',
      '섀도우', '라이트', '다크니스', '브라이트', '글로우',
      '미스트', '스톰', '레인', '클라우드', '스타'
    ];
    return names[number - 1];
  }

  static String _getRareCardDesc(int number) {
    final descs = [
      '마법소녀 퍼플', '신비한 달빛 마녀', '불꽃 궁수',
      '물의 마법사', '바람의 정령', '번개의 사도',
      '얼음의 여왕', '화염의 전사', '바다의 수호자',
      '하늘의 기사', '어둠의 마법사', '빛의 전사',
      '어둠의 기사', '빛의 수호자', '빛나는 별',
      '안개의 요정', '폭풍의 전사', '비의 마법사',
      '구름의 정령', '별빛의 마법사'
    ];
    return descs[number - 1];
  }

  // Super Rare 카드 이름 생성
  static String _getSuperRareCardName(int number) {
    final names = [
      '셀레스티아', '오로라', '아스트라', '루미나',
      '세라핌', '아리아', '크리스탈', '사파이어',
      '에메랄드', '다이아몬드'
    ];
    return names[number - 1];
  }

  static String _getSuperRareCardDesc(int number) {
    final descs = [
      '무지개 여신', '황금 프린세스', '별의 여신',
      '빛의 여신', '천사의 수호자', '하늘의 가수',
      '수정의 마법사', '사파이어 여왕', '에메랄드 공주',
      '다이아몬드 황후'
    ];
    return descs[number - 1];
  }

  // Ultra Rare 카드 이름 생성
  static String _getUltraRareCardName(int number) {
    final names = [
      '사쿠라 여왕', '디바인 라이트', '이터널 플레임',
      '세레스티얼', '옴니시아', '아카샤', '엘리시온',
      '파라다이스', '헤븐', '유토피아'
    ];
    return names[number - 1];
  }

  static String _getUltraRareCardDesc(int number) {
    final descs = [
      '벚꽃의 여왕', '신성한 빛의 수호자', '영원한 불꽃',
      '천상의 존재', '전지전능의 여신', '우주의 기록자',
      '낙원의 수호자', '천국의 문지기', '하늘의 주인',
      '이상향의 창조자'
    ];
    return descs[number - 1];
  }

  // Secret 카드 이름 생성
  static String _getSecretCardName(int number) {
    final names = [
      '코스믹 엔젤', '이터널 드림', '갤럭시 퀸',
      '스타라이트 엠프레스', '셀레스티얼 디바', '드래곤 하트',
      '피닉스 소울', '유니버스', '인피니티', '레전드'
    ];
    return names[number - 1];
  }

  static String _getSecretCardDesc(int number) {
    final descs = [
      '전 서버에 단 10장만 존재하는 전설의 카드',
      '영원한 꿈을 지닌 궁극의 카드',
      '은하계를 지배하는 여왕',
      '별빛의 황제', '천상의 가수',
      '용의 심장을 가진 자', '불사조의 영혼',
      '우주 그 자체', '무한의 힘', '전설의 시작'
    ];
    return descs[number - 1];
  }

  static List<GachaCard> getCardsByRarity(CardRarity rarity) {
    return allCards.where((card) => card.rarity == rarity).toList();
  }

  static GachaCard? getCardById(String cardId) {
    try {
      return allCards.firstWhere((card) => card.id == cardId);
    } catch (e) {
      return null;
    }
  }

  // 등급별 총 발행량
  static int getTotalSupplyByRarity(CardRarity rarity) {
    return allCards
        .where((card) => card.rarity == rarity)
        .fold(0, (sum, card) => sum + card.maxSupply);
  }

  // 등급별 카드 종류 수
  static int getCardTypeCountByRarity(CardRarity rarity) {
    return allCards.where((card) => card.rarity == rarity).length;
  }
}

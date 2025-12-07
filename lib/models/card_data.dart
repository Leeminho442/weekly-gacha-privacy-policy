import '../models/card_model.dart';

class CardData {
  static const String currentSeason = '2025 S1';

  // 70장 카드 데이터
  static final List<GachaCard> allCards = [
    // ============ NORMAL (노말) 20장 ============
    GachaCard(
      id: 'card_001',
      name: '사이버 라멘',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_001.png',
      description: '네온빛 국물에 홀로그램 면발이 춤춘다',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_002',
      name: '홀로 분재',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_002.png',
      description: '디지털 나무가 푸른 홀로그램으로 빛난다',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_003',
      name: '녹슨 카타나',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_003.png',
      description: '오래된 칼날에 새겨진 전설',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_004',
      name: '메카닉 고양이',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_004.png',
      description: '금속 털을 가진 야옹이가 지붕 위를 걷는다',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_005',
      name: '미래 캔',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_005.png',
      description: '빛나는 액체가 담긴 증기미학 캔',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_006',
      name: '빛나는 칩',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_006.png',
      description: '회로 무늬가 새겨진 마이크로칩',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_007',
      name: '벤딩 머신',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_007.png',
      description: '빗속 밤, 미래의 음료수 자판기',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_008',
      name: '종이 등',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_008.png',
      description: '전선에 매달린 스크린 등롱',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_009',
      name: '네온 스케이트',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_009.png',
      description: '네온 언더글로우가 빛나는 공중부양 스케이트보드',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_010',
      name: '키츠네 마스크',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_010.png',
      description: '반은 기계, 반은 정령의 여우 가면',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_011',
      name: '벤토 타이머',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_011.png',
      description: '알록달록 전선이 담긴 귀여운 도시락 타이머',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_012',
      name: '우산 검',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_012.png',
      description: '빗속에서 검이 되는 우산',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_013',
      name: '픽셀 벚꽃',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_013.png',
      description: '8비트로 떨어지는 분홍 꽃잎',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_014',
      name: '핫도그 로봇',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_014.png',
      description: '핫도그를 파는 작은 로봇 노점',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_015',
      name: '청소 봇',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_015.png',
      description: '골목을 청소하는 귀여운 둥근 로봇',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_016',
      name: '코인 스핀',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_016.png',
      description: '회전하는 3D 로고가 새겨진 암호화폐',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_017',
      name: '커피 드론',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_017.png',
      description: '커피를 배달하는 작은 드론',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_018',
      name: '게임패드 유령',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_018.png',
      description: '픽셀화된 게임패드가 허공에 떠있다',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_019',
      name: '네온 사무라이',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_019.png',
      description: '네온 갑옷을 입은 사무라이 동상',
      maxSupply: 1000,
    ),
    GachaCard(
      id: 'card_020',
      name: '사이버 그래피티',
      rarity: CardRarity.normal,
      imagePath: 'assets/cards/card_020.png',
      description: '네온 빛으로 칠해진 반란의 스프레이 아트',
      maxSupply: 1000,
    ),

    // ============ RARE (레어) 20장 ============
    GachaCard(
      id: 'card_021',
      name: '배달 라이더',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_021.png',
      description: '밤거리를 질주하는 배달원',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_022',
      name: '노점 요리사',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_022.png',
      description: '김이 모락모락 나는 길거리 음식을 만드는 사람',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_023',
      name: '오락실 게이머',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_023.png',
      description: '아케이드 게임에 몰두한 플레이어',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_024',
      name: '드론 파일럿',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_024.png',
      description: 'VR 헤드셋으로 드론을 조종하는 조종사',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_025',
      name: '로봇 셰프',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_025.png',
      description: '요리사 모자를 쓴 로봇이 국수를 담고 있다',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_026',
      name: '후드 해커',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_026.png',
      description: '가상 키보드로 타이핑하는 후드티의 해커',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_027',
      name: '경비 로봇',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_027.png',
      description: '붉은 눈을 가진 둥근 경비 로봇',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_028',
      name: '정보 상인',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_028.png',
      description: '데이터 패드를 든 신비한 선글라스의 인물',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_029',
      name: '메카닉 소녀',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_029.png',
      description: '고글을 쓰고 드라이버를 든 기계공 소녀',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_030',
      name: '가상 팝스타',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_030.png',
      description: '반짝이는 무대 위 귀여운 포즈의 가상 아이돌',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_031',
      name: '배달 특급',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_031.png',
      description: '헬멧과 백팩을 맨 질주하는 배송원',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_032',
      name: '검술 소년',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_032.png',
      description: '나무 검을 든 단호한 얼굴의 도장 소년',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_033',
      name: '노장 사이보그',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_033.png',
      description: '작업장에서 불꽃을 튀기며 망치질하는 늙은 사이보그',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_034',
      name: '전투 의무병',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_034.png',
      description: '적십자 마크의 흰 갑옷을 입고 환자를 스캔하는 메딕',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_035',
      name: '고물상',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_035.png',
      description: '로봇 팔을 가진 고철더미의 상인',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_036',
      name: '가면 아티스트',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_036.png',
      description: '스프레이 캔을 든 가면의 거리 예술가',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_037',
      name: '미래 경찰',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_037.png',
      description: '파란 제복을 입고 호루라기를 부는 교통 경찰',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_038',
      name: '사이버 승려',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_038.png',
      description: '사이버네틱 눈과 염주를 가진 승복의 승려',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_039',
      name: '바텐더 로봇',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_039.png',
      description: '네온 바 카운터에서 칵테일을 만드는 로봇',
      maxSupply: 300,
    ),
    GachaCard(
      id: 'card_040',
      name: 'VR 파일럿',
      rarity: CardRarity.rare,
      imagePath: 'assets/cards/card_040.png',
      description: 'VR 헤드셋과 컨트롤러를 든 조종사',
      maxSupply: 300,
    ),

    // ============ SUPER RARE (슈퍼 레어) 10장 ============
    GachaCard(
      id: 'card_041',
      name: '전기 검사',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_041.png',
      description: '번개 검을 휘두르는 역동적인 전사',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_042',
      name: '탱크 워리어',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_042.png',
      description: '거대한 망치를 든 중갑옷 전차 전사',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_043',
      name: '격투가',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_043.png',
      description: '너클을 끼고 충격 이펙트와 함께 펀치하는 격투가',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_044',
      name: '리본 댄서',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_044.png',
      description: '리본 검을 든 우아한 회전 무용수',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_045',
      name: '사무라이 저격수',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_045.png',
      description: '첨단 저격소총으로 조준하는 사무라이 갑옷의 저격수',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_046',
      name: '테크 프리스트',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_046.png',
      description: '구체가 달린 지팡이로 홀로그램을 시전하는 사제',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_047',
      name: '암살자',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_047.png',
      description: '숨겨진 칼날로 그림자 스텝하며 사라지는 암살자',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_048',
      name: '엔지니어',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_048.png',
      description: '렌치로 거대 메카를 수리하는 엔지니어',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_049',
      name: '곡예 도둑',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_049.png',
      description: '그래플링 훅으로 점프하는 지붕 위 도둑',
      maxSupply: 100,
    ),
    GachaCard(
      id: 'card_050',
      name: '비스트 테이머',
      rarity: CardRarity.superRare,
      imagePath: 'assets/cards/card_050.png',
      description: '빛나는 룬과 마법진으로 생명체를 소환하는 조련사',
      maxSupply: 100,
    ),

    // ============ ULTRA RARE (울트라 레어) 10장 ============
    GachaCard(
      id: 'card_051',
      name: '사이버 닌자',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_051.png',
      description: '이중 에너지 카타나로 잔상을 남기며 베는 사이버 닌자',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_052',
      name: '드래곤 나이트',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_052.png',
      description: '화염 검과 용 날개를 가진 전설의 기사',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_053',
      name: '팬텀',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_053.png',
      description: '흐르는 망토와 이중 권총, 보라색 오라의 유령',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_054',
      name: '네온 메이지',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_054.png',
      description: '떠다니는 크리스탈과 무지개 마법진으로 궁극의 주문을 시전하는 마법사',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_055',
      name: '타이탄 슬레이어',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_055.png',
      description: '거대한 대검과 번개, 충격파를 가진 거인 사냥꾼',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_056',
      name: '아이스 퀸',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_056.png',
      description: '얼음 왕관과 블리자드 지팡이를 든 서리의 여왕',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_057',
      name: '보이드 워커',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_057.png',
      description: '어둠의 포털과 우주 에너지로 현실을 찢는 존재',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_058',
      name: '피닉스 워리어',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_058.png',
      description: '불타는 날개와 부활의 불꽃을 가진 불사조 전사',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_059',
      name: '사이버 사무라이',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_059.png',
      description: '홀로그램 검과 데이터 스트림이 흐르는 매트릭스의 사무라이',
      maxSupply: 50,
    ),
    GachaCard(
      id: 'card_060',
      name: '데몬 헌터',
      rarity: CardRarity.ultraRare,
      imagePath: 'assets/cards/card_060.png',
      description: '악마 날개와 저주받은 사슬, 성스러운 빛의 폭발을 가진 사냥꾼',
      maxSupply: 50,
    ),

    // ============ SECRET (시크릿) 10장 ============
    GachaCard(
      id: 'card_061',
      name: '뇌신',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_061.png',
      description: '번개 갑옷과 폭풍 구름, 천둥 망치를 가진 신의 힘',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_062',
      name: '우주 수호자',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_062.png',
      description: '은하 갑옷과 별의 검, 우주 배경을 가진 수호신',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_063',
      name: '시간의 군주',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_063.png',
      description: '시계 톱니와 시공간 왜곡, 시간 마법을 다루는 지배자',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_064',
      name: '그림자 황제',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_064.png',
      description: '어둠의 왕좌와 그림자 군단, 악몽의 영역을 지배하는 황제',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_065',
      name: '빛의 천사',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_065.png',
      description: '여섯 날개와 성스러운 후광, 신성한 무기를 든 천국의 천사',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_066',
      name: '네크로맨서 킹',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_066.png',
      description: '언데드 군단과 죽음의 낫, 해골 왕좌의 네크로맨서 왕',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_067',
      name: '무한의 마법사',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_067.png',
      description: '끝없는 주문과 현실 조작, 전능한 오라를 가진 마법사',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_068',
      name: '크리스탈 드래곤',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_068.png',
      description: '다이아몬드 비늘과 프리즘 브레스를 가진 인간-드래곤 하이브리드',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_069',
      name: '양자 암살자',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_069.png',
      description: '위상 이동과 여러 잔상, 역설의 검을 가진 양자 암살자',
      maxSupply: 10,
    ),
    GachaCard(
      id: 'card_070',
      name: '더 컨트롤러',
      rarity: CardRarity.secret,
      imagePath: 'assets/cards/card_070.png',
      description: '꼭두각시 줄로 현실을 조종하는 궁극의 지배자',
      maxSupply: 10,
    ),
  ];

  // 등급별로 카드 가져오기
  static List<GachaCard> getCardsByRarity(String rarityString) {
    CardRarity rarity;
    switch (rarityString.toLowerCase()) {
      case 'normal':
        rarity = CardRarity.normal;
        break;
      case 'rare':
        rarity = CardRarity.rare;
        break;
      case 'superrare':
      case 'super rare':
        rarity = CardRarity.superRare;
        break;
      case 'ultrarare':
      case 'ultra rare':
        rarity = CardRarity.ultraRare;
        break;
      case 'secret':
        rarity = CardRarity.secret;
        break;
      default:
        return [];
    }
    return allCards.where((card) => card.rarity == rarity).toList();
  }

  // ID로 카드 찾기
  static GachaCard? getCardById(String id) {
    try {
      return allCards.firstWhere((card) => card.id == id);
    } catch (e) {
      return null;
    }
  }

  // 총 카드 수
  static int get totalCardCount => allCards.length;

  // 등급별 카드 수
  static int getCardCountByRarity(CardRarity rarity) {
    return allCards.where((card) => card.rarity == rarity).length;
  }
}

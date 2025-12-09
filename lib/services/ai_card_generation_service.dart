import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import 'package:flutter/foundation.dart';

/// 카드 생성 모드
enum GenerationMode {
  evolution,      // 진화 시스템 (20마리 캐릭터, 각 5단계 진화)
  thematic,       // 테마별 랜덤 생성 (70장 독립)
  hybrid,         // 혼합 (10마리 진화 + 20장 독립)
}

/// 카드 스타일
enum CardStyle {
  cute,           // 귀여운 스타일
  realistic,      // 사실적 스타일
  cyberpunk,      // 사이버펑크 (현재 스타일)
  fantasy,        // 판타지
  pixelArt,       // 픽셀 아트
  cartoon,        // 만화/카툰
}

/// AI 카드 생성 서비스
/// 
/// 진화 시스템, 테마별 생성, 고급 커스터마이징 지원
class AICardGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 카드 테마 프리셋
  static const Map<String, Map<String, dynamic>> themePresets = {
    'pokemon_style': {
      'name': '진화하는 몬스터 (포켓몬 스타일)',
      'description': '귀여운 몬스터가 5단계로 진화하는 시스템',
      'baseCreatures': 20,
      'examples': ['퉁퉁퉁사우르스', '찌리릭', '꼬부기', '파이리'],
    },
    'weird_creatures': {
      'name': '해괴한 생명체',
      'description': '기괴하고 독특한 크리처들',
      'examples': ['우주 해파리', '네온 슬라임', '글리치 벌레'],
    },
    'cute_animals': {
      'name': '귀여운 동물들',
      'description': '사랑스러운 동물 친구들',
      'examples': ['아기 판다', '꼬마 고양이', '폭신 강아지'],
    },
    'cute_dinosaurs': {
      'name': '귀여운 공룡들',
      'description': '공룡의 귀여운 버전',
      'examples': ['귀요미 티라노', '아기 트리케라', '꼬마 브라키오'],
    },
    'cyberpunk_city': {
      'name': '사이버펑크 도시',
      'description': '미래 도시의 물건과 장소 (현재 스타일)',
      'examples': ['네온 라멘', '홀로 빌딩', '사이버 고양이'],
    },
    'custom': {
      'name': '커스텀 테마',
      'description': '직접 입력하는 자유 테마',
    },
  };

  /// 진화 시스템 희귀도 매핑
  static const Map<int, CardRarity> evolutionRarityMap = {
    1: CardRarity.normal,      // 1단계 - Normal (20장)
    2: CardRarity.normal,      // 2단계 - Normal (20장) 
    3: CardRarity.rare,        // 3단계 - Rare (20장)
    4: CardRarity.superRare,   // 4단계 - Super Rare (9장)
    5: CardRarity.ultraRare,   // 5단계 - Ultra Rare (1장)
  };

  /// 진화 체인 생성 (20마리 × 5단계 = 100장 중 70장 선택)
  /// 
  /// 분배 전략:
  /// - 1-2단계 (Normal): 20마리 모두 = 40장 중 20장 선택
  /// - 3단계 (Rare): 20마리 모두 = 20장
  /// - 4단계 (Super Rare): 20마리 중 9마리만 선택 = 9장
  /// - 5단계 (Ultra Rare): 20마리 중 1마리만 선택 = 1장
  List<Map<String, dynamic>> generateEvolutionChain({
    required String baseTheme,
    required CardStyle style,
    List<String>? customCreatureNames,
  }) {
    final List<Map<String, dynamic>> cards = [];
    
    // 20마리 기본 크리처 이름 생성
    final List<String> baseCreatures = customCreatureNames ?? _generateBaseCreatureNames(baseTheme, 20);
    
    // 각 크리처별 진화 체인 생성
    for (int creatureIndex = 0; creatureIndex < 20; creatureIndex++) {
      final baseName = baseCreatures[creatureIndex];
      
      // 5단계 진화 생성
      for (int stage = 1; stage <= 5; stage++) {
        final rarity = evolutionRarityMap[stage]!;
        final evolvedName = _generateEvolvedName(baseName, stage);
        final description = _generateEvolutionDescription(baseName, stage);
        
        cards.add({
          'creatureIndex': creatureIndex,
          'evolutionStage': stage,
          'name': evolvedName,
          'rarity': rarity,
          'description': description,
          'baseCreature': baseName,
          'style': style,
          'theme': baseTheme,
        });
      }
    }
    
    // 70장으로 필터링
    return _selectCardsForDistribution(cards);
  }

  /// 70장 선택 로직 (진화 시스템)
  List<Map<String, dynamic>> _selectCardsForDistribution(List<Map<String, dynamic>> allCards) {
    final selected = <Map<String, dynamic>>[];
    
    // 1-2단계 (Normal): 40장 중 20장 랜덤 선택
    final stage1and2 = allCards.where((c) => c['evolutionStage'] <= 2).toList();
    stage1and2.shuffle();
    selected.addAll(stage1and2.take(20));
    
    // 3단계 (Rare): 20마리 모두 선택
    selected.addAll(allCards.where((c) => c['evolutionStage'] == 3));
    
    // 4단계 (Super Rare): 20마리 중 9마리 선택
    final stage4 = allCards.where((c) => c['evolutionStage'] == 4).toList();
    stage4.shuffle();
    selected.addAll(stage4.take(9));
    
    // 5단계 (Ultra Rare): 20마리 중 1마리 선택 (가장 인기 있는 것)
    final stage5 = allCards.where((c) => c['evolutionStage'] == 5).toList();
    stage5.shuffle();
    selected.add(stage5.first);
    
    return selected;
  }

  /// 기본 크리처 이름 생성 (20마리)
  List<String> _generateBaseCreatureNames(String theme, int count) {
    // AI API 호출 또는 사전 정의된 이름 사용
    final Map<String, List<String>> themeNames = {
      'pokemon_style': [
        '퉁퉁퉁사우르스', '찌리릭', '꼬부기', '파이리', '피카츄',
        '잠만보', '이상해씨', '고라파덕', '망나뇽', '뮤츠',
        '루카리오', '가디안', '니드킹', '피죤투', '라이츄',
        '꼬렛', '모래두지', '냐옹', '야도란', '질퍽이',
      ],
      'weird_creatures': [
        '글리치 슬라임', '네온 해파리', '우주 벌레', '홀로 버섯', '데이터 유령',
        '픽셀 바이러스', '증강 달팽이', '양자 문어', '전자 불가사리', '메모리 거미',
        '코드 나비', '바이트 두더지', '렌더 도마뱀', '캐시 뱀', '로그 개구리',
        '스팸 쥐', '버그 파리', '크래시 딱정벌레', '렉 애벌레', '패치 귀뚜라미',
      ],
      'cute_animals': [
        '아기 판다', '꼬마 고양이', '폭신 강아지', '귀요미 토끼', '사랑 햄스터',
        '깜찍 다람쥐', '애교 여우', '순둥 코알라', '졸린 나무늘보', '통통 펭귄',
        '말랑 바다표범', '둥글 수달', '포근 알파카', '몽실 양', '보들 병아리',
        '귀염 오리', '파스텔 돌고래', '사탕 유니콘', '구름 고래', '별 사슴',
      ],
      'cute_dinosaurs': [
        '귀요미 티라노', '아기 트리케라', '꼬마 브라키오', '졸린 스테고', '폭신 벨로시',
        '통통 안킬로', '말랑 프테라', '둥글 파라사', '몽실 디플로', '보들 스피노',
        '귀염 알로', '파스텔 이구아노', '사탕 케라토', '구름 테리지노', '별 카르노',
        '무지개 모사', '풍선 파키케', '젤리 오비랍토르', '솜사탕 미크로', '마시멜로 갈리',
      ],
    };
    
    return themeNames[theme] ?? List.generate(count, (i) => '크리처 ${i + 1}');
  }

  /// 진화된 이름 생성
  String _generateEvolvedName(String baseName, int stage) {
    switch (stage) {
      case 1:
        return '꼬마 $baseName';
      case 2:
        return baseName;
      case 3:
        return '강화 $baseName';
      case 4:
        return '궁극 $baseName';
      case 5:
        return '신성 $baseName';
      default:
        return baseName;
    }
  }

  /// 진화 설명 생성
  String _generateEvolutionDescription(String baseName, int stage) {
    switch (stage) {
      case 1:
        return '$baseName의 초기 형태, 아직 어리지만 잠재력이 보인다';
      case 2:
        return '$baseName의 기본 형태, 균형잡힌 능력을 보유';
      case 3:
        return '$baseName가 강화되었다! 훨씬 강력해진 모습';
      case 4:
        return '$baseName의 궁극 진화! 압도적인 힘을 자랑';
      case 5:
        return '$baseName의 최종 형태! 전설로 불리는 존재';
      default:
        return '$baseName의 진화 형태';
    }
  }

  /// 테마별 카드 생성 (70장 독립)
  Future<List<Map<String, dynamic>>> generateThematicCards({
    required String theme,
    required CardStyle style,
    String? customThemeDescription,
  }) async {
    final cards = <Map<String, dynamic>>[];
    
    // 희귀도별 분배: Normal 20, Rare 20, SR 20, UR 9, Secret 1
    final rarityDistribution = [
      {'rarity': CardRarity.normal, 'count': 20},
      {'rarity': CardRarity.rare, 'count': 20},
      {'rarity': CardRarity.superRare, 'count': 20},
      {'rarity': CardRarity.ultraRare, 'count': 9},
      {'rarity': CardRarity.secret, 'count': 1},
    ];
    
    int cardIndex = 1;
    for (var dist in rarityDistribution) {
      final rarity = dist['rarity'] as CardRarity;
      final count = dist['count'] as int;
      
      for (int i = 0; i < count; i++) {
        cards.add({
          'index': cardIndex++,
          'name': '${theme} #$cardIndex',
          'rarity': rarity,
          'description': '$theme 테마의 ${_getRarityKorean(rarity)} 카드',
          'style': style,
          'theme': theme,
        });
      }
    }
    
    return cards;
  }

  /// 희귀도 한글 변환
  String _getRarityKorean(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.normal:
        return '일반';
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

  /// AI 이미지 생성 프롬프트 생성
  String generateImagePrompt(Map<String, dynamic> cardData) {
    final style = cardData['style'] as CardStyle;
    final name = cardData['name'] as String;
    final description = cardData['description'] as String;
    final rarity = cardData['rarity'] as CardRarity;
    
    // 스타일별 프롬프트 접두사
    final stylePrefix = _getStylePrefix(style);
    
    // 희귀도별 품질 접미사
    final rarityQuality = _getRarityQualityModifier(rarity);
    
    return '$stylePrefix, $name, $description, $rarityQuality, high quality, detailed, digital art, trading card style, centered composition, clean background';
  }

  /// 스타일별 프롬프트 접두사
  String _getStylePrefix(CardStyle style) {
    switch (style) {
      case CardStyle.cute:
        return 'cute kawaii style, adorable, chibi, pastel colors, soft lighting';
      case CardStyle.realistic:
        return 'photorealistic, detailed, professional, dramatic lighting';
      case CardStyle.cyberpunk:
        return 'cyberpunk style, neon lights, futuristic, holographic, sci-fi';
      case CardStyle.fantasy:
        return 'fantasy art style, magical, ethereal, mystical';
      case CardStyle.pixelArt:
        return 'pixel art style, retro gaming, 16-bit, colorful';
      case CardStyle.cartoon:
        return 'cartoon style, vibrant colors, exaggerated features, playful';
    }
  }

  /// 희귀도별 품질 수정자
  String _getRarityQualityModifier(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.normal:
        return 'simple design, clean';
      case CardRarity.rare:
        return 'enhanced details, glowing effects';
      case CardRarity.superRare:
        return 'intricate details, epic lighting, sparkles';
      case CardRarity.ultraRare:
        return 'legendary quality, divine glow, particle effects, masterpiece';
      case CardRarity.secret:
        return 'ultimate masterpiece, godlike aura, rainbow holographic, breathtaking';
    }
  }

  /// Firestore에 시즌 카드 저장
  Future<void> saveSeasonCards({
    required String seasonId,
    required List<GachaCard> cards,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (var card in cards) {
        final docRef = _firestore
            .collection('seasons')
            .doc(seasonId)
            .collection('cards')
            .doc(card.id);
        
        batch.set(docRef, {
          'id': card.id,
          'name': card.name,
          'rarity': card.rarity.toString(),
          'imagePath': card.imagePath,
          'description': card.description,
          'maxSupply': card.maxSupply,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      if (kDebugMode) {
        debugPrint('✅ ${cards.length}장 카드가 시즌 $seasonId에 저장되었습니다.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 카드 저장 실패: $e');
      }
      rethrow;
    }
  }
}



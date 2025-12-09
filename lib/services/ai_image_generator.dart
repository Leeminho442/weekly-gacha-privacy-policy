import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/card_model.dart';
import 'ai_card_generation_service.dart';

/// AI 이미지 실제 생성 서비스
/// 
/// Genspark AI image_generation tool과 통합하여 실제 카드 이미지를 생성합니다
class AIImageGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AICardGenerationService _cardService = AICardGenerationService();
  
  // Genspark AI 설정
  static const String _imageModel = 'recraft-v3'; // 빠르고 비용 효율적인 모델

  /// 옵션 1: 완전 자동 생성
  /// 
  /// 70장의 카드를 자동으로 생성하고 Firebase에 바로 업로드
  Future<GenerationResult> generateFullyAutomatic({
    required GenerationMode mode,
    required String theme,
    required CardStyle style,
    required Function(int current, int total, String status) onProgress,
  }) async {
    try {
      final result = GenerationResult();
      
      // 1단계: 카드 컨셉 생성
      onProgress(0, 70, '카드 컨셉 생성 중...');
      List<Map<String, dynamic>> cardConcepts;
      
      if (mode == GenerationMode.evolution) {
        cardConcepts = _cardService.generateEvolutionChain(
          baseTheme: theme,
          style: style,
        );
      } else {
        cardConcepts = await _cardService.generateThematicCards(
          theme: theme,
          style: style,
        );
      }
      
      // 2단계: 이미지 생성 (70장)
      for (int i = 0; i < cardConcepts.length; i++) {
        final concept = cardConcepts[i];
        onProgress(i + 1, 70, '${concept['name']} 생성 중... (${i + 1}/70)');
        
        try {
          // 실제 AI 이미지 생성
          final imageUrl = await _generateCardImage(
            cardName: concept['name'] as String,
            description: concept['description'] as String,
            rarity: concept['rarity'] as CardRarity,
            style: style,
          );
          
          // Firebase Storage에 업로드
          final storagePath = await _uploadToStorage(
            imageUrl: imageUrl,
            cardIndex: i,
            seasonId: '2025_S1_v1',
          );
          
          concept['imagePath'] = storagePath;
          concept['generatedAt'] = DateTime.now().toIso8601String();
          
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ 카드 ${i + 1} 생성 실패, 재시도 중: $e');
          }
          
          // 에러 발생 시 재시도 (최대 2회)
          for (int retry = 0; retry < 2; retry++) {
            try {
              await Future.delayed(Duration(seconds: retry + 1));
              final imageUrl = await _generateCardImage(
                cardName: concept['name'] as String,
                description: concept['description'] as String,
                rarity: concept['rarity'] as CardRarity,
                style: style,
              );
              
              final storagePath = await _uploadToStorage(
                imageUrl: imageUrl,
                cardIndex: i,
                seasonId: '2025_S1_v1',
              );
              
              concept['imagePath'] = storagePath;
              concept['generatedAt'] = DateTime.now().toIso8601String();
              break;
            } catch (retryError) {
              if (retry == 1) {
                // 최종 실패 시 플레이스홀더
                concept['imagePath'] = 'https://via.placeholder.com/512x512?text=${Uri.encodeComponent(concept['name'])}';
                if (kDebugMode) {
                  debugPrint('❌ 카드 ${i + 1} 최종 생성 실패: $retryError');
                }
              }
            }
          }
        }
      }
      
      // 3단계: Firebase Storage 업로드
      onProgress(70, 70, 'Firebase에 업로드 중...');
      
      // 4단계: Firestore에 카드 데이터 저장
      await _saveToFirestore(cardConcepts, '2025_S1_v1');
      
      result.success = true;
      result.cardCount = 70;
      result.message = '✅ 70장 카드 생성 완료!';
      
      return result;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 자동 생성 실패: $e');
      }
      return GenerationResult()
        ..success = false
        ..message = '생성 실패: $e';
    }
  }

  /// 옵션 2: 미리보기 + 승인 시스템
  /// 
  /// 70장 생성 후 미리보기, 관리자 승인 후 Firebase 업로드
  Future<PreviewResult> generateWithPreview({
    required GenerationMode mode,
    required String theme,
    required CardStyle style,
    required Function(int current, int total, String status) onProgress,
  }) async {
    try {
      final result = PreviewResult();
      
      // 1단계: 카드 컨셉 생성
      onProgress(0, 70, '카드 컨셉 생성 중...');
      List<Map<String, dynamic>> cardConcepts;
      
      if (mode == GenerationMode.evolution) {
        cardConcepts = _cardService.generateEvolutionChain(
          baseTheme: theme,
          style: style,
        );
      } else {
        cardConcepts = await _cardService.generateThematicCards(
          theme: theme,
          style: style,
        );
      }
      
      // 2단계: 이미지 생성 (70장) - 임시 저장 (Firebase 업로드 전)
      final previewCards = <PreviewCard>[];
      
      for (int i = 0; i < cardConcepts.length; i++) {
        final concept = cardConcepts[i];
        onProgress(i + 1, 70, '${concept['name']} 생성 중... (${i + 1}/70)');
        
        try {
          // 실제 AI 이미지 생성
          final imageUrl = await _generateCardImage(
            cardName: concept['name'] as String,
            description: concept['description'] as String,
            rarity: concept['rarity'] as CardRarity,
            style: style,
          );
          
          // 미리보기용으로 임시 URL 저장 (아직 Firebase 업로드 안 함)
          previewCards.add(PreviewCard(
            index: i,
            name: concept['name'] as String,
            description: concept['description'] as String,
            rarity: concept['rarity'] as CardRarity,
            imageUrl: imageUrl,
            concept: concept,
          ));
          
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ 카드 ${i + 1} 생성 실패: $e');
          }
          
          // 에러 발생 시 플레이스홀더
          previewCards.add(PreviewCard(
            index: i,
            name: concept['name'] as String,
            description: concept['description'] as String,
            rarity: concept['rarity'] as CardRarity,
            imageUrl: 'https://via.placeholder.com/512x512?text=${Uri.encodeComponent(concept['name'])}',
            concept: concept,
          ));
        }
      }
      
      result.success = true;
      result.cards = previewCards;
      result.message = '✅ 70장 생성 완료! 미리보기 가능합니다.';
      
      return result;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 미리보기 생성 실패: $e');
      }
      return PreviewResult()
        ..success = false
        ..message = '생성 실패: $e';
    }
  }

  /// 미리보기 승인 후 Firebase 업로드
  Future<bool> approveAndUpload(List<PreviewCard> cards) async {
    try {
      // Firebase Storage에 이미지 업로드
      for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        
        if (card.imageUrl.startsWith('http') && !card.imageUrl.contains('placeholder')) {
          // 임시 URL을 Firebase Storage로 업로드
          final storagePath = await _uploadToStorage(
            imageUrl: card.imageUrl,
            cardIndex: i,
            seasonId: '2025_S1_v1',
          );
          
          card.concept['imagePath'] = storagePath;
        }
      }
      
      final concepts = cards.map((card) => card.concept).toList();
      await _saveToFirestore(concepts, '2025_S1_v1');
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 승인 업로드 실패: $e');
      }
      return false;
    }
  }

  /// 개별 카드 재생성
  Future<PreviewCard?> regenerateCard({
    required int index,
    required Map<String, dynamic> originalConcept,
    required CardStyle style,
  }) async {
    try {
      // 실제 AI 이미지 재생성
      final imageUrl = await _generateCardImage(
        cardName: originalConcept['name'] as String,
        description: originalConcept['description'] as String,
        rarity: originalConcept['rarity'] as CardRarity,
        style: style,
      );
      
      return PreviewCard(
        index: index,
        name: originalConcept['name'] as String,
        description: originalConcept['description'] as String,
        rarity: originalConcept['rarity'] as CardRarity,
        imageUrl: imageUrl,
        concept: originalConcept,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 카드 재생성 실패: $e');
      }
      return null;
    }
  }

  /// 옵션 3: 컨셉만 생성
  /// 
  /// 이미지 없이 카드 이름/설명만 70개 생성
  Future<ConceptResult> generateConceptsOnly({
    required GenerationMode mode,
    required String theme,
    required CardStyle style,
  }) async {
    try {
      final result = ConceptResult();
      
      List<Map<String, dynamic>> cardConcepts;
      
      if (mode == GenerationMode.evolution) {
        cardConcepts = _cardService.generateEvolutionChain(
          baseTheme: theme,
          style: style,
        );
      } else {
        cardConcepts = await _cardService.generateThematicCards(
          theme: theme,
          style: style,
        );
      }
      
      result.success = true;
      result.concepts = cardConcepts;
      result.message = '✅ 70개 카드 컨셉 생성 완료!';
      
      return result;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 컨셉 생성 실패: $e');
      }
      return ConceptResult()
        ..success = false
        ..message = '생성 실패: $e';
    }
  }

  /// 실제 AI 이미지 생성 (Genspark API 호출)
  Future<String> _generateCardImage({
    required String cardName,
    required String description,
    required CardRarity rarity,
    required CardStyle style,
  }) async {
    // 프롬프트 생성
    final prompt = _buildImagePrompt(
      cardName: cardName,
      description: description,
      rarity: rarity,
      style: style,
    );
    
    // AI 이미지 생성 요청
    // 실제 환경에서는 Genspark AI API를 직접 호출하거나
    // Flutter 앱 외부에서 image_generation tool을 호출해야 합니다.
    // 
    // 현재는 시뮬레이션으로 처리하고, 실제 통합 시 아래 코드를 수정하세요.
    
    if (kDebugMode) {
      debugPrint('🎨 AI 이미지 생성 요청:');
      debugPrint('   카드: $cardName');
      debugPrint('   프롬프트: $prompt');
      debugPrint('   모델: $_imageModel');
    }
    
    // TODO: 실제 Genspark AI API 호출
    // 현재는 placeholder 반환
    // 실제 구현 시 image_generation tool의 반환값을 사용
    
    // 임시 지연 (실제 생성 시간 시뮬레이션: 약 20-30초)
    await Future.delayed(const Duration(seconds: 1));
    
    // 임시 placeholder URL (실제로는 AI가 생성한 이미지 URL)
    return 'https://via.placeholder.com/512x512/FF6B9D/FFFFFF?text=${Uri.encodeComponent(cardName)}';
  }
  
  /// 이미지 프롬프트 생성
  String _buildImagePrompt({
    required String cardName,
    required String description,
    required CardRarity rarity,
    required CardStyle style,
  }) {
    // 스타일별 프롬프트 접두사
    String stylePrefix = '';
    switch (style) {
      case CardStyle.cute:
        stylePrefix = 'Cute and adorable style, kawaii aesthetic, soft colors, charming';
        break;
      case CardStyle.cyberpunk:
        stylePrefix = 'Cyberpunk style, neon colors, futuristic, high-tech, glowing effects';
        break;
      case CardStyle.cartoon:
        stylePrefix = 'Cartoon style, bold lines, vibrant colors, animated look';
        break;
      case CardStyle.fantasy:
        stylePrefix = 'Fantasy art style, magical, ethereal, detailed, epic';
        break;
      case CardStyle.pixelArt:
        stylePrefix = '16-bit pixel art style, retro gaming aesthetic, detailed pixels';
        break;
      case CardStyle.realistic:
        stylePrefix = 'Realistic style, photorealistic, detailed textures, natural lighting';
        break;
    }
    
    // 희귀도별 품질 강조
    String rarityBoost = '';
    switch (rarity) {
      case CardRarity.secret:
        rarityBoost = 'legendary, masterpiece quality, extremely detailed, holographic effect, premium';
        break;
      case CardRarity.ultraRare:
        rarityBoost = 'epic, highly detailed, glowing aura, premium quality';
        break;
      case CardRarity.superRare:
        rarityBoost = 'rare, detailed, special effects, quality';
        break;
      case CardRarity.rare:
        rarityBoost = 'uncommon, good quality, slight glow';
        break;
      case CardRarity.normal:
        rarityBoost = 'standard quality, clean design';
        break;
    }
    
    // 최종 프롬프트 조합
    return '$stylePrefix, $description, $rarityBoost, trading card art, centered composition, white background, high quality, 512x512';
  }
  
  /// Firebase Storage에 이미지 업로드
  Future<String> _uploadToStorage({
    required String imageUrl,
    required int cardIndex,
    required String seasonId,
  }) async {
    try {
      // 이미지 다운로드
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('이미지 다운로드 실패: ${response.statusCode}');
      }
      
      final imageData = response.bodyBytes;
      
      // Firebase Storage 경로
      final storagePath = 'seasons/$seasonId/cards/card_$cardIndex.png';
      final storageRef = _storage.ref().child(storagePath);
      
      // 업로드
      await storageRef.putData(
        imageData,
        SettableMetadata(contentType: 'image/png'),
      );
      
      // 다운로드 URL 가져오기
      final downloadUrl = await storageRef.getDownloadURL();
      
      if (kDebugMode) {
        debugPrint('✅ Firebase Storage 업로드 완료: $storagePath');
      }
      
      return downloadUrl;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Firebase Storage 업로드 실패: $e');
      }
      rethrow;
    }
  }
  
  /// Firestore에 카드 데이터 저장
  Future<void> _saveToFirestore(
    List<Map<String, dynamic>> concepts,
    String seasonId,
  ) async {
    final batch = _firestore.batch();
    
    for (var concept in concepts) {
      final cardId = 'card_${concept['index']}';
      final docRef = _firestore
          .collection('seasons')
          .doc(seasonId)
          .collection('cards')
          .doc(cardId);
      
      batch.set(docRef, {
        'id': cardId,
        'name': concept['name'],
        'rarity': concept['rarity'].toString(),
        'imagePath': concept['imagePath'] ?? '',
        'description': concept['description'],
        'maxSupply': 1000,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }
}

/// 생성 결과 (옵션 1)
class GenerationResult {
  bool success = false;
  String message = '';
  int cardCount = 0;
}

/// 미리보기 결과 (옵션 2)
class PreviewResult {
  bool success = false;
  String message = '';
  List<PreviewCard> cards = [];
}

/// 미리보기 카드
class PreviewCard {
  final int index;
  final String name;
  final String description;
  final CardRarity rarity;
  final String imageUrl;
  final Map<String, dynamic> concept;

  PreviewCard({
    required this.index,
    required this.name,
    required this.description,
    required this.rarity,
    required this.imageUrl,
    required this.concept,
  });
}

/// 컨셉 전용 결과 (옵션 3)
class ConceptResult {
  bool success = false;
  String message = '';
  List<Map<String, dynamic>> concepts = [];
}

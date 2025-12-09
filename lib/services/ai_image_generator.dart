import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import 'ai_card_generation_service.dart';

/// AI 이미지 실제 생성 서비스
/// 
/// image_generation tool과 통합하여 실제 카드 이미지를 생성합니다
class AIImageGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AICardGenerationService _cardService = AICardGenerationService();

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
        onProgress(i + 1, 70, '${concept['name']} 생성 중...');
        
        // TODO: 실제 image_generation tool 호출
        // 현재는 시뮬레이션
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 이미지 URL 시뮬레이션 (실제로는 image_generation tool에서 반환)
        final imageUrl = 'https://placeholder.com/card_${i + 1}.png';
        
        concept['imagePath'] = imageUrl;
        concept['generatedAt'] = DateTime.now().toIso8601String();
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
      
      // 2단계: 이미지 생성 (70장) - 임시 저장
      final previewCards = <PreviewCard>[];
      
      for (int i = 0; i < cardConcepts.length; i++) {
        final concept = cardConcepts[i];
        onProgress(i + 1, 70, '${concept['name']} 생성 중...');
        
        // TODO: 실제 image_generation tool 호출
        await Future.delayed(const Duration(milliseconds: 100));
        
        final imageUrl = 'https://placeholder.com/card_${i + 1}.png';
        
        previewCards.add(PreviewCard(
          index: i,
          name: concept['name'] as String,
          description: concept['description'] as String,
          rarity: concept['rarity'] as CardRarity,
          imageUrl: imageUrl,
          concept: concept,
        ));
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
      // TODO: image_generation tool로 재생성
      await Future.delayed(const Duration(seconds: 2));
      
      final imageUrl = 'https://placeholder.com/card_${index}_regenerated.png';
      
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

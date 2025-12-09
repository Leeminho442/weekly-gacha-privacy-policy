import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import '../models/card_data.dart';

/// 갓챠 서비스 - Firebase Firestore 기반 카드 발행량 및 시리얼 넘버 관리
class GachaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? get currentUserId => _auth.currentUser?.uid;
  
  /// 카드 재고 초기화 (앱 첫 실행 시 또는 관리자용)
  Future<void> initializeStock() async {
    try {
      // Firestore에서 card_stocks 컬렉션 확인
      final stocksSnapshot = await _firestore.collection('card_stocks').get();
      
      // 재고 개수가 70개가 아니면 재초기화
      if (stocksSnapshot.docs.isEmpty || stocksSnapshot.docs.length != 70) {
        print('[GachaService] 재고 초기화 시작 (현재 재고: ${stocksSnapshot.docs.length}개)');
        
        // 기존 재고 삭제
        final batch = _firestore.batch();
        for (final doc in stocksSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        // 새로운 70개 카드 재고 설정
        final newBatch = _firestore.batch();
        
        for (final card in CardData.allCards) {
          final stockRef = _firestore.collection('card_stocks').doc(card.id);
          newBatch.set(stockRef, {
            'cardId': card.id,
            'currentSupply': 0,
            'maxSupply': card.maxSupply,
            'season': CardData.currentSeason,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        await newBatch.commit();
        print('[GachaService] 재고 초기화 완료 (70개 카드)');
      }
    } catch (e) {
      print('재고 초기화 오류: $e');
      // 초기화 실패 시 로컬 처리 (오프라인 대비)
    }
  }

  /// 카드 재고 강제 초기화 (기존 데이터 삭제 후 재생성)
  Future<void> forceInitializeStock() async {
    try {
      print('[GachaService] 카드 재고 강제 초기화 시작...');
      
      // 1. 기존 재고 데이터 모두 삭제
      final existingStocks = await _firestore.collection('card_stocks').get();
      if (existingStocks.docs.isNotEmpty) {
        final deleteBatch = _firestore.batch();
        for (var doc in existingStocks.docs) {
          deleteBatch.delete(doc.reference);
        }
        await deleteBatch.commit();
        print('[GachaService] 기존 재고 ${existingStocks.docs.length}개 삭제 완료');
      }
      
      // 2. 70장 카드 재고 새로 생성
      final allCards = CardData.allCards;
      if (allCards.isEmpty) {
        print('[GachaService] 경고: CardData.allCards가 비어있습니다');
        return;
      }
      
      final newBatch = _firestore.batch();
      for (var card in allCards) {
        final stockRef = _firestore.collection('card_stocks').doc(card.id);
        newBatch.set(stockRef, {
          'cardId': card.id,
          'currentSupply': 0,
          'maxSupply': card.maxSupply,
          'season': CardData.currentSeason,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await newBatch.commit();
      print('[GachaService] ✅ 카드 재고 강제 초기화 완료: ${allCards.length}개 카드');
    } catch (e) {
      print('[GachaService] ❌ 카드 재고 강제 초기화 실패: $e');
      rethrow;
    }
  }

  /// 특정 카드의 현재 재고 정보 가져오기
  Future<CardStock> getCardStock(String cardId) async {
    try {
      final stockDoc = await _firestore.collection('card_stocks').doc(cardId).get();
      
      if (!stockDoc.exists) {
        // 재고 정보가 없으면 기본값 반환
        final card = CardData.getCardById(cardId);
        if (card == null) {
          throw Exception('카드를 찾을 수 없습니다: $cardId');
        }
        
        return CardStock(
          cardId: cardId,
          currentSupply: 0,
          maxSupply: card.maxSupply,
          season: CardData.currentSeason,
        );
      }
      
      final data = stockDoc.data()!;
      return CardStock(
        cardId: data['cardId'] ?? cardId,
        currentSupply: data['currentSupply'] ?? 0,
        maxSupply: data['maxSupply'] ?? 0,
        season: data['season'] ?? CardData.currentSeason,
      );
    } catch (e) {
      print('재고 조회 오류: $e');
      // 오류 시 기본값 반환
      final card = CardData.getCardById(cardId);
      return CardStock(
        cardId: cardId,
        currentSupply: 0,
        maxSupply: card?.maxSupply ?? 0,
        season: CardData.currentSeason,
      );
    }
  }

  /// 모든 카드의 재고 정보 가져오기
  Future<Map<String, CardStock>> getAllStocks() async {
    final stocks = <String, CardStock>{};
    
    try {
      final stocksSnapshot = await _firestore.collection('card_stocks').get();
      
      for (final doc in stocksSnapshot.docs) {
        final data = doc.data();
        stocks[doc.id] = CardStock(
          cardId: data['cardId'] ?? doc.id,
          currentSupply: data['currentSupply'] ?? 0,
          maxSupply: data['maxSupply'] ?? 0,
          season: data['season'] ?? CardData.currentSeason,
        );
      }
    } catch (e) {
      print('전체 재고 조회 오류: $e');
    }
    
    // 누락된 카드 추가
    for (final card in CardData.allCards) {
      if (!stocks.containsKey(card.id)) {
        stocks[card.id] = CardStock(
          cardId: card.id,
          currentSupply: 0,
          maxSupply: card.maxSupply,
          season: CardData.currentSeason,
        );
      }
    }
    
    return stocks;
  }

  /// 카드 뽑기 (재고 확인 및 시리얼 넘버 발급) - Firebase Transaction 사용
  Future<OwnedCard?> pullCard(String userId) async {
    try {
      // 1. 확률에 따라 등급 결정
      final rarity = _determineRarity();
      
      // 2. 해당 등급의 카드 중 재고가 있는 카드 필터링
      final availableCards = await _getAvailableCardsByRarity(rarity);
      
      if (availableCards.isEmpty) {
        // 재고가 없으면 null 반환
        return null;
      }
      
      // 3. 랜덤으로 카드 선택
      final random = Random();
      final selectedCard = availableCards[random.nextInt(availableCards.length)];
      
      // 4. Firestore Transaction으로 원자적 재고 업데이트
      final ownedCard = await _firestore.runTransaction<OwnedCard?>((transaction) async {
        final stockRef = _firestore.collection('card_stocks').doc(selectedCard.id);
        final stockDoc = await transaction.get(stockRef);
        
        if (!stockDoc.exists) {
          throw Exception('재고 정보를 찾을 수 없습니다');
        }
        
        final currentSupply = stockDoc.data()?['currentSupply'] ?? 0;
        final maxSupply = stockDoc.data()?['maxSupply'] ?? 0;
        
        // 재고 확인
        if (currentSupply >= maxSupply) {
          return null; // 품절
        }
        
        // 글로벌 시리얼 넘버 카운터 조회 및 증가
        final counterRef = _firestore.collection('global_counters').doc('card_serial_number');
        final counterDoc = await transaction.get(counterRef);
        
        int serialNumber;
        if (counterDoc.exists) {
          serialNumber = (counterDoc.data()?['value'] ?? 0) + 1;
          transaction.update(counterRef, {
            'value': serialNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 카운터가 없으면 새로 생성 (초기값 1)
          serialNumber = 1;
          transaction.set(counterRef, {
            'value': serialNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        // 재고 업데이트 (currentSupply는 카드별 발행 수량 관리용)
        transaction.update(stockRef, {
          'currentSupply': currentSupply + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // OwnedCard 생성
        final ownedCardRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('owned_cards')
            .doc();
        
        final ownedCard = OwnedCard(
          ownedCardId: ownedCardRef.id,
          cardId: selectedCard.id,
          userId: userId,
          serialNumber: serialNumber,
          season: CardData.currentSeason,
          obtainedAt: DateTime.now(),
          name: selectedCard.name,
          rarity: selectedCard.rarity,
          imagePath: selectedCard.imagePath,
          description: selectedCard.description,
          maxSupply: selectedCard.maxSupply,
        );
        
        // 사용자 소유 카드 저장
        transaction.set(ownedCardRef, {
          'cardId': ownedCard.cardId,
          'userId': userId,
          'serialNumber': serialNumber,
          'season': CardData.currentSeason,
          'obtainedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return ownedCard;
      });
      
      return ownedCard;
    } catch (e) {
      print('카드 뽑기 오류: $e');
      rethrow;
    }
  }

  /// 확률에 따른 등급 결정
  CardRarity _determineRarity() {
    final random = Random();
    final chance = random.nextDouble();
    
    // 누적 확률로 계산
    double cumulative = 0.0;
    
    for (final rarity in CardRarity.values) {
      // 각 등급의 확률을 임시 카드로 가져오기
      final tempCard = CardData.allCards.firstWhere(
        (card) => card.rarity == rarity,
      );
      cumulative += tempCard.pullChance;
      
      if (chance < cumulative) {
        return rarity;
      }
    }
    
    return CardRarity.normal; // 기본값
  }

  /// 특정 등급 중 재고가 있는 카드만 필터링
  Future<List<GachaCard>> _getAvailableCardsByRarity(CardRarity rarity) async {
    // CardRarity enum을 String으로 변환
    final rarityString = rarity.toString().split('.').last;
    final cardsOfRarity = CardData.getCardsByRarity(rarityString);
    final availableCards = <GachaCard>[];
    
    for (final card in cardsOfRarity) {
      final stock = await getCardStock(card.id);
      if (stock.isAvailable) {
        availableCards.add(card);
      }
    }
    
    return availableCards;
  }

  /// 사용자의 모든 소유 카드 가져오기
  Future<List<OwnedCard>> getUserCards(String userId) async {
    try {
      final cardsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('owned_cards')
          .orderBy('obtainedAt', descending: true)
          .get();
      
      final ownedCards = <OwnedCard>[];
      
      for (final doc in cardsSnapshot.docs) {
        final data = doc.data();
        final cardId = data['cardId'] as String;
        final cardInfo = CardData.getCardById(cardId);
        
        if (cardInfo != null) {
          ownedCards.add(OwnedCard(
            ownedCardId: doc.id,
            cardId: cardId,
            userId: userId,
            serialNumber: data['serialNumber'] ?? 0,
            season: data['season'] ?? CardData.currentSeason,
            obtainedAt: (data['obtainedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            name: cardInfo.name,
            rarity: cardInfo.rarity,
            imagePath: cardInfo.imagePath,
            description: cardInfo.description,
            maxSupply: cardInfo.maxSupply,
          ));
        }
      }
      
      return ownedCards;
    } catch (e) {
      print('소유 카드 조회 오류: $e');
      return [];
    }
  }

  /// 관리자용: 모든 사용자의 카드 조회
  Future<List<OwnedCard>> getAllUserCards() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final allOwnedCards = <OwnedCard>[];
      
      for (final userDoc in usersSnapshot.docs) {
        final cardsSnapshot = await userDoc.reference
            .collection('owned_cards')
            .get();
        
        for (final cardDoc in cardsSnapshot.docs) {
          final data = cardDoc.data();
          final cardId = data['cardId'] as String;
          final cardInfo = CardData.getCardById(cardId);
          
          if (cardInfo != null) {
            allOwnedCards.add(OwnedCard(
              ownedCardId: cardDoc.id,
              cardId: cardId,
              userId: userDoc.id,
              serialNumber: data['serialNumber'] ?? 0,
              season: data['season'] ?? CardData.currentSeason,
              obtainedAt: (data['obtainedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              name: cardInfo.name,
              rarity: cardInfo.rarity,
              imagePath: cardInfo.imagePath,
              description: cardInfo.description,
              maxSupply: cardInfo.maxSupply,
            ));
          }
        }
      }
      
      return allOwnedCards;
    } catch (e) {
      print('전체 카드 조회 오류: $e');
      return [];
    }
  }

  /// 재고 리셋 (관리자 전용)
  Future<void> resetStock() async {
    try {
      final batch = _firestore.batch();
      final stocksSnapshot = await _firestore.collection('card_stocks').get();
      
      for (final doc in stocksSnapshot.docs) {
        batch.update(doc.reference, {
          'currentSupply': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('재고 리셋 오류: $e');
      rethrow;
    }
  }
}

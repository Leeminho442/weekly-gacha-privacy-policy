import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';
import '../models/card_data.dart';

/// 카드 관리 서비스 - 관리자용
/// 주차별로 카드 70종을 교체하고 관리하는 기능
class CardManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 현재 활성 카드 세트 조회
  Future<CardSet?> getCurrentCardSet() async {
    try {
      final query = await _firestore
          .collection('card_sets')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        return null;
      }
      
      return CardSet.fromFirestore(query.docs.first);
    } catch (e) {
      print('Error getting current card set: $e');
      return null;
    }
  }
  
  /// 모든 카드 세트 목록 조회 (역순 - 최신 먼저)
  Future<List<CardSet>> getAllCardSets() async {
    try {
      final query = await _firestore
          .collection('card_sets')
          .orderBy('createdAt', descending: true)
          .get();
      
      return query.docs
          .map((doc) => CardSet.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all card sets: $e');
      return [];
    }
  }
  
  /// 새로운 카드 세트 생성 (기존 active를 비활성화하고 새 세트 활성화)
  Future<void> createNewCardSet({
    required String name,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      // 1. 기존 활성 카드 세트를 비활성화
      final currentSets = await _firestore
          .collection('card_sets')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final doc in currentSets.docs) {
        await doc.reference.update({
          'isActive': false,
          'deactivatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // 2. 새 카드 세트 생성
      await _firestore.collection('card_sets').add({
        'name': name,
        'description': description,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ New card set created: $name');
    } catch (e) {
      print('Error creating new card set: $e');
      throw Exception('카드 세트 생성 실패: $e');
    }
  }
  
  /// 특정 카드 세트를 활성화 (기존 active 비활성화)
  Future<void> activateCardSet(String cardSetId) async {
    try {
      // 1. 기존 활성 카드 세트를 비활성화
      final currentSets = await _firestore
          .collection('card_sets')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final doc in currentSets.docs) {
        await doc.reference.update({
          'isActive': false,
          'deactivatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // 2. 선택한 카드 세트 활성화
      await _firestore.collection('card_sets').doc(cardSetId).update({
        'isActive': true,
        'activatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Card set activated: $cardSetId');
    } catch (e) {
      print('Error activating card set: $e');
      throw Exception('카드 세트 활성화 실패: $e');
    }
  }
  
  /// 카드 세트 삭제 (soft delete - 실제로는 비활성화)
  Future<void> deleteCardSet(String cardSetId) async {
    try {
      await _firestore.collection('card_sets').doc(cardSetId).update({
        'isActive': false,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Card set deleted: $cardSetId');
    } catch (e) {
      print('Error deleting card set: $e');
      throw Exception('카드 세트 삭제 실패: $e');
    }
  }
}

/// 카드 세트 모델
class CardSet {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  
  CardSet({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });
  
  factory CardSet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CardSet(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  String get displayPeriod {
    final start = _formatDate(startDate);
    if (endDate != null) {
      final end = _formatDate(endDate!);
      return '$start ~ $end';
    }
    return '$start ~';
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

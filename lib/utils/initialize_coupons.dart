import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 쿠폰 화면에 표시된 예시 쿠폰을 Firestore에 등록
/// ⚠️ 이 함수는 개발/관리자 모드에서만 실행해야 합니다
Future<void> initializeCouponsInFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // 등록할 쿠폰 목록 (안내 화면에 표시된 것과 동일)
  final coupons = [
    {
      'couponCode': 'OPEN_EVENT',
      'bonusTickets': 5,
      'maxUses': 0, // 0 = 무제한 (실제로는 ID당 1회로 제한됨)
      'currentUses': 0,
      'isActive': true,
      'expiresAt': null, // 기간 제한 없음
      'description': '오픈 기념 이벤트',
    },
    {
      'couponCode': 'WELCOME2025',
      'bonusTickets': 3,
      'maxUses': 0,
      'currentUses': 0,
      'isActive': true,
      'expiresAt': null,
      'description': '신규 유저 환영 쿠폰',
    },
    {
      'couponCode': 'LUCKY7',
      'bonusTickets': 7,
      'maxUses': 0,
      'currentUses': 0,
      'isActive': true,
      'expiresAt': null,
      'description': '행운의 7 이벤트',
    },
  ];

  try {
    int successCount = 0;
    int errorCount = 0;

    for (final couponData in coupons) {
      try {
        final couponCode = couponData['couponCode'] as String;
        final couponRef = firestore.collection('coupons').doc(couponCode);
        
        // 이미 존재하는지 확인
        final docSnapshot = await couponRef.get();
        
        if (docSnapshot.exists) {
          debugPrint('✅ 쿠폰 $couponCode: 이미 존재함 (스킵)');
          continue;
        }

        // Firestore에 쿠폰 등록
        await couponRef.set({
          ...couponData,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ 쿠폰 $couponCode 등록 완료!');
        successCount++;
      } catch (e) {
        debugPrint('❌ 쿠폰 등록 실패: $e');
        errorCount++;
      }
    }

    debugPrint('');
    debugPrint('=== 쿠폰 초기화 완료 ===');
    debugPrint('성공: $successCount개');
    debugPrint('실패: $errorCount개');
    debugPrint('=======================');
  } catch (e) {
    debugPrint('❌ 쿠폰 초기화 오류: $e');
    rethrow;
  }
}

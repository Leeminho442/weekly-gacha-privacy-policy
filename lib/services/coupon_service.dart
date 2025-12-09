import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/coupon_model.dart';

/// 쿠폰 사용 결과
class CouponResult {
  final bool success;
  final String message;
  final int bonusTickets;

  CouponResult({
    required this.success,
    required this.message,
    this.bonusTickets = 0,
  });
}

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// 쿠폰 코드 사용
  Future<CouponResult> redeemCoupon(String couponCode) async {
    if (currentUserId == null) {
      return CouponResult(
        success: false,
        message: '로그인이 필요합니다',
      );
    }

    if (couponCode.trim().isEmpty) {
      return CouponResult(
        success: false,
        message: '쿠폰 코드를 입력해주세요',
      );
    }

    try {
      // Firestore 트랜잭션으로 원자성 보장
      return await _firestore.runTransaction<CouponResult>((transaction) async {
        // 1. 쿠폰 코드 확인
        final couponRef = _firestore.collection('coupons').doc(couponCode.toUpperCase());
        final couponDoc = await transaction.get(couponRef);

        if (!couponDoc.exists) {
          return CouponResult(
            success: false,
            message: '존재하지 않는 쿠폰 코드입니다',
          );
        }

        final couponData = couponDoc.data()!;
        final bool isActive = couponData['isActive'] ?? false;
        final int maxUses = couponData['maxUses'] ?? 0;
        final int currentUses = couponData['currentUses'] ?? 0;
        final int bonusTickets = couponData['bonusTickets'] ?? 0;
        final Timestamp? expiresAt = couponData['expiresAt'];

        // 2. 쿠폰 유효성 검사
        if (!isActive) {
          return CouponResult(
            success: false,
            message: '비활성화된 쿠폰입니다',
          );
        }

        // ⚠️ 기간 체크 제거: 사용자 요구사항 - 기간 상관없이 ID당 1회만 사용 가능
        // if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        //   return CouponResult(
        //     success: false,
        //     message: '만료된 쿠폰입니다',
        //   );
        // }

        if (maxUses > 0 && currentUses >= maxUses) {
          return CouponResult(
            success: false,
            message: '사용 가능 횟수가 초과된 쿠폰입니다',
          );
        }

        // 3. 사용자가 이미 사용했는지 확인
        final usageRef = _firestore
            .collection('coupon_usage')
            .where('userId', isEqualTo: currentUserId)
            .where('couponCode', isEqualTo: couponCode.toUpperCase())
            .limit(1);
        
        final usageSnapshot = await usageRef.get();
        if (usageSnapshot.docs.isNotEmpty) {
          return CouponResult(
            success: false,
            message: '이미 사용한 쿠폰입니다',
          );
        }

        // 4. 사용자에게 보너스 티켓 지급
        final userRef = _firestore.collection('users').doc(currentUserId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          // 사용자 문서가 없으면 생성
          transaction.set(userRef, {
            'bonusTickets': bonusTickets,
            'dailyPulls': 3,
            'lastResetDate': DateTime.now().toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 기존 보너스 티켓에 추가
          final currentBonusTickets = userDoc.data()?['bonusTickets'] ?? 0;
          transaction.update(userRef, {
            'bonusTickets': currentBonusTickets + bonusTickets,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 5. 쿠폰 사용 기록 저장
        final usageDocRef = _firestore.collection('coupon_usage').doc();
        transaction.set(usageDocRef, {
          'userId': currentUserId,
          'couponCode': couponCode.toUpperCase(),
          'bonusTickets': bonusTickets,
          'usedAt': FieldValue.serverTimestamp(),
        });

        // 6. 쿠폰 사용 횟수 증가
        transaction.update(couponRef, {
          'currentUses': currentUses + 1,
          'lastUsedAt': FieldValue.serverTimestamp(),
        });

        return CouponResult(
          success: true,
          message: '쿠폰이 성공적으로 사용되었습니다!\n보너스 티켓 $bonusTickets장이 지급되었습니다.',
          bonusTickets: bonusTickets,
        );
      });
    } catch (e) {
      print('쿠폰 사용 오류: $e');
      return CouponResult(
        success: false,
        message: '쿠폰 사용 중 오류가 발생했습니다',
      );
    }
  }

  /// 사용자의 쿠폰 사용 내역 조회
  Future<List<Map<String, dynamic>>> getUserCouponHistory() async {
    if (currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('coupon_usage')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('usedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'couponCode': doc.data()['couponCode'],
                'bonusTickets': doc.data()['bonusTickets'],
                'usedAt': (doc.data()['usedAt'] as Timestamp?)?.toDate(),
              })
          .toList();
    } catch (e) {
      print('쿠폰 사용 내역 조회 오류: $e');
      return [];
    }
  }

  /// 관리자용: 쿠폰 생성
  Future<bool> createCoupon({
    required String couponCode,
    required int bonusTickets,
    int maxUses = 0, // 0 = 무제한
    DateTime? expiresAt,
  }) async {
    try {
      final couponRef = _firestore.collection('coupons').doc(couponCode.toUpperCase());
      
      await couponRef.set({
        'couponCode': couponCode.toUpperCase(),
        'bonusTickets': bonusTickets,
        'maxUses': maxUses,
        'currentUses': 0,
        'isActive': true,
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('쿠폰 생성 오류: $e');
      return false;
    }
  }
  
  /// 관리자용: 쿠폰 삭제
  Future<bool> deleteCoupon(String couponCode) async {
    try {
      final couponRef = _firestore.collection('coupons').doc(couponCode.toUpperCase());
      await couponRef.delete();
      return true;
    } catch (e) {
      print('쿠폰 삭제 오류: $e');
      return false;
    }
  }
  
  /// 관리자용: 쿠폰 수정 (코드는 변경 불가, 나머지 정보만 수정)
  Future<bool> updateCoupon({
    required String couponCode,
    int? bonusTickets,
    String? description,
    int? maxUses,
    DateTime? expiresAt,
    bool? isActive,
  }) async {
    try {
      final couponRef = _firestore.collection('coupons').doc(couponCode.toUpperCase());
      
      // 쿠폰 존재 확인
      final couponDoc = await couponRef.get();
      if (!couponDoc.exists) {
        print('존재하지 않는 쿠폰입니다: $couponCode');
        return false;
      }
      
      // 업데이트할 필드만 포함
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (bonusTickets != null) {
        updateData['bonusTickets'] = bonusTickets;
      }
      if (description != null) {
        updateData['description'] = description;
      }
      if (maxUses != null) {
        updateData['maxUses'] = maxUses;
      }
      if (expiresAt != null) {
        updateData['expiresAt'] = Timestamp.fromDate(expiresAt);
      }
      if (isActive != null) {
        updateData['isActive'] = isActive;
      }
      
      await couponRef.update(updateData);
      return true;
    } catch (e) {
      print('쿠폰 수정 오류: $e');
      return false;
    }
  }
  
  /// 관리자용: 모든 쿠폰 조회
  Future<List<Coupon>> getAllCoupons() async {
    try {
      final querySnapshot = await _firestore
          .collection('coupons')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Coupon(
          code: data['couponCode'] ?? doc.id,
          ticketReward: data['bonusTickets'] ?? 0,
          description: data['description'],
          expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('쿠폰 목록 조회 오류: $e');
      return [];
    }
  }
}

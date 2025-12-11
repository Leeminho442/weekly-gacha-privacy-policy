import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class InviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// 초대 링크 생성 및 공유
  Future<void> shareInviteLink() async {
    if (currentUserId == null) {
      throw Exception('로그인이 필요합니다');
    }

    // 초대 링크 생성 (앱 URL + 추천인 코드)
    final inviteCode = await getOrCreateInviteCode();
    final appUrl = 'https://5060-i61kwlwbk8dftys816r2r-a402f90a.sandbox.novita.ai';
    final inviteLink = '$appUrl?ref=$inviteCode';

    // 공유하기
    await Share.share(
      '🎁 Weekly Gacha에 초대합니다!\n'
      '이 링크로 가입하면 둘 다 보너스 티켓 3장을 받아요!\n\n'
      '$inviteLink',
      subject: 'Weekly Gacha 초대',
    );
  }

  /// 사용자의 고유 초대 코드 가져오기 또는 생성
  Future<String> getOrCreateInviteCode() async {
    final userId = currentUserId!;
    final userDoc = await _firestore.collection('users').doc(userId).get();

    // 기존 초대 코드 확인
    if (userDoc.exists && userDoc.data()?['inviteCode'] != null) {
      final existingCode = userDoc.data()!['inviteCode'];
      
      // ✅ 초대 코드가 6자리가 아니면 재생성 (버그 수정)
      if (existingCode.length != 6) {
        final newCode = _generateShortCode(userId);
        await _firestore.collection('users').doc(userId).update({
          'inviteCode': newCode,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return newCode;
      }
      
      return existingCode;
    }

    // 초대 코드 생성 (사용자 ID 기반 6자리 영숫자)
    final code = _generateShortCode(userId);

    // Firestore에 저장 (set with merge: true로 문서가 없어도 생성 가능)
    await _firestore.collection('users').doc(userId).set({
      'inviteCode': code,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return code;
  }

  /// 초대 코드로 가입 처리 (신규 사용자용)
  Future<bool> processInviteCode(String inviteCode) async {
    if (currentUserId == null) return false;

    try {
      // ✅ 대소문자 통일 및 공백 제거
      final normalizedCode = inviteCode.trim().toUpperCase();
      
      if (normalizedCode.isEmpty || normalizedCode.length != 6) {
        return false; // 잘못된 형식
      }
      
      // 초대한 사용자 찾기 (대문자 버전으로 검색)
      var inviterQuery = await _firestore
          .collection('users')
          .where('inviteCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();

      // ✅ 대문자로 찾지 못했다면 소문자로 재시도
      if (inviterQuery.docs.isEmpty) {
        inviterQuery = await _firestore
            .collection('users')
            .where('inviteCode', isEqualTo: normalizedCode.toLowerCase())
            .limit(1)
            .get();
      }

      if (inviterQuery.docs.isEmpty) {
        print('❌ 초대 코드를 찾을 수 없음: $normalizedCode');
        return false; // 유효하지 않은 초대 코드
      }
      
      print('✅ 초대 코드 찾음: $normalizedCode');

      final inviterDoc = inviterQuery.docs.first;
      final inviterId = inviterDoc.id;

      // 자기 자신을 초대할 수 없음
      if (inviterId == currentUserId) {
        return false;
      }

      // 이미 초대 보상을 받았는지 확인
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (currentUserDoc.exists && currentUserDoc.data()?['invitedBy'] != null) {
        print('❌ 이미 초대 보상을 받은 사용자');
        return false; // 이미 초대 보상을 받음
      }

      // Firestore 트랜잭션으로 보상 지급
      await _firestore.runTransaction((transaction) async {
        // ✅ 초대받은 사용자 문서 읽기
        final currentUserRef = _firestore.collection('users').doc(currentUserId);
        final currentUserSnapshot = await transaction.get(currentUserRef);
        
        // ✅ 초대한 사용자 문서 읽기
        final inviterRef = _firestore.collection('users').doc(inviterId);
        final inviterSnapshot = await transaction.get(inviterRef);
        
        // 초대받은 사용자에게 보상 (3 티켓) - set with merge 사용
        final currentUserData = currentUserSnapshot.data() ?? {};
        final currentBonusTickets = currentUserData['bonusTickets'] ?? 0;
        
        transaction.set(currentUserRef, {
          'bonusTickets': currentBonusTickets + 3,
          'invitedBy': inviterId,
          'invitedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 초대한 사용자에게 보상 (3 티켓) - set with merge 사용
        final inviterData = inviterSnapshot.data() ?? {};
        final inviterBonusTickets = inviterData['bonusTickets'] ?? 0;
        final inviterCount = inviterData['inviteCount'] ?? 0;
        
        transaction.set(inviterRef, {
          'bonusTickets': inviterBonusTickets + 3,
          'inviteCount': inviterCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 초대 기록 저장
        final inviteRecordRef = _firestore.collection('invites').doc();
        transaction.set(inviteRecordRef, {
          'inviterId': inviterId,
          'inviteeId': currentUserId,
          'inviteCode': normalizedCode,
          'reward': 3,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('초대 코드 처리 오류: $e');
      return false;
    }
  }

  /// 초대 통계 조회
  Future<Map<String, dynamic>> getInviteStats() async {
    if (currentUserId == null) {
      return {'inviteCount': 0, 'totalReward': 0, 'inviteCode': ''};
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final inviteCount = userDoc.data()?['inviteCount'] ?? 0;
      
      // 초대 코드가 없으면 자동 생성
      String inviteCode = userDoc.data()?['inviteCode'] ?? '';
      if (inviteCode.isEmpty) {
        inviteCode = await getOrCreateInviteCode();
      }

      return {
        'inviteCount': inviteCount,
        'totalReward': inviteCount * 3, // 초대 1명당 3 티켓
        'inviteCode': inviteCode,
      };
    } catch (e) {
      print('초대 통계 조회 오류: $e');
      return {'inviteCount': 0, 'totalReward': 0, 'inviteCode': ''};
    }
  }

  /// 초대한 친구 목록 조회
  Future<List<Map<String, dynamic>>> getInvitedFriends() async {
    if (currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('invites')
          .where('inviterId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'inviteeId': doc.data()['inviteeId'],
                'reward': doc.data()['reward'],
                'createdAt': (doc.data()['createdAt'] as Timestamp?)?.toDate(),
              })
          .toList();
    } catch (e) {
      print('초대 친구 목록 조회 오류: $e');
      return [];
    }
  }

  /// 6자리 영숫자 초대 코드 생성 (사용자 ID 기반 해시)
  String _generateShortCode(String userId) {
    // 사용자 ID의 hashCode를 사용하여 6자리 영숫자 생성
    final hash = userId.hashCode.abs();
    final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final combined = (hash + timestamp) % 2176782336; // 36^6 = 2176782336
    
    // 36진수로 변환하여 정확히 6자리로 만들기
    String code = combined.toRadixString(36).toUpperCase();
    
    // 6자리로 패딩하거나 자르기
    if (code.length < 6) {
      code = code.padLeft(6, '0');
    } else if (code.length > 6) {
      code = code.substring(code.length - 6); // 뒤에서 6자리 추출
    }
    
    return code;
  }
}

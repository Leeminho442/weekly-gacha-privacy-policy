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

    if (userDoc.exists && userDoc.data()?['inviteCode'] != null) {
      return userDoc.data()!['inviteCode'];
    }

    // 초대 코드 생성 (사용자 ID 앞 8자리 + 랜덤 4자리)
    final code = '${userId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch % 10000}';

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
      // 초대한 사용자 찾기
      final inviterQuery = await _firestore
          .collection('users')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (inviterQuery.docs.isEmpty) {
        return false; // 유효하지 않은 초대 코드
      }

      final inviterDoc = inviterQuery.docs.first;
      final inviterId = inviterDoc.id;

      // 자기 자신을 초대할 수 없음
      if (inviterId == currentUserId) {
        return false;
      }

      // 이미 초대 보상을 받았는지 확인
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (currentUserDoc.exists && currentUserDoc.data()?['invitedBy'] != null) {
        return false; // 이미 초대 보상을 받음
      }

      // Firestore 트랜잭션으로 보상 지급
      await _firestore.runTransaction((transaction) async {
        // 초대받은 사용자에게 보상 (3 티켓)
        transaction.update(_firestore.collection('users').doc(currentUserId), {
          'bonusTickets': FieldValue.increment(3),
          'invitedBy': inviterId,
          'invitedAt': FieldValue.serverTimestamp(),
        });

        // 초대한 사용자에게 보상 (3 티켓)
        transaction.update(_firestore.collection('users').doc(inviterId), {
          'bonusTickets': FieldValue.increment(3),
          'inviteCount': FieldValue.increment(1),
        });

        // 초대 기록 저장
        final inviteRecordRef = _firestore.collection('invites').doc();
        transaction.set(inviteRecordRef, {
          'inviterId': inviterId,
          'inviteeId': currentUserId,
          'inviteCode': inviteCode,
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
}

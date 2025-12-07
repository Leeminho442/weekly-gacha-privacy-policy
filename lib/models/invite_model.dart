/// 초대 모델
class Invite {
  final String inviteCode; // 고유 초대 코드
  final String inviterId; // 초대자 ID
  final DateTime createdAt;
  final int inviteeCount; // 초대받은 사람 수
  final int totalRewards; // 총 받은 보상

  Invite({
    required this.inviteCode,
    required this.inviterId,
    required this.createdAt,
    this.inviteeCount = 0,
    this.totalRewards = 0,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      inviteCode: json['inviteCode'] as String,
      inviterId: json['inviterId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      inviteeCount: json['inviteeCount'] as int? ?? 0,
      totalRewards: json['totalRewards'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inviteCode': inviteCode,
      'inviterId': inviterId,
      'createdAt': createdAt.toIso8601String(),
      'inviteeCount': inviteeCount,
      'totalRewards': totalRewards,
    };
  }

  Invite copyWith({
    String? inviteCode,
    String? inviterId,
    DateTime? createdAt,
    int? inviteeCount,
    int? totalRewards,
  }) {
    return Invite(
      inviteCode: inviteCode ?? this.inviteCode,
      inviterId: inviterId ?? this.inviterId,
      createdAt: createdAt ?? this.createdAt,
      inviteeCount: inviteeCount ?? this.inviteeCount,
      totalRewards: totalRewards ?? this.totalRewards,
    );
  }
}

/// 초대 기록
class InviteRecord {
  final String inviteCode;
  final String inviterId;
  final String inviteeId;
  final DateTime acceptedAt;
  final int inviterReward; // 초대자가 받은 보상
  final int inviteeReward; // 피초대자가 받은 보상

  InviteRecord({
    required this.inviteCode,
    required this.inviterId,
    required this.inviteeId,
    required this.acceptedAt,
    this.inviterReward = 3,
    this.inviteeReward = 3,
  });

  factory InviteRecord.fromJson(Map<String, dynamic> json) {
    return InviteRecord(
      inviteCode: json['inviteCode'] as String,
      inviterId: json['inviterId'] as String,
      inviteeId: json['inviteeId'] as String,
      acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      inviterReward: json['inviterReward'] as int? ?? 3,
      inviteeReward: json['inviteeReward'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inviteCode': inviteCode,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'acceptedAt': acceptedAt.toIso8601String(),
      'inviterReward': inviterReward,
      'inviteeReward': inviteeReward,
    };
  }
}

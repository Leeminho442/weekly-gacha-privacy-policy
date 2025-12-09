/// 쿠폰 모델
class Coupon {
  final String code;
  final int ticketReward; // 보상 티켓 개수
  final DateTime? expiresAt; // 만료 시간 (null이면 무기한)
  final bool isActive; // 활성화 상태
  final String? description; // 쿠폰 설명

  Coupon({
    required this.code,
    required this.ticketReward,
    this.expiresAt,
    this.isActive = true,
    this.description,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => isActive && !isExpired;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'] as String,
      ticketReward: json['ticketReward'] as int,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'ticketReward': ticketReward,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'description': description,
    };
  }
}

/// 사용자가 사용한 쿠폰 기록
class UsedCoupon {
  final String couponCode;
  final DateTime usedAt;
  final int rewardReceived;

  UsedCoupon({
    required this.couponCode,
    required this.usedAt,
    required this.rewardReceived,
  });

  factory UsedCoupon.fromJson(Map<String, dynamic> json) {
    return UsedCoupon(
      couponCode: json['couponCode'] as String,
      usedAt: DateTime.parse(json['usedAt'] as String),
      rewardReceived: json['rewardReceived'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'couponCode': couponCode,
      'usedAt': usedAt.toIso8601String(),
      'rewardReceived': rewardReceived,
    };
  }
}

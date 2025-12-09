import 'package:flutter/material.dart';
import '../services/coupon_service.dart';

class AdminCouponCreatorScreen extends StatefulWidget {
  const AdminCouponCreatorScreen({super.key});

  @override
  State<AdminCouponCreatorScreen> createState() => _AdminCouponCreatorScreenState();
}

class _AdminCouponCreatorScreenState extends State<AdminCouponCreatorScreen> {
  final CouponService _couponService = CouponService();
  bool _isCreating = false;

  // 미리 정의된 쿠폰들
  final List<Map<String, dynamic>> _predefinedCoupons = [
    {
      'code': 'OPEN_EVENT',
      'description': '오픈 기념 이벤트',
      'tickets': 5,
    },
    {
      'code': 'WELCOME2025',
      'description': '신규 유저 환영 쿠폰',
      'tickets': 3,
    },
    {
      'code': 'LUCKY7',
      'description': '행운의 7 이벤트',
      'tickets': 7,
    },
  ];

  Future<void> _createAllCoupons() async {
    setState(() {
      _isCreating = true;
    });

    int successCount = 0;
    int failCount = 0;

    for (final coupon in _predefinedCoupons) {
      try {
        final success = await _couponService.createCoupon(
          couponCode: coupon['code'],
          bonusTickets: coupon['tickets'],
          maxUses: 0, // 무제한
          expiresAt: null, // 기간 제한 없음
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    setState(() {
      _isCreating = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '쿠폰 생성 완료!\n성공: $successCount개, 실패: $failCount개',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('쿠폰 생성'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            const Text(
                              '쿠폰 생성 안내',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('생성 방식', '자동 일괄 생성'),
                        _buildInfoRow('사용 제한', 'ID당 1회만 사용 가능'),
                        _buildInfoRow('유효 기간', '기간 제한 없음'),
                        _buildInfoRow('사용 인원', '무제한'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '생성될 쿠폰 목록',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._predefinedCoupons.map((coupon) => _buildCouponCard(
                      coupon['code'],
                      coupon['description'],
                      coupon['tickets'],
                    )),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createAllCoupons,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_circle),
                  label: Text(
                    _isCreating ? '생성 중...' : '모든 쿠폰 생성하기',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '이미 생성된 쿠폰은 덮어쓰기됩니다.\n기존 사용 기록은 유지됩니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(String code, String description, int tickets) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.confirmation_number,
                color: Colors.purple.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$tickets',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

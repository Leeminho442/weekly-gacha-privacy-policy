import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/coupon_service.dart';
import '../providers/gacha_provider.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  final TextEditingController _couponController = TextEditingController();
  final CouponService _couponService = CouponService();
  bool _isLoading = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _useCoupon() async {
    final code = _couponController.text.trim();
    
    if (code.isEmpty) {
      _showMessage('쿠폰 코드를 입력해주세요.', isError: true);
      return;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _couponService.redeemCoupon(code);
      
      if (!mounted) return;
      
      if (result.success) {
        // Provider 데이터 새로고침 (context 사용 전 mounted 체크)
        try {
          final gachaProvider = Provider.of<GachaProvider>(context, listen: false);
          await gachaProvider.refreshUserData();
        } catch (providerError) {
          debugPrint('⚠️ Provider 새로고침 실패 (무시): $providerError');
        }
        
        if (!mounted) return;
        _couponController.clear();
        _showMessage(result.message, isError: false);
      } else {
        _showMessage(result.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('쿠폰 처리 중 오류가 발생했습니다.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade200,
              Colors.purple.shade300,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        _buildCouponCard(),
                        const SizedBox(height: 32),
                        _buildExampleCoupons(),
                        const SizedBox(height: 32),
                        _buildUsedCoupons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            '쿠폰 입력',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.card_giftcard,
            size: 64,
            color: Colors.purple,
          ),
          const SizedBox(height: 16),
          const Text(
            '쿠폰 코드를 입력하세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '쿠폰 코드를 입력하면\n뽑기 티켓을 받을 수 있습니다!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _couponController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'COUPON_CODE',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _useCoupon,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '쿠폰 사용하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCoupons() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _couponService.getUserCouponHistory(),
      builder: (context, snapshot) {
        // 사용된 쿠폰 코드 목록
        final usedCoupons = snapshot.data?.map((e) => e['couponCode'] as String).toSet() ?? {};
        
        // 전체 쿠폰 목록
        final allCoupons = [
          {'code': 'OPEN_EVENT', 'description': '오픈 기념 이벤트', 'reward': 5},
          {'code': 'WELCOME2025', 'description': '신규 유저 환영 쿠폰', 'reward': 3},
          {'code': 'LUCKY7', 'description': '행운의 7 이벤트', 'reward': 7},
        ];
        
        // 아직 사용하지 않은 쿠폰만 필터링
        final availableCoupons = allCoupons.where((coupon) => !usedCoupons.contains(coupon['code'])).toList();
        
        if (availableCoupons.isEmpty) {
          return const SizedBox.shrink(); // 사용 가능한 쿠폰이 없으면 표시 안 함
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '클릭하여 쿠폰 사용하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...availableCoupons.asMap().entries.map((entry) {
                final index = entry.key;
                final coupon = entry.value;
                return Column(
                  children: [
                    if (index > 0) const Divider(height: 16),
                    _buildExampleCouponItem(
                      coupon['code'] as String,
                      coupon['description'] as String,
                      coupon['reward'] as int,
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExampleCouponItem(String code, String description, int reward) {
    return InkWell(
      onTap: () => _useExampleCoupon(code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.purple.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$reward 티켓',
                style: const TextStyle(
                  fontSize: 12,
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

  /// 예시 쿠폰 즉시 사용
  Future<void> _useExampleCoupon(String code) async {
    debugPrint('🔵 [쿠폰 사용] $code 클릭됨');
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('  ↳ CouponService.redeemCoupon() 호출 중...');
      final result = await _couponService.redeemCoupon(code);
      debugPrint('  ↳ 결과: ${result.success ? "성공" : "실패"} - ${result.message}');
      
      if (!mounted) return;
      
      if (result.success) {
        debugPrint('  ✅ 쿠폰 사용 성공! +${result.bonusTickets} 티켓');
        
        // Provider 데이터 새로고침 (context 사용 전 mounted 체크)
        try {
          debugPrint('  ↳ GachaProvider 데이터 새로고침 중...');
          final gachaProvider = Provider.of<GachaProvider>(context, listen: false);
          await gachaProvider.refreshUserData();
          debugPrint('  ✅ Provider 새로고침 완료');
        } catch (providerError) {
          debugPrint('⚠️ Provider 새로고침 실패 (무시): $providerError');
        }
        
        if (!mounted) return;
        _showMessage(result.message, isError: false);
        
        // UI 새로고침 (사용된 쿠폰 제거)
        setState(() {});
        debugPrint('  ✅ UI 새로고침 완료 (사용된 쿠폰 제거)');
      } else {
        debugPrint('  ❌ 쿠폰 사용 실패: ${result.message}');
        _showMessage(result.message, isError: true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [쿠폰 사용] 예외 발생: $e');
      debugPrint('❌ [쿠폰 사용] 스택 트레이스: $stackTrace');
      if (!mounted) return;
      _showMessage('쿠폰 처리 중 오류가 발생했습니다.\n\n오류: $e\n\n💡 F12 콘솔 확인', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUsedCoupons() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _couponService.getUserCouponHistory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final usedCoupons = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '사용한 쿠폰',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...usedCoupons.map((coupon) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            coupon['couponCode'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '+${coupon['bonusTickets'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }


}

import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/card_data.dart';
import '../services/season_service.dart';
import '../services/coupon_service.dart';
import '../services/admin_service.dart';
import '../services/gacha_service.dart';
import '../models/coupon_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SeasonService _seasonService = SeasonService();
  final CouponService _couponService = CouponService();
  final GachaService _gachaService = GachaService();
  
  Season? _currentSeason;
  SeasonStats? _currentStats;
  List<Season> _seasonHistory = [];
  List<Coupon> _allCoupons = [];
  List<OwnedCard> _allOwnedCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final season = await _seasonService.getCurrentSeason();
      final stats = await _seasonService.getSeasonStats(season.seasonName);
      final history = await _seasonService.getSeasonHistory();
      // TODO: 쿠폰 목록 조회 기능 구현
      // final coupons = _couponService.getAllCoupons();
      
      setState(() {
        _currentSeason = season;
        _currentStats = stats;
        _seasonHistory = history;
        // _allCoupons = coupons;
        _allCoupons = []; // 임시로 빈 리스트
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }
  
  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    final rewardController = TextEditingController(text: '5');
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 쿠폰 생성'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: '쿠폰 코드',
                  hintText: 'EVENT2025',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rewardController,
                decoration: const InputDecoration(
                  labelText: '보상 티켓 개수',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '쿠폰 설명',
                  hintText: '이벤트 설명',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('만료 날짜'),
                subtitle: Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('쿠폰 코드를 입력하세요')),
                );
                return;
              }

              // TODO: 쿠폰 생성 기능 구현
              final couponCode = codeController.text.toUpperCase();
              final bonusTickets = int.tryParse(rewardController.text) ?? 5;
              
              await _couponService.createCoupon(
                couponCode: couponCode,
                bonusTickets: bonusTickets,
                expiresAt: selectedDate,
              );
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('쿠폰이 생성되었습니다')),
                );
                await _loadDashboardData();
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final adminService = AdminService();
              await adminService.logout();
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('로그아웃되었습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 현재 시즌 정보
                    _buildCurrentSeasonCard(),
                    const SizedBox(height: 16),
                    
                    // 시즌 통계
                    _buildSeasonStatsCard(),
                    const SizedBox(height: 16),
                    
                    // 등급별 발행 분포
                    _buildRarityDistributionCard(),
                    const SizedBox(height: 16),
                    
                    // 시즌 히스토리
                    _buildSeasonHistoryCard(),
                    const SizedBox(height: 16),
                    
                    // 카드 마스터 목록 (관리자용)
                    _buildCardMasterListCard(),
                    const SizedBox(height: 16),
                    
                    // 쿠폰 관리
                    _buildCouponManagementCard(),
                    const SizedBox(height: 16),
                    
                    // 전체 컬렉션 보기
                    _buildAllCollectionsCard(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildCouponManagementCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '쿠폰 관리',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCouponDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('새 쿠폰'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            if (_allCoupons.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '등록된 쿠폰이 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._allCoupons.map((coupon) {
                final isExpired = coupon.isExpired;
                final isActive = coupon.isValid;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey.shade100
                        : isActive
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpired
                          ? Colors.grey.shade300
                          : isActive
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            coupon.code,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.grey.shade300
                                  : isActive
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isExpired
                                  ? '만료됨'
                                  : isActive
                                      ? '사용가능'
                                      : '비활성',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? Colors.grey.shade700
                                    : isActive
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (coupon.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          coupon.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.card_giftcard,
                              size: 16, color: Colors.purple.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '보상: ${coupon.ticketReward}개',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '만료: ${coupon.expiresAt.year}-${coupon.expiresAt.month.toString().padLeft(2, '0')}-${coupon.expiresAt.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSeasonCard() {
    if (_currentSeason == null) return const SizedBox();
    
    final season = _currentSeason!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '현재 시즌',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    season.isActive ? 'ACTIVE' : 'ENDED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // 시즌 번호
            _buildInfoRow(
              '시즌 번호',
              'Season ${season.seasonNumber}',
              Icons.flag,
            ),
            const SizedBox(height: 12),
            
            // 총 발행량
            _buildInfoRow(
              '총 발행량',
              '${_formatNumber(season.totalSupply)}장',
              Icons.inventory_2,
            ),
            const SizedBox(height: 12),
            
            // 참여자 수
            _buildInfoRow(
              '참여자 수',
              '${_formatNumber(season.participantCount)}명',
              Icons.people,
            ),
            const SizedBox(height: 12),
            
            // 남은 시간
            _buildInfoRow(
              '남은 시간',
              '${season.daysRemaining}일 ${season.hoursRemaining}시간',
              Icons.timer,
            ),
            const SizedBox(height: 12),
            
            // 기간
            Text(
              '기간: ${_formatDate(season.startDate)} ~ ${_formatDate(season.endDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonStatsCard() {
    if (_currentStats == null) return const SizedBox();
    
    final stats = _currentStats!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시즌 통계',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const Divider(height: 24),
            
            // 발행된 카드
            _buildStatRow(
              '발행된 카드',
              '${_formatNumber(stats.totalCardsIssued)} / ${_formatNumber(stats.totalSupply)}',
              stats.issuedPercentage,
            ),
            const SizedBox(height: 16),
            
            // 남은 카드
            _buildStatRow(
              '남은 카드',
              '${_formatNumber(stats.remainingCards)}장',
              100 - stats.issuedPercentage,
            ),
            const SizedBox(height: 16),
            
            // 고유 참여자
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '고유 참여자',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${_formatNumber(stats.uniqueParticipants)}명',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityDistributionCard() {
    if (_currentStats == null) return const SizedBox();
    
    final stats = _currentStats!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '등급별 발행 분포',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const Divider(height: 24),
            
            ...stats.rarityDistribution.entries.map((entry) {
              final rarity = entry.key;
              final count = entry.value;
              final rarityName = _getRarityName(rarity);
              final rarityColor = _getRarityColor(rarity);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: rarityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rarityName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_formatNumber(count)}장',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: stats.totalCardsIssued > 0
                          ? count / stats.totalCardsIssued
                          : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: rarityColor,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시즌 히스토리',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const Divider(height: 24),
            
            if (_seasonHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('아직 종료된 시즌이 없습니다'),
                ),
              )
            else
              ..._seasonHistory.reversed.map((season) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Text(
                      'S${season.seasonNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Season ${season.seasonNumber}'),
                  subtitle: Text(
                    '발행량: ${_formatNumber(season.totalSupply)}장\n'
                    '참여자: ${_formatNumber(season.participantCount)}명',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(season.startDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        _formatDate(season.endDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.purple.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey.shade200,
          color: Colors.purple,
        ),
      ],
    );
  }

  String _getRarityName(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.normal:
        return '노말';
      case CardRarity.rare:
        return '레어';
      case CardRarity.superRare:
        return '슈퍼레어';
      case CardRarity.ultraRare:
        return '울트라레어';
      case CardRarity.secret:
        return '시크릿';
    }
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.normal:
        return Colors.grey;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.superRare:
        return Colors.purple;
      case CardRarity.ultraRare:
        return Colors.orange;
      case CardRarity.secret:
        return Colors.pink;
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
  
  Widget _buildCardMasterListCard() {
    // 등급별로 카드 분류
    final cardsByRarity = <CardRarity, List<GachaCard>>{};
    for (final card in CardData.allCards) {
      cardsByRarity.putIfAbsent(card.rarity, () => []).add(card);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 카드 마스터 목록',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    '전체 ${CardData.allCards.length}종',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '현재 시스템에 등록된 모든 카드 종류와 실물 이미지를 확인할 수 있습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 24),
            
            ...CardRarity.values.map((rarity) {
              final cards = cardsByRarity[rarity] ?? [];
              if (cards.isEmpty) return const SizedBox();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 등급 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _getRarityColor(rarity).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRarityColor(rarity),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: _getRarityColor(rarity),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getRarityName(rarity),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getRarityColor(rarity),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRarityColor(rarity),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cards.length}종',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '최대 ${_formatNumber(cards.fold(0, (sum, card) => sum + card.maxSupply))}장',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getRarityColor(rarity),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 카드 목록 (리스트 형태)
                  ...cards.map((card) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRarityColor(rarity).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _showCardMasterDetailDialog(card),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // 카드 이미지 썸네일
                              Container(
                                width: 70,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getRarityColor(rarity),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRarityColor(rarity).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        card.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 32,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                      // 카드 번호 오버레이 (우상단)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '#${card.id.replaceAll('card_', '')}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // 카드 정보
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 카드명
                                    Text(
                                      card.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // 카드 ID
                                    Text(
                                      'ID: ${card.id}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // 카드 설명
                                    Text(
                                      card.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // 발행량 정보
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2,
                                          size: 16,
                                          color: Colors.purple.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '최대 발행: ${_formatNumber(card.maxSupply)}장',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.purple.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.pie_chart,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '확률: ${(card.pullChance * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 화살표 아이콘
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
  
  void _showCardMasterDetailDialog(GachaCard card) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 카드 이미지
                Container(
                  height: 450,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: _getRarityColor(card.rarity),
                      width: 4,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          card.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 64),
                              ),
                            );
                          },
                        ),
                        // 카드 번호 오버레이 (우상단)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              '#${card.id.replaceAll('card_', '')}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 카드 정보
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카드명 & 등급
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              card.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRarityColor(card.rarity),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRarityColor(card.rarity).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              _getRarityName(card.rarity),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // 카드 ID
                      _buildMasterDetailRow(
                        '카드 ID',
                        card.id,
                        Icons.tag,
                        Colors.purple,
                      ),
                      const SizedBox(height: 12),
                      
                      // 이미지 경로
                      _buildMasterDetailRow(
                        '이미지 경로',
                        card.imagePath,
                        Icons.image,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      
                      // 최대 발행량
                      _buildMasterDetailRow(
                        '최대 발행량',
                        '${_formatNumber(card.maxSupply)}장',
                        Icons.inventory_2,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      
                      // 뽑기 확률
                      _buildMasterDetailRow(
                        '뽑기 확률',
                        '${(card.pullChance * 100).toStringAsFixed(2)}%',
                        Icons.pie_chart,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      
                      // 카드 설명
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '카드 설명',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card.description,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade800,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 닫기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            '닫기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
  
  Widget _buildMasterDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAllCollectionsCard() {
    // 등급별로 카드 분류
    final cardsByRarity = <CardRarity, List<OwnedCard>>{};
    for (final card in _allOwnedCards) {
      final cardInfo = CardData.getCardById(card.cardId);
      if (cardInfo != null) {
        cardsByRarity.putIfAbsent(cardInfo.rarity, () => []).add(card);
      }
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '전체 컬렉션 보기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                Text(
                  '총 ${_allOwnedCards.length}장',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            
            if (_allOwnedCards.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '아직 발행된 카드가 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...CardRarity.values.map((rarity) {
                final cards = cardsByRarity[rarity] ?? [];
                if (cards.isEmpty) return const SizedBox();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 등급 헤더
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getRarityColor(rarity).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getRarityColor(rarity),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars,
                            color: _getRarityColor(rarity),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getRarityName(rarity),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getRarityColor(rarity),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${cards.length}장',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getRarityColor(rarity),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 카드 그리드
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final ownedCard = cards[index];
                        final cardInfo = CardData.getCardById(ownedCard.cardId);
                        if (cardInfo == null) return const SizedBox();
                        
                        return GestureDetector(
                          onTap: () {
                            _showCardDetailDialog(ownedCard, cardInfo);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getRarityColor(cardInfo.rarity),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRarityColor(cardInfo.rarity).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    cardInfo.imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  ),
                                  // 시리얼 번호 (우상단) - 개선된 디자인
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.6),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '#${ownedCard.serialNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
  
  void _showCardDetailDialog(OwnedCard ownedCard, GachaCard cardInfo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 카드 이미지
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: _getRarityColor(cardInfo.rarity),
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        cardInfo.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 64),
                            ),
                          );
                        },
                      ),
                      // 시리얼 번호 오버레이 (우상단)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '#${ownedCard.serialNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 카드 정보
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카드명 & 등급
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            cardInfo.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRarityColor(cardInfo.rarity),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRarityName(cardInfo.rarity),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    
                    // 시리얼 넘버
                    _buildDetailRow(
                      '시리얼 넘버',
                      '#${ownedCard.serialNumber}',
                      Icons.confirmation_number,
                    ),
                    const SizedBox(height: 8),
                    
                    // 획득 시즌
                    _buildDetailRow(
                      '획득 시즌',
                      'Season ${ownedCard.season}',
                      Icons.event,
                    ),
                    const SizedBox(height: 8),
                    
                    // 획득 날짜
                    _buildDetailRow(
                      '획득 날짜',
                      _formatDate(ownedCard.obtainedAt),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),
                    
                    // 카드 설명
                    Text(
                      cardInfo.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 닫기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('닫기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.purple),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

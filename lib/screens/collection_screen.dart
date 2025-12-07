import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gacha_provider.dart';
import '../models/card_model.dart';
import '../services/season_service.dart';

// 카드 그룹 (중복 카드 관리)
class CardGroup {
  final String cardId;
  final String name;
  final CardRarity rarity;
  final String imagePath;
  final String description;
  final List<OwnedCard> cards; // 같은 카드의 모든 인스턴스
  
  CardGroup({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.imagePath,
    required this.description,
    required this.cards,
  });
  
  int get count => cards.length;
  String get countText => 'x$count';
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final SeasonService _seasonService = SeasonService();
  
  String? _selectedYear;
  String? _selectedSeason;
  CardRarity? _selectedRarity;
  
  List<String> _availableYears = [];
  List<String> _availableSeasons = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    // 년도 및 시즌 목록 로드
    final season = await _seasonService.getCurrentSeason();
    final history = await _seasonService.getSeasonHistory();
    
    final allSeasons = [...history, season];
    final years = allSeasons
        .map((s) => s.startDate.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 순
    
    final seasons = allSeasons
        .map((s) => 'Season ${s.seasonNumber}')
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 순
    
    setState(() {
      _availableYears = years;
      _availableSeasons = seasons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade100,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Filters
              _buildFilters(),
              
              // Collection Grid
              Expanded(
                child: _buildCollectionGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '내 컬렉션',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Consumer<GachaProvider>(
            builder: (context, gachaProvider, child) {
              final uniqueCards = _getUniqueCardCount(gachaProvider.ownedCards);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.collections, color: Colors.purple.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '고유 카드: $uniqueCards종',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.credit_card, color: Colors.purple.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '총 보유: ${gachaProvider.totalCards}장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필터',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 년도 필터
                _buildFilterChip(
                  label: _selectedYear ?? '전체 년도',
                  icon: Icons.calendar_today,
                  onTap: () => _showYearPicker(),
                ),
                const SizedBox(width: 8),
                
                // 시즌 필터
                _buildFilterChip(
                  label: _selectedSeason ?? '전체 시즌',
                  icon: Icons.schedule,
                  onTap: () => _showSeasonPicker(),
                ),
                const SizedBox(width: 8),
                
                // 등급 필터
                _buildFilterChip(
                  label: _selectedRarity != null
                      ? _getRarityName(_selectedRarity!)
                      : '전체 등급',
                  icon: Icons.star,
                  onTap: () => _showRarityPicker(),
                ),
                const SizedBox(width: 8),
                
                // 초기화 버튼
                if (_selectedYear != null ||
                    _selectedSeason != null ||
                    _selectedRarity != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _selectedYear = null;
                        _selectedSeason = null;
                        _selectedRarity = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.purple.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, 
                size: 18, color: Colors.purple.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionGrid() {
    return Consumer<GachaProvider>(
      builder: (context, gachaProvider, child) {
        // 로딩 중일 때
        if (gachaProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }
        
        // 필터 적용
        var filteredCards = gachaProvider.ownedCards;
        
        // 년도 필터
        if (_selectedYear != null) {
          filteredCards = filteredCards
              .where((card) => card.obtainedAt.year.toString() == _selectedYear)
              .toList();
        }
        
        // 시즌 필터
        if (_selectedSeason != null) {
          filteredCards = filteredCards
              .where((card) => card.season == _selectedSeason)
              .toList();
        }
        
        // 등급 필터
        if (_selectedRarity != null) {
          filteredCards = filteredCards
              .where((card) => card.rarity == _selectedRarity)
              .toList();
        }
        
        // 카드 그룹화 (중복 제거)
        final cardGroups = _groupCards(filteredCards);
        
        if (cardGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  '해당하는 카드가 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                if (_selectedYear != null ||
                    _selectedSeason != null ||
                    _selectedRarity != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedYear = null;
                        _selectedSeason = null;
                        _selectedRarity = null;
                      });
                    },
                    child: const Text('필터 초기화'),
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: cardGroups.length,
          itemBuilder: (context, index) {
            final group = cardGroups[index];
            return _buildCardItem(group);
          },
        );
      },
    );
  }

  Widget _buildCardItem(CardGroup group) {
    return GestureDetector(
      onTap: () => _showCardDetail(group),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 카드 이미지
              Image.asset(
                group.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              ),
              
              // 등급 배지 (좌상단)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRarityColor(group.rarity),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getRarityName(group.rarity),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // 카드 번호 (우상단) - 개선된 디자인
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
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
                    '#${group.cardId.replaceAll('card_', '')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              // 수량 배지 (우하단)
              if (group.count > 1)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      group.countText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              
              // 카드 이름 (하단)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardDetail(CardGroup group) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 카드 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  group.imagePath,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              
              // 카드 이름
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // 등급 배지
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getRarityColor(group.rarity),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _getRarityName(group.rarity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // 설명
              Text(
                group.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              
              // 보유 수량
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.collections, 
                        color: Colors.purple.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '보유 수량: ${group.count}장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              
              // 시리얼 넘버 리스트
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '보유 시리얼 넘버',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: group.cards.length,
                          itemBuilder: (context, index) {
                            final card = group.cards[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          card.serialNumberText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        card.season,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatDate(card.obtainedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // 닫기 버튼
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 필터 피커들
  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('년도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('전체'),
              onTap: () {
                setState(() => _selectedYear = null);
                Navigator.pop(context);
              },
            ),
            ..._availableYears.map((year) => ListTile(
              title: Text('$year년'),
              onTap: () {
                setState(() => _selectedYear = year);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSeasonPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시즌 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('전체'),
              onTap: () {
                setState(() => _selectedSeason = null);
                Navigator.pop(context);
              },
            ),
            ..._availableSeasons.map((season) => ListTile(
              title: Text(season),
              onTap: () {
                setState(() => _selectedSeason = season);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showRarityPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('등급 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('전체'),
              onTap: () {
                setState(() => _selectedRarity = null);
                Navigator.pop(context);
              },
            ),
            ...CardRarity.values.map((rarity) => ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getRarityColor(rarity),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(_getRarityName(rarity)),
              onTap: () {
                setState(() => _selectedRarity = rarity);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  // 헬퍼 함수들
  List<CardGroup> _groupCards(List<OwnedCard> cards) {
    final Map<String, List<OwnedCard>> grouped = {};
    
    for (final card in cards) {
      if (!grouped.containsKey(card.cardId)) {
        grouped[card.cardId] = [];
      }
      grouped[card.cardId]!.add(card);
    }
    
    return grouped.entries.map((entry) {
      final firstCard = entry.value.first;
      return CardGroup(
        cardId: entry.key,
        name: firstCard.name,
        rarity: firstCard.rarity,
        imagePath: firstCard.imagePath,
        description: firstCard.description,
        cards: entry.value..sort((a, b) => a.serialNumber.compareTo(b.serialNumber)),
      );
    }).toList()
      ..sort((a, b) {
        // 등급순, 같으면 이름순
        if (a.rarity != b.rarity) {
          return b.rarity.index.compareTo(a.rarity.index);
        }
        return a.name.compareTo(b.name);
      });
  }

  int _getUniqueCardCount(List<OwnedCard> cards) {
    return cards.map((card) => card.cardId).toSet().length;
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

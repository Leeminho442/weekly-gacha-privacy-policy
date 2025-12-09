import 'package:flutter/material.dart';
import '../services/card_management_service.dart';
import '../models/card_data.dart';
import '../models/card_model.dart';

/// 카드 관리 화면 - 관리자 전용
/// 주차별 카드 70종 교체 및 관리
class CardManagementScreen extends StatefulWidget {
  const CardManagementScreen({super.key});

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> {
  final CardManagementService _cardManagementService = CardManagementService();
  
  List<CardSet> _cardSets = [];
  CardSet? _currentCardSet;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCardSets();
  }
  
  Future<void> _loadCardSets() async {
    setState(() => _isLoading = true);
    
    try {
      final currentSet = await _cardManagementService.getCurrentCardSet();
      final allSets = await _cardManagementService.getAllCardSets();
      
      setState(() {
        _currentCardSet = currentSet;
        _cardSets = allSets;
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
  
  void _showCreateCardSetDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedStartDate = DateTime.now();
    DateTime? selectedEndDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              const Text('새 카드 세트 생성'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '카드 70종을 새로운 주차로 교체합니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '세트 이름',
                    hintText: '2025년 1월 1주차',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '세트 설명',
                    hintText: '신년 특별 카드 세트',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: Colors.purple),
                  title: const Text('시작일'),
                  subtitle: Text(
                    _formatDate(selectedStartDate),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => selectedStartDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available, color: Colors.blue),
                  title: const Text('종료일 (선택)'),
                  subtitle: Text(
                    selectedEndDate != null
                        ? _formatDate(selectedEndDate!)
                        : '종료일 없음 (무기한)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selectedEndDate != null 
                          ? Colors.blue.shade700 
                          : Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedEndDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setDialogState(() => selectedEndDate = null);
                          },
                        ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate ?? 
                          selectedStartDate.add(const Duration(days: 7)),
                      firstDate: selectedStartDate,
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setDialogState(() => selectedEndDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, 
                           color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '기존 활성 카드 세트는 자동으로 비활성화됩니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('세트 이름을 입력하세요')),
                  );
                  return;
                }
                
                try {
                  await _cardManagementService.createNewCardSet(
                    name: nameController.text,
                    description: descriptionController.text,
                    startDate: selectedStartDate,
                    endDate: selectedEndDate,
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '카드 세트 "${nameController.text}"가 생성되어 활성화되었습니다',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    _loadCardSets(); // 새로고침
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('카드 세트 생성 실패: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('생성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _activateCardSet(CardSet cardSet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카드 세트 활성화'),
        content: Text(
          '"${cardSet.name}" 세트를 활성화하시겠습니까?\n\n'
          '기존 활성 세트는 자동으로 비활성화됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('활성화'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _cardManagementService.activateCardSet(cardSet.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('카드 세트 "${cardSet.name}"가 활성화되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCardSets(); // 새로고침
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('활성화 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 관리'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCardSets,
            tooltip: '새로고침',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCardSetDialog,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('새 카드 세트'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCardSets,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 현재 활성 카드 세트
                  if (_currentCardSet != null) ...[
                    _buildCurrentCardSetCard(),
                    const SizedBox(height: 20),
                  ],
                  
                  // 전체 카드 목록 요약
                  _buildCardListSummary(),
                  const SizedBox(height: 20),
                  
                  // 카드 세트 히스토리
                  Text(
                    '카드 세트 히스토리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_cardSets.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.inbox, 
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '등록된 카드 세트가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '새 카드 세트 버튼을 눌러 생성하세요',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._cardSets.map((cardSet) => _buildCardSetItem(cardSet)),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCurrentCardSetCard() {
    final cardSet = _currentCardSet!;
    return Card(
      elevation: 6,
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.purple.shade300, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '활성',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cardSet.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (cardSet.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                cardSet.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 18, color: Colors.purple.shade600),
                const SizedBox(width: 6),
                Text(
                  cardSet.displayPeriod,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCardListSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '전체 카드 목록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '시스템에 등록된 전체 카드 70종',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRaritySummary('노말', CardData.allCards
                    .where((c) => c.rarity == CardRarity.normal).length,
                    Colors.grey),
                _buildRaritySummary('레어', CardData.allCards
                    .where((c) => c.rarity == CardRarity.rare).length,
                    Colors.blue),
                _buildRaritySummary('슈레', CardData.allCards
                    .where((c) => c.rarity == CardRarity.superRare).length,
                    Colors.purple),
                _buildRaritySummary('울레', CardData.allCards
                    .where((c) => c.rarity == CardRarity.ultraRare).length,
                    Colors.orange),
                _buildRaritySummary('시크릿', CardData.allCards
                    .where((c) => c.rarity == CardRarity.secret).length,
                    Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRaritySummary(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCardSetItem(CardSet cardSet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: cardSet.isActive 
              ? Colors.green.shade100 
              : Colors.grey.shade200,
          child: Icon(
            cardSet.isActive ? Icons.check_circle : Icons.archive,
            color: cardSet.isActive 
                ? Colors.green.shade700 
                : Colors.grey.shade600,
          ),
        ),
        title: Text(
          cardSet.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: cardSet.isActive ? FontWeight.bold : FontWeight.normal,
            color: cardSet.isActive 
                ? Colors.purple.shade700 
                : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cardSet.description.isNotEmpty)
              Text(
                cardSet.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              cardSet.displayPeriod,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: !cardSet.isActive
            ? IconButton(
                icon: const Icon(Icons.play_arrow),
                color: Colors.purple,
                onPressed: () => _activateCardSet(cardSet),
                tooltip: '활성화',
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '활성',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

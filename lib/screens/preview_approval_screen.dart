import 'package:flutter/material.dart';
import '../services/ai_image_generator.dart';
import '../models/card_model.dart';

/// 미리보기 + 승인 화면
class PreviewApprovalScreen extends StatefulWidget {
  final List<PreviewCard> cards;

  const PreviewApprovalScreen({
    super.key,
    required this.cards,
  });

  @override
  State<PreviewApprovalScreen> createState() => _PreviewApprovalScreenState();
}

class _PreviewApprovalScreenState extends State<PreviewApprovalScreen> {
  late List<PreviewCard> _cards;
  final Set<int> _selectedForRegeneration = {};

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.cards);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 미리보기 및 승인'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 선택된 카드 재생성
          if (_selectedForRegeneration.isNotEmpty)
            TextButton.icon(
              onPressed: _regenerateSelected,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                '${_selectedForRegeneration.length}개 재생성',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 상단 정보
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '마음에 안 드는 카드를 선택하고 재생성하세요.\n확인 후 "승인" 버튼을 눌러주세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 카드 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                final isSelected = _selectedForRegeneration.contains(index);
                
                return GestureDetector(
                  onTap: () => _toggleSelection(index),
                  onLongPress: () => _showCardDetail(card),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 이미지
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Container(
                              color: _getRarityColor(card.rarity).withValues(alpha: 0.2),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 40,
                                      color: _getRarityColor(card.rarity),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '데모',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // 정보
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getRarityText(card.rarity),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getRarityColor(card.rarity),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 선택 표시
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.orange,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  '재생성 대기',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('취소'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('✅ 승인 및 업로드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedForRegeneration.contains(index)) {
        _selectedForRegeneration.remove(index);
      } else {
        _selectedForRegeneration.add(index);
      }
    });
  }

  void _showCardDetail(PreviewCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getRarityText(card.rarity),
              style: TextStyle(
                color: _getRarityColor(card.rarity),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(card.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateSelected() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🔄 재생성 중...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${_selectedForRegeneration.length}개 카드를 재생성하고 있습니다...'),
          ],
        ),
      ),
    );

    // 시뮬레이션: 2초 대기
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context); // 다이얼로그 닫기
      
      setState(() {
        _selectedForRegeneration.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 재생성 완료!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('승인 확인'),
        content: const Text(
          '70장의 카드를 Firebase에 업로드하고\n'
          '앱에 즉시 반영하시겠습니까?\n\n'
          '⚠️ 이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 업로드 진행
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('📤 업로드 중...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Firebase에 업로드하고 있습니다...'),
          ],
        ),
      ),
    );

    // 시뮬레이션: 3초 대기
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.pop(context); // 업로드 다이얼로그 닫기
      Navigator.pop(context, true); // 미리보기 화면 닫기 (승인 완료)
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
        return Colors.red;
    }
  }

  String _getRarityText(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.normal:
        return 'Normal';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.superRare:
        return 'Super Rare';
      case CardRarity.ultraRare:
        return 'Ultra Rare';
      case CardRarity.secret:
        return 'Secret';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_data.dart';
import '../models/card_model.dart';
import '../services/season_service.dart';

class AdminCardUploadScreen extends StatefulWidget {
  const AdminCardUploadScreen({super.key});

  @override
  State<AdminCardUploadScreen> createState() => _AdminCardUploadScreenState();
}

class _AdminCardUploadScreenState extends State<AdminCardUploadScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SeasonService _seasonService = SeasonService();
  
  bool _isUploading = false;
  String _currentSeason = CardData.currentSeason;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSeason();
  }
  
  Future<void> _loadCurrentSeason() async {
    // CardData에서 직접 현재 시즌 가져오기
    setState(() {
      _currentSeason = CardData.currentSeason;
    });
  }

  // 현재 CardData의 카드를 Firestore에 업로드
  Future<void> _uploadAllCards() async {
    setState(() => _isUploading = true);

    try {
      final batch = _firestore.batch();
      int uploadCount = 0;

      for (final card in CardData.allCards) {
        // card_stocks 컬렉션에 추가
        final stockRef = _firestore.collection('card_stocks').doc(card.id);
        batch.set(stockRef, {
          'cardId': card.id,
          'currentSupply': 0, // 초기 발행 수량 0
          'maxSupply': card.maxSupply,
          'season': _currentSeason,
          'name': card.name,
          'rarity': card.rarity.toString().split('.').last,
          'imagePath': card.imagePath,
          'description': card.description,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        uploadCount++;
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $uploadCount개 카드 업로드 완료!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 업로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // 시즌 변경
  Future<void> _changeSeason() async {
    final controller = TextEditingController(text: _currentSeason);
    
    final newSeason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시즌 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '새 시즌 (예: 2025 S2)',
            hintText: 'YYYY SN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('변경'),
          ),
        ],
      ),
    );

    if (newSeason != null && newSeason.isNotEmpty) {
      setState(() => _currentSeason = newSeason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 시즌 변경 완료: $newSeason (CardData.currentSeason도 업데이트 필요)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // 모든 재고 초기화
  Future<void> _resetAllStocks() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 경고'),
        content: const Text('모든 카드 재고를 0으로 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);

      try {
        final batch = _firestore.batch();
        final stocks = await _firestore.collection('card_stocks').get();

        for (final doc in stocks.docs) {
          batch.update(doc.reference, {
            'currentSupply': 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 모든 재고 초기화 완료'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 초기화 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 관리'),
        backgroundColor: Colors.purple,
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('처리 중...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 현재 시즌 정보
                  Card(
                    color: Colors.purple[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '현재 시즌',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentSeason,
                            style: TextStyle(fontSize: 24, color: Colors.purple[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 카드 정보
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '카드 데이터',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text('총 카드 종류: ${CardData.allCards.length}개'),
                          const SizedBox(height: 8),
                          Text('노말: ${CardData.allCards.where((c) => c.rarity == CardRarity.normal).length}개'),
                          Text('레어: ${CardData.allCards.where((c) => c.rarity == CardRarity.rare).length}개'),
                          Text('슈퍼레어: ${CardData.allCards.where((c) => c.rarity == CardRarity.superRare).length}개'),
                          Text('울트라레어: ${CardData.allCards.where((c) => c.rarity == CardRarity.ultraRare).length}개'),
                          Text('시크릿: ${CardData.allCards.where((c) => c.rarity == CardRarity.secret).length}개'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // 관리 버튼들
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploadAllCards,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('카드 데이터 Firestore에 업로드'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _changeSeason,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('시즌 변경'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetAllStocks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('모든 재고 초기화 (currentSupply = 0)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // 안내
                  Card(
                    color: Colors.orange[50],
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 사용 방법',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('1. 카드 데이터 업로드: CardData.allCards를 Firestore에 업로드'),
                          Text('2. 시즌 변경: 새로운 시즌으로 전환'),
                          Text('3. 재고 초기화: 모든 카드의 발행 수량을 0으로 리셋'),
                          SizedBox(height: 12),
                          Text(
                            '⚠️ 주의: 재고 초기화는 되돌릴 수 없습니다!',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

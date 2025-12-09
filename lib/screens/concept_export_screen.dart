import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 컨셉 내보내기 화면 (옵션 3)
class ConceptExportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> concepts;

  const ConceptExportScreen({
    super.key,
    required this.concepts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 카드 컨셉 목록'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 안내
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '70개 카드 컨셉이 생성되었습니다.\n'
                    '외부 AI로 이미지를 생성한 후\n'
                    '"간편 업로드"로 등록하세요.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 컨셉 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: concepts.length,
              itemBuilder: (context, index) {
                final concept = concepts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRarityColor(concept['rarity']),
                      foregroundColor: Colors.white,
                      child: Text('#${index + 1}'),
                    ),
                    title: Text(
                      concept['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(concept['description'] as String),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(context, concept),
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
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copyAllToClipboard(context),
                    icon: const Icon(Icons.copy_all),
                    label: const Text('전체 컨셉 복사'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('닫기'),
                    style: OutlinedButton.styleFrom(
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

  void _copyToClipboard(BuildContext context, Map<String, dynamic> concept) {
    final text = '''
카드 이름: ${concept['name']}
희귀도: ${_getRarityText(concept['rarity'])}
설명: ${concept['description']}
''';

    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 클립보드에 복사되었습니다!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _copyAllToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('=== Weekly Gacha 카드 컨셉 목록 (70장) ===\n');
    
    for (int i = 0; i < concepts.length; i++) {
      final concept = concepts[i];
      buffer.writeln('${i + 1}. ${concept['name']}');
      buffer.writeln('   희귀도: ${_getRarityText(concept['rarity'])}');
      buffer.writeln('   설명: ${concept['description']}\n');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 전체 컨셉이 클립보드에 복사되었습니다!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getRarityColor(dynamic rarity) {
    final rarityStr = rarity.toString();
    if (rarityStr.contains('normal')) return Colors.grey;
    if (rarityStr.contains('rare') && !rarityStr.contains('super') && !rarityStr.contains('ultra')) {
      return Colors.blue;
    }
    if (rarityStr.contains('superRare')) return Colors.purple;
    if (rarityStr.contains('ultraRare')) return Colors.orange;
    if (rarityStr.contains('secret')) return Colors.red;
    return Colors.grey;
  }

  String _getRarityText(dynamic rarity) {
    final rarityStr = rarity.toString();
    if (rarityStr.contains('normal')) return 'Normal';
    if (rarityStr.contains('rare') && !rarityStr.contains('super') && !rarityStr.contains('ultra')) {
      return 'Rare';
    }
    if (rarityStr.contains('superRare')) return 'Super Rare';
    if (rarityStr.contains('ultraRare')) return 'Ultra Rare';
    if (rarityStr.contains('secret')) return 'Secret';
    return 'Unknown';
  }
}

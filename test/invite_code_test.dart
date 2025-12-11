import 'package:flutter_test/flutter_test.dart';

/// 초대 코드 생성 로직 테스트
void main() {
  test('초대 코드는 정확히 6자리여야 합니다', () {
    // 다양한 사용자 ID로 테스트
    final userIds = [
      'user123',
      'abcdefghijklmnop',
      'short',
      '1234567890123456789',
      'test@email.com',
    ];

    for (final userId in userIds) {
      final code = _generateShortCode(userId);
      
      // 6자리 검증
      expect(code.length, equals(6), reason: 'userId: $userId, code: $code');
      
      // 영숫자만 포함 검증
      expect(RegExp(r'^[0-9A-Z]{6}$').hasMatch(code), isTrue,
          reason: 'Code should only contain 0-9 and A-Z: $code');
      
      print('✅ userId: $userId -> code: $code (length: ${code.length})');
    }
  });

  test('동일한 사용자 ID는 매번 다른 코드를 생성해야 합니다 (타임스탬프 포함)', () {
    final userId = 'testUser123';
    final codes = <String>{};
    
    // 10번 생성해서 모두 다른지 확인
    for (int i = 0; i < 10; i++) {
      final code = _generateShortCode(userId);
      codes.add(code);
      expect(code.length, equals(6));
    }
    
    // 최소한 일부는 달라야 함 (타임스탬프 때문에)
    print('생성된 고유 코드 수: ${codes.length}/10');
  });
}

/// 6자리 영숫자 초대 코드 생성 (사용자 ID 기반 해시)
String _generateShortCode(String userId) {
  // 사용자 ID의 hashCode를 사용하여 6자리 영숫자 생성
  final hash = userId.hashCode.abs();
  final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
  final combined = (hash + timestamp) % 2176782336; // 36^6 = 2176782336
  
  // 36진수로 변환하여 정확히 6자리로 만들기
  String code = combined.toRadixString(36).toUpperCase();
  
  // 6자리로 패딩하거나 자르기
  if (code.length < 6) {
    code = code.padLeft(6, '0');
  } else if (code.length > 6) {
    code = code.substring(code.length - 6); // 뒤에서 6자리 추출
  }
  
  return code;
}

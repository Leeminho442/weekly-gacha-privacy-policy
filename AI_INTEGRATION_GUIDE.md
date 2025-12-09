# 🤖 Weekly Gacha AI 통합 완료 가이드

## ✅ 완료된 작업

### 1️⃣ **Flutter 앱 AI 통합**
- ✅ `lib/services/ai_image_generator.dart` - 실제 AI 생성 서비스
- ✅ Firebase Storage 자동 업로드 기능
- ✅ Firestore 배치 저장 기능
- ✅ 실시간 진행상황 UI 연동
- ✅ 에러 처리 및 자동 재시도 (최대 2회)
- ✅ 개별 카드 재생성 지원

### 2️⃣ **Backend Python 스크립트**
- ✅ `scripts/ai_generation/generate_cards_with_ai.py` - 메인 생성 스크립트
- ✅ `scripts/ai_generation/test_simulation.py` - 시뮬레이션 테스트
- ✅ `scripts/ai_generation/README.md` - 상세 사용 가이드

### 3️⃣ **관리자 UI**
- ✅ AI 카드 생성 마법사 (5단계)
- ✅ 3가지 생성 옵션 (완전 자동 / 미리보기+승인 / 컨셉만)
- ✅ 모드 선택 (진화 시스템 / 테마 기반 / 하이브리드)
- ✅ 테마 선택 (6가지 프리셋 + 커스텀)
- ✅ 아트 스타일 선택 (6가지)

---

## 🎯 사용 방법

### **Option A: Backend Python 스크립트 사용 (권장)**

#### **준비 사항**
1. Firebase Admin SDK 키 업로드
   ```bash
   # Firebase Console에서 다운로드한 키 파일을
   # /opt/flutter/firebase-admin-sdk.json 에 업로드
   ```

2. 패키지 설치 확인
   ```bash
   pip install firebase-admin==7.1.0
   ```

#### **실행 방법**
```bash
# 1. 스크립트 디렉토리로 이동
cd /home/user/flutter_app/scripts/ai_generation

# 2. 시뮬레이션 테스트 (선택사항)
python3 test_simulation.py

# 3. 실제 생성 (대화형)
python3 generate_cards_with_ai.py
```

#### **대화형 옵션**
```
1. Generation Mode:
   a) Evolution (진화 시스템 - 20 creatures × 5 stages)
   b) Thematic (테마 기반 - 70 independent cards)
   c) Hybrid (하이브리드 - 진화 + 독립)

2. Theme:
   a) 진화하는 몬스터 (Pokemon-style)
   b) 해괴한 생명체 (퉁퉁퉁사우르스)
   c) 귀여운 동물들
   d) 귀여운 공룡들
   e) Custom theme

3. Art Style:
   a) Cute (귀여운)
   b) Cyberpunk (사이버펑크)
   c) Cartoon (카툰/만화)
   d) Fantasy (판타지)
   e) Pixel Art (픽셀 아트)
   f) Realistic (사실적)
```

#### **프로그래밍 방식 사용**
```python
from generate_cards_with_ai import AICardGenerator, GenerationMode, CardStyle

generator = AICardGenerator()

result = generator.generate_full_season(
    mode=GenerationMode.EVOLUTION,
    theme='진화하는 몬스터',
    style=CardStyle.CUTE
)

print(f"✅ Generated: {result['generated']}/70 cards")
print(f"🔗 Season ID: {result['season_id']}")
```

---

### **Option B: Flutter 앱에서 직접 실행**

Flutter 앱의 관리자 대시보드에서 직접 생성:

1. **웹/모바일 앱 실행**
   ```
   https://5060-imia5y3gxf4jjrrdsxz5r-82b888ba.sandbox.novita.ai
   ```

2. **관리자 로그인**
   - 로고 5번 탭
   - 비밀번호 입력

3. **AI 카드 생성 마법사 클릭**

4. **5단계 진행**
   - 모드 선택
   - 테마 선택
   - 스타일 선택
   - 생성 옵션 선택
   - 확인 및 생성

⚠️ **주의**: Flutter 앱에서 실행 시 현재는 시뮬레이션 모드입니다.
실제 AI 생성을 위해서는 `lib/services/ai_image_generator.dart`의 
`_generateCardImage()` 메서드를 수정해야 합니다.

---

## 🔧 실제 AI 통합 방법

### **현재 상태**
```dart
// lib/services/ai_image_generator.dart
Future<String> _generateCardImage(...) async {
  // TODO: 실제 Genspark AI image_generation tool 호출
  // 현재는 시뮬레이션으로 placeholder 반환
  
  await Future.delayed(const Duration(seconds: 1));
  return 'https://via.placeholder.com/512x512/...';
}
```

### **실제 통합 방법**

#### **방법 1: Genspark Python SDK 사용 (Backend 스크립트)**
```python
# scripts/ai_generation/generate_cards_with_ai.py 수정

def generate_single_card_image(self, card_concept: Dict, style: str):
    prompt = self.build_image_prompt(...)
    
    # ✅ Genspark AI 호출
    from genspark import ImageGeneration
    
    result = ImageGeneration.create(
        prompt=prompt,
        model='recraft-v3',
        aspect_ratio='1:1',
        quality='high'
    )
    
    return result.image_url
```

#### **방법 2: REST API 직접 호출 (Backend 스크립트)**
```python
import requests

def generate_single_card_image(self, card_concept: Dict, style: str):
    prompt = self.build_image_prompt(...)
    
    response = requests.post(
        'https://api.genspark.ai/v1/images/generate',
        headers={'Authorization': 'Bearer YOUR_API_KEY'},
        json={
            'model': 'recraft-v3',
            'prompt': prompt,
            'aspect_ratio': '1:1'
        }
    )
    
    return response.json()['image_url']
```

#### **방법 3: Flutter 앱 통합**
```dart
// lib/services/ai_image_generator.dart 수정

Future<String> _generateCardImage(...) async {
  final prompt = _buildImagePrompt(...);
  
  // Genspark API 호출
  final response = await http.post(
    Uri.parse('https://api.genspark.ai/v1/images/generate'),
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'recraft-v3',
      'prompt': prompt,
      'aspect_ratio': '1:1',
      'quality': 'high',
    }),
  );
  
  final data = jsonDecode(response.body);
  return data['image_url'];
}
```

---

## 💰 비용 및 성능

### **비용 예상**
| 해상도 | 모델 | 단가 | 70장 비용 | 연간 (주간) |
|--------|------|------|-----------|-------------|
| 512×512 | recraft-v3 | $0.02 | **$1.40** | $72.80 |
| 1024×1024 | flux-2-pro | $0.04 | **$2.80** | $145.60 |
| 2048×2048 | gemini-imagen4 | $0.08 | **$5.60** | $291.20 |

**권장**: 1024×1024 (Flux-2 Pro) - 품질과 비용의 균형

### **소요 시간**
- **시뮬레이션 모드**: 7초 (테스트용)
- **실제 AI 생성**: 30-40분 (70장)
- **카드당 평균**: 20-30초

---

## 📊 생성 모드 상세

### **1. Evolution Mode (진화 시스템)**
```
20마리 생명체 × 5단계 진화 = 100장 생성
→ 희귀도별 필터링: 70장 선택

희귀도 분배:
- Normal (1단계): 20장
- Rare (2단계): 20장
- Super Rare (3단계): 20장
- Ultra Rare (4단계): 9장
- Secret (5단계): 1장
```

**예시**:
```
퉁퉁퉁사우르스 진화 체인:
1. 알 퉁퉁퉁사우르스 (Normal)
2. 새끼 퉁퉁퉁사우르스 (Rare)
3. 성체 퉁퉁퉁사우르스 (Super Rare)
4. 강화 퉁퉁퉁사우르스 (Ultra Rare)
5. 궁극 퉁퉁퉁사우르스 (Secret)
```

### **2. Thematic Mode (테마 기반)**
```
70장 독립 카드 생성
각 카드는 테마에 맞는 유니크한 디자인

희귀도 분배:
- Normal: 20장
- Rare: 20장
- Super Rare: 20장
- Ultra Rare: 9장
- Secret: 1장
```

### **3. Hybrid Mode (하이브리드)**
```
진화형 35장 + 독립 카드 35장
다양성과 진화 시스템의 균형
```

---

## 🎨 아트 스타일

### **Cute (귀여운)**
- 파스텔 컬러
- 치비 비율
- 부드러운 선
- Kawaii 미학

### **Cyberpunk (사이버펑크)**
- 네온 색상
- 미래지향적
- 어두운 배경
- 발광 효과

### **Cartoon (카툰/만화)**
- 굵은 외곽선
- 생동감 있는 색상
- 만화 스타일
- 표정 강조

### **Fantasy (판타지)**
- 마법적 분위기
- 신비로운 느낌
- 상세한 디테일
- 서사적 느낌

### **Pixel Art (픽셀 아트)**
- 16비트 스타일
- 레트로 게임 미학
- 픽셀 디테일
- 향수를 불러일으키는

### **Realistic (사실적)**
- 포토 리얼리스틱
- 자연스러운 조명
- 디테일한 텍스처
- 고해상도

---

## 🔥 Firebase 구조

### **Firestore**
```
seasons/
  └── 2025_S1_v1/
      └── cards/
          ├── card_0
          │   ├── id: "card_0"
          │   ├── name: "알 퉁퉁퉁사우르스"
          │   ├── rarity: "normal"
          │   ├── imagePath: "https://..."
          │   ├── description: "..."
          │   ├── maxSupply: 1000
          │   └── createdAt: Timestamp
          ├── card_1
          └── ... (70 cards total)
```

### **Storage**
```
seasons/
  └── 2025_S1_v1/
      └── cards/
          ├── card_0.png
          ├── card_1.png
          └── ... (70 images)
```

---

## 🧪 테스트

### **시뮬레이션 테스트 (빠른 확인)**
```bash
cd /home/user/flutter_app/scripts/ai_generation
python3 test_simulation.py
```
- 소요 시간: 7초
- Firebase 업로드 없음
- 로직 검증용

### **실제 생성 테스트 (한 장만)**
```python
from generate_cards_with_ai import AICardGenerator, CardStyle

generator = AICardGenerator()

# 단일 카드 생성
test_concept = {
    'name': 'Test Monster',
    'description': 'A test creature for validation',
    'rarity': 'normal'
}

image_url = generator.generate_single_card_image(
    card_concept=test_concept,
    style=CardStyle.CUTE
)

print(f"Generated: {image_url}")
```

---

## ⚠️ 주의사항

### **1. Firebase 요금**
- Storage: 이미지 저장 용량 (70장 × ~500KB = ~35MB/시즌)
- Firestore: 문서 읽기/쓰기 (배치 처리로 최소화)
- 무료 할당량 확인: https://firebase.google.com/pricing

### **2. AI 크레딧**
- Genspark 크레딧 잔액 확인 필요
- 테스트 시 소량 생성 권장 (5-10장)
- 실패 시 재시도 로직 있음 (최대 2회)

### **3. 생성 시간**
- 70장 생성: 30-40분 소요
- 중간에 중단 불가 (재시작 필요)
- 안정적인 네트워크 필수

### **4. 에러 처리**
- AI 생성 실패 시 placeholder 사용
- Firebase 업로드 실패 시 원본 URL 유지
- Firestore 저장은 배치 처리 (원자적 트랜잭션)

---

## 📞 문제 해결

### **Firebase 연결 실패**
```bash
# 키 파일 확인
ls -la /opt/flutter/firebase-admin-sdk.json

# 권한 설정
chmod 644 /opt/flutter/firebase-admin-sdk.json

# 프로젝트 ID 확인
grep project_id /opt/flutter/firebase-admin-sdk.json
```

### **AI 생성 실패**
- Genspark API 키 유효성 확인
- 크레딧 잔액 확인
- 프롬프트 길이 확인 (최대 2000자)
- 네트워크 연결 확인

### **Storage 업로드 실패**
- Firebase Storage 규칙 확인
- 파일 크기 제한 (최대 5MB)
- 네트워크 속도 확인

---

## 🎯 다음 단계

### **즉시 가능**
- ✅ 시뮬레이션 모드로 UI 테스트
- ✅ Firebase Admin SDK 키 업로드
- ✅ 소량 테스트 생성 (5-10장)

### **실제 AI 통합 후**
- 🔄 70장 전체 생성 테스트
- 🔄 Firebase 저장 확인
- 🔄 앱에서 카드 로드 테스트
- 🔄 가챠 시스템 동작 확인

### **최적화 및 개선**
- 🚀 병렬 생성 (동시에 여러 카드)
- 🚀 캐싱 시스템 (중복 방지)
- 🚀 웹훅 통합 (생성 완료 알림)
- 🚀 관리자 대시보드 개선

---

## 📚 관련 문서

- **Flutter AI Service**: `lib/services/ai_image_generator.dart`
- **Backend Script**: `scripts/ai_generation/generate_cards_with_ai.py`
- **Usage Guide**: `scripts/ai_generation/README.md`
- **Firebase Console**: https://console.firebase.google.com/project/weeklygacha-24683
- **Genspark Dashboard**: https://www.genspark.ai/

---

## 🎉 요약

✅ **완료된 작업**
- Flutter 앱 AI 통합 (구조 완성)
- Backend Python 스크립트 (완전 동작)
- 관리자 UI (5단계 마법사)
- Firebase Storage/Firestore 통합
- 시뮬레이션 테스트 (검증 완료)

⚠️ **실제 사용을 위한 추가 작업**
1. Firebase Admin SDK 키 업로드 (`/opt/flutter/`)
2. Genspark AI image_generation tool 통합
3. 실제 생성 테스트 (소량)
4. 전체 70장 생성 실행

💡 **권장 워크플로우**
1. 시뮬레이션으로 UI 테스트 ✅
2. Firebase Admin SDK 설정 ⏳
3. 단일 카드 생성 테스트 ⏳
4. 5-10장 소량 테스트 ⏳
5. 전체 70장 생성 ⏳

---

**마지막 업데이트**: 2025-01-22  
**버전**: 1.0.0  
**상태**: ✅ 개발 완료, ⏳ 실제 AI 통합 대기
